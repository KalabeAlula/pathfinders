import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation/glass_dock.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/member_avatar.dart';
import '../../../core/application/app_visibility.dart';
import '../../../core/utils/time_format.dart';
import '../../circle/domain/circle_member.dart';
import '../../circle/domain/user_profile.dart';
import '../../location/application/telemetry_providers.dart';
import '../../location/domain/geo_point.dart';
import '../../navigation/application/navigation_providers.dart';
import '../../navigation/domain/navigation_failure.dart';
import '../application/chat_notification_providers.dart';
import '../application/chat_providers.dart';
import '../domain/chat_failure.dart';
import '../domain/chat_mentions.dart';
import '../domain/chat_message.dart';
import 'widgets/chat_map_preview.dart';

/// The circle's thread: text, shared locations and destination updates.
///
/// Lives as a full tab now. [active] tells it whether the member is actually
/// looking at the thread; only then does a new message clear the unread badge.
class ChatTab extends ConsumerStatefulWidget {
  const ChatTab({
    super.key,
    required this.circleId,
    required this.currentUserId,
    required this.members,
    required this.onShowLocation,
    this.active = true,
  });

  final String circleId;
  final String currentUserId;

  /// Everyone in the circle; drives mention suggestions and their styling.
  final List<CircleMember> members;

  /// Hands the place to the map tab, which flies there.
  final void Function(GeoPoint point, String? label) onShowLocation;

  final bool active;

  @override
  ConsumerState<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<ChatTab> with WidgetsBindingObserver {
  late final _MentionTextEditingController _text;
  final _scroll = ScrollController();
  final _composerFocus = FocusNode();
  final _messageKeys = <String, GlobalKey>{};
  bool _sending = false;
  bool _sharing = false;
  String? _error;
  ChatMessage? _replyTo;
  ChatMessage? _editing;
  ChatMentionDraft? _mention;
  String? _highlightedId;
  Timer? _highlightTimer;

  List<UserProfile> get _memberProfiles => [
    for (final member in widget.members) member.profile,
  ];

  Set<String> get _onlineIds => {
    for (final member in widget.members)
      if (member.status?.isOnlineAt(DateTime.now()) ?? false) member.profile.id,
  };

  @override
  void initState() {
    super.initState();
    _text = _MentionTextEditingController(members: _memberProfiles)
      ..addListener(_onTextChanged);
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) _markSeenAfterFrame();
  }

  @override
  void didUpdateWidget(ChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _text.members = _memberProfiles;
    if (widget.active && !oldWidget.active) _markSeenAfterFrame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning to a thread that was already open clears the notifications
    // posted while the app was away.
    if (state == AppLifecycleState.resumed && widget.active) {
      _markSeenAfterFrame();
    }
  }

  void _markSeenAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.active) return;
      _markSeen();
    });
  }

  void _markSeen() {
    ref.read(chatSeenControllerProvider(widget.circleId).notifier).markSeen();
    unawaited(ref.read(chatNotificationsProvider).clearCircle(widget.circleId));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _highlightTimer?.cancel();
    _text.dispose();
    _scroll.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  /// Follows the caret so the suggestion popover tracks the `@` being typed.
  void _onTextChanged() {
    final value = _text.value;
    final selection = value.selection;
    final draft = selection.isValid && selection.isCollapsed
        ? findMentionDraft(
            text: value.text,
            caret: selection.baseOffset,
            members: _memberProfiles,
            excludeUserId: widget.currentUserId,
          )
        : null;
    if (draft?.start == _mention?.start && draft?.query == _mention?.query) {
      return;
    }
    setState(() => _mention = draft);
  }

  void _applyMention(UserProfile member) {
    final draft = _mention;
    if (draft == null) return;

    final completed = completeMention(_text.text, draft, member.displayName);
    HapticFeedback.selectionClick();
    _text.value = TextEditingValue(
      text: completed.text,
      selection: TextSelection.collapsed(offset: completed.caret),
    );
    _composerFocus.requestFocus();
    setState(() => _mention = null);
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;

    final editing = _editing;
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      if (editing != null) {
        if (text != editing.text) {
          await ref
              .read(chatRepositoryProvider(widget.circleId))
              .editText(
                messageId: editing.id,
                text: text,
                mentionedUserIds: findMentionedUserIds(text, _memberProfiles),
              );
        }
        if (!mounted) return;
        _leaveEditMode();
        return;
      }

      await ref
          .read(chatRepositoryProvider(widget.circleId))
          .sendText(
            senderId: widget.currentUserId,
            text: text,
            replyToId: _replyTo?.id,
            mentionedUserIds: findMentionedUserIds(text, _memberProfiles),
          );
      if (!mounted) return;
      _text.clear();
      setState(() {
        _replyTo = null;
        _mention = null;
      });
    } on ChatFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _shareLocation() async {
    if (_sharing) return;
    setState(() {
      _sharing = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      final telemetry = ref.read(
        telemetryControllerProvider(widget.currentUserId),
      );
      var reading = telemetry.lastReading;

      if (reading == null) {
        await ref
            .read(telemetryControllerProvider(widget.currentUserId).notifier)
            .requestAccess();
        if (!mounted) return;
        reading = ref
            .read(telemetryControllerProvider(widget.currentUserId))
            .lastReading;
      }

      if (reading == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Waiting for a location fix…')),
        );
        return;
      }

      String? label;
      try {
        label = await ref
            .read(navigationGatewayProvider)
            .reverseGeocode(reading.point);
      } on NavigationFailure {
        label = null;
      }
      if (!mounted) return;

      await ref
          .read(chatRepositoryProvider(widget.circleId))
          .shareLocation(
            senderId: widget.currentUserId,
            latitude: reading.point.latitude,
            longitude: reading.point.longitude,
            placeLabel: label,
            replyToId: _replyTo?.id,
          );
      if (!mounted) return;
      setState(() => _replyTo = null);
    } on ChatFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _showOnMap(ChatMessage message) {
    final point = message.point;
    if (point == null) return;
    widget.onShowLocation(point, message.placeLabel);
  }

  void _startReply(ChatMessage message) {
    HapticFeedback.selectionClick();
    final wasEditing = _editing != null;
    setState(() {
      _replyTo = message;
      _editing = null;
      _mention = null;
    });
    if (wasEditing) _text.clear();
    _composerFocus.requestFocus();
  }

  void _startEdit(ChatMessage message) {
    HapticFeedback.selectionClick();
    setState(() {
      _editing = message;
      _replyTo = null;
      _mention = null;
    });
    final body = message.text ?? '';
    _text.value = TextEditingValue(
      text: body,
      selection: TextSelection.collapsed(offset: body.length),
    );
    _composerFocus.requestFocus();
  }

  void _leaveEditMode() {
    _text.clear();
    _composerFocus.unfocus();
    setState(() => _editing = null);
  }

  Future<void> _confirmDelete(ChatMessage message) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this message?'),
        content: const Text(
          'It disappears for everyone in the circle, and any reply quoting '
          'it loses the quote.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(chatRepositoryProvider(widget.circleId))
          .deleteMessage(message.id);
      if (!mounted) return;
      if (_editing?.id == message.id) _leaveEditMode();
    } on ChatFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
    }
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    const reply = 'reply';
    const edit = 'edit';
    const delete = 'delete';
    final mine =
        message.senderId == widget.currentUserId &&
        message.kind == ChatMessageKind.text;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.reply_rounded, color: scheme.primary),
                  title: const Text('Reply'),
                  subtitle: Text(
                    'Quote ${message.senderFirstName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(context, reply),
                ),
                if (mine) ...[
                  ListTile(
                    leading: Icon(Icons.edit_rounded, color: scheme.primary),
                    title: const Text('Edit message'),
                    subtitle: Text(
                      message.text ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(context, edit),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: scheme.error,
                    ),
                    title: Text(
                      'Delete message',
                      style: TextStyle(color: scheme.error),
                    ),
                    onTap: () => Navigator.pop(context, delete),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    switch (choice) {
      case reply:
        _startReply(message);
      case edit:
        _startEdit(message);
      case delete:
        await _confirmDelete(message);
    }
  }

  /// Brings an older message back into view and flashes it.
  Future<void> _scrollToMessage(String messageId) async {
    final items = ref.read(circleMessagesProvider(widget.circleId)).value;
    if (items == null) return;

    final index = items.indexWhere((message) => message.id == messageId);
    if (index < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That message is no longer in the thread.'),
        ),
      );
      return;
    }

    _highlightTimer?.cancel();
    setState(() => _highlightedId = messageId);
    _highlightTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _highlightedId = null);
    });

    final built = _messageKeys[messageId]?.currentContext;
    if (built != null) {
      await Scrollable.ensureVisible(
        built,
        alignment: 0.35,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (!_scroll.hasClients) return;
    // The list is reversed, so older rows sit further along the scroll axis.
    // Jump roughly there first; the exact row is corrected once it builds.
    final listIndex = items.length - 1 - index;
    final estimate = (listIndex * 72.0).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    await _scroll.animateTo(
      estimate,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;

    final revealed = _messageKeys[messageId]?.currentContext;
    if (revealed != null && revealed.mounted) {
      await Scrollable.ensureVisible(
        revealed,
        alignment: 0.35,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  GlobalKey _keyFor(String messageId) =>
      _messageKeys.putIfAbsent(messageId, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final messages = ref.watch(circleMessagesProvider(widget.circleId));

    ref.listen(circleMessagesProvider(widget.circleId), (_, _) {
      // A message that lands while the app is away still belongs in the shade;
      // only a visible thread counts as having read it.
      if (!widget.active || !ref.read(appVisibilityProvider).isForeground) {
        return;
      }
      _markSeen();
    });

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ChatHeader(
              subtitle: messages.value?.isEmpty ?? true
                  ? 'Say hi or share where you are'
                  : '${messages.value!.length} message'
                        '${messages.value!.length == 1 ? '' : 's'} in the thread',
            ),
            Expanded(
              child: messages.when(
                data: (items) => items.isEmpty
                    ? const _EmptyThread()
                    : ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final message = items[items.length - 1 - index];
                          return _MessageItem(
                            key: _keyFor(message.id),
                            highlighted: message.id == _highlightedId,
                            mentioned: message.mentions(widget.currentUserId),
                            onReply: () => _startReply(message),
                            onLongPress: () => _showMessageActions(message),
                            child: message.isDestinationUpdate
                                ? _DestinationUpdateRow(
                                    message: message,
                                    onTap: message.hasLocation
                                        ? () => _showOnMap(message)
                                        : null,
                                    onShowQuote: message.replyTo == null
                                        ? null
                                        : () => _scrollToMessage(
                                            message.replyTo!.id,
                                          ),
                                  )
                                : _MessageRow(
                                    message: message,
                                    isMine:
                                        message.senderId ==
                                        widget.currentUserId,
                                    members: _memberProfiles,
                                    onShowLocation: message.hasLocation
                                        ? () => _showOnMap(message)
                                        : null,
                                    onShowQuote: message.replyTo == null
                                        ? null
                                        : () => _scrollToMessage(
                                            message.replyTo!.id,
                                          ),
                                  ),
                          );
                        },
                      ),
                loading: () => const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => _ThreadError(
                  onRetry: () =>
                      ref.invalidate(circleMessagesProvider(widget.circleId)),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(bottom: ShellDock.contentInset(context)),
              child: _Composer(
                controller: _text,
                focusNode: _composerFocus,
                sending: _sending,
                sharing: _sharing,
                replyingTo: _replyTo,
                editing: _editing,
                mentionDraft: _mention,
                onlineUserIds: _onlineIds,
                onCancelReply: () => setState(() => _replyTo = null),
                onCancelEdit: _leaveEditMode,
                onMentionSelected: _applyMention,
                onSend: _send,
                onShareLocation: _shareLocation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.tertiaryContainer,
            ),
            child: Icon(
              Icons.forum_rounded,
              size: 20,
              color: scheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crew chat', style: theme.textTheme.titleLarge),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.isMine,
    required this.members,
    required this.onShowLocation,
    this.onShowQuote,
  });

  final ChatMessage message;
  final bool isMine;
  final List<UserProfile> members;
  final VoidCallback? onShowLocation;
  final VoidCallback? onShowQuote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bubbleColor = isMine ? scheme.primary : scheme.surfaceContainerHigh;
    final textColor = isMine ? scheme.onPrimary : scheme.onSurface;
    final mutedColor = isMine
        ? scheme.onPrimary.withValues(alpha: 0.72)
        : scheme.onSurfaceVariant;

    final reply = message.replyTo;
    final quote = reply == null
        ? null
        : _QuotedMessage(
            reply: reply,
            accent: isMine ? scheme.onPrimary : scheme.primary,
            background: isMine
                ? scheme.onPrimary.withValues(alpha: 0.16)
                : scheme.surface.withValues(alpha: 0.55),
            authorColor: isMine ? scheme.onPrimary : scheme.primary,
            textColor: isMine
                ? scheme.onPrimary.withValues(alpha: 0.82)
                : scheme.onSurfaceVariant,
            onTap: onShowQuote,
          );

    final bubble = message.kind == ChatMessageKind.locationShare
        ? _LocationBubble(
            message: message,
            bubbleColor: bubbleColor,
            textColor: textColor,
            mutedColor: mutedColor,
            quote: quote,
            onTap: onShowLocation,
          )
        : _TextBubble(
            message: message,
            bubbleColor: bubbleColor,
            textColor: textColor,
            mutedColor: mutedColor,
            quote: quote,
            isMine: isMine,
            members: members,
            mentionColor: isMine ? scheme.onPrimary : scheme.primary,
            mentionBackground: (isMine ? scheme.onPrimary : scheme.primary)
                .withValues(alpha: isMine ? 0.22 : 0.14),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            _SenderAvatar(message: message),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      message.senderFirstName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                bubble,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final url = message.senderAvatarUrl;
    if (url != null && url.trim().isNotEmpty) {
      final avatarPixels = (28 * MediaQuery.devicePixelRatioOf(context))
          .round();
      return CircleAvatar(
        radius: 14,
        backgroundImage: ResizeImage(
          NetworkImage(url),
          width: avatarPixels,
          height: avatarPixels,
          policy: ResizeImagePolicy.fit,
        ),
      );
    }
    return MemberAvatar(
      profile: UserProfile(
        id: message.senderId,
        displayName: message.senderName,
        avatarColor: message.senderAvatarColor,
      ),
      size: 28,
      showStatusBadge: false,
    );
  }
}

/// One row plus the gestures that do not change what it shows: swipe to
/// reply, long-press actions, and the flash after a quote jump.
class _MessageItem extends StatelessWidget {
  const _MessageItem({
    super.key,
    required this.highlighted,
    required this.mentioned,
    required this.onReply,
    required this.onLongPress,
    required this.child,
  });

  final bool highlighted;

  /// The current member is tagged in this message.
  final bool mentioned;
  final VoidCallback onReply;
  final VoidCallback onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = highlighted
        ? scheme.primary.withValues(alpha: 0.12)
        : mentioned
        ? scheme.primary.withValues(alpha: 0.07)
        : Colors.transparent;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: onLongPress,
      child: _SwipeToReply(
        onReply: onReply,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(14),
            border: mentioned
                ? Border.all(color: scheme.primary.withValues(alpha: 0.32))
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Pulls a row to the right until a reply arrow is armed.
class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({required this.onReply, required this.child});

  final VoidCallback onReply;
  final Widget child;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  static const _maxDrag = 64.0;
  static const _trigger = 0.55;

  late final AnimationController _pull = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  bool _hapticSent = false;

  @override
  void dispose() {
    _pull.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) => _hapticSent = false;

  void _onDragUpdate(DragUpdateDetails details) {
    final next = (_pull.value + (details.primaryDelta ?? 0) / _maxDrag).clamp(
      0.0,
      1.0,
    );
    if (next == _pull.value) return;
    _pull.value = next;
    if (!_hapticSent && next >= _trigger) {
      _hapticSent = true;
      HapticFeedback.lightImpact();
    }
  }

  void _settle() {
    _hapticSent = false;
    _pull.animateTo(0, curve: Curves.easeOutCubic);
  }

  void _onDragEnd(DragEndDetails details) {
    final armed = _pull.value >= _trigger;
    _settle();
    if (armed) widget.onReply();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _settle,
      child: AnimatedBuilder(
        animation: _pull,
        builder: (context, child) {
          final eased = Curves.easeOut.transform(_pull.value);
          return Stack(
            children: [
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Opacity(
                    opacity: eased,
                    child: Transform.scale(
                      scale: 0.72 + eased * 0.28,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary.withValues(alpha: 0.14),
                        ),
                        child: Icon(
                          Icons.reply_rounded,
                          size: 17,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(eased * _maxDrag, 0),
                child: child,
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// The compact snippet a reply shows above its own words.
class _QuotedMessage extends StatelessWidget {
  const _QuotedMessage({
    required this.reply,
    required this.accent,
    required this.background,
    required this.authorColor,
    required this.textColor,
    required this.onTap,
  });

  final ChatMessageReply reply;
  final Color accent;
  final Color background;
  final Color authorColor;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          reply.senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: authorColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          reply.preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: textColor,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.message,
    required this.bubbleColor,
    required this.textColor,
    required this.mutedColor,
    required this.quote,
    required this.isMine,
    required this.members,
    required this.mentionColor,
    required this.mentionBackground,
  });

  final ChatMessage message;
  final Color bubbleColor;
  final Color textColor;
  final Color mutedColor;
  final Widget? quote;
  final bool isMine;
  final List<UserProfile> members;
  final Color mentionColor;
  final Color mentionBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = message.text ?? '';
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: textColor,
      height: 1.3,
    );
    final segments = mentionSegments(body, findMentions(body, members));
    final mentionStyle = TextStyle(
      color: mentionColor,
      fontWeight: FontWeight.w700,
      backgroundColor: mentionBackground,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMine ? 16 : 5),
          bottomRight: Radius.circular(isMine ? 5 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (quote != null) ...[quote!, const SizedBox(height: 6)],
          Text.rich(
            TextSpan(
              children: [
                for (final segment in segments)
                  if (segment.userId == null)
                    TextSpan(text: segment.text)
                  else
                    TextSpan(text: segment.text, style: mentionStyle),
              ],
            ),
            style: bodyStyle,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeAgo(message.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: mutedColor,
                  fontSize: 9.5,
                ),
              ),
              if (message.isEdited) ...[
                const SizedBox(width: 3),
                Text(
                  'edited',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: mutedColor,
                    fontSize: 9.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (isMine) ...[
                const SizedBox(width: 3),
                Tooltip(
                  message: 'Sent',
                  child: Icon(Icons.done_rounded, size: 12, color: mutedColor),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationBubble extends StatelessWidget {
  const _LocationBubble({
    required this.message,
    required this.bubbleColor,
    required this.textColor,
    required this.mutedColor,
    required this.quote,
    required this.onTap,
  });

  final ChatMessage message;
  final Color bubbleColor;
  final Color textColor;
  final Color mutedColor;
  final Widget? quote;
  final VoidCallback? onTap;

  static const _width = 232.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final latitude = message.latitude;
    final longitude = message.longitude;
    final preview = latitude == null || longitude == null
        ? null
        : chatMapPreviewUrl(
            latitude: latitude,
            longitude: longitude,
            dark: scheme.brightness == Brightness.dark,
          );

    return Material(
      color: bubbleColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: _width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (quote != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: quote,
                ),
              SizedBox(
                height: 112,
                width: _width,
                child: preview == null
                    ? Container(
                        color: scheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.map_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : Image(
                        image: ResizeImage(
                          NetworkImage(preview),
                          width:
                              (_width * MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                          height: (112 * MediaQuery.devicePixelRatioOf(context))
                              .round(),
                          policy: ResizeImagePolicy.fit,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: scheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.map_outlined,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    Icon(Icons.place_rounded, size: 15, color: textColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        message.placeLabel ?? 'Shared location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeAgo(message.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: mutedColor,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationUpdateRow extends StatelessWidget {
  const _DestinationUpdateRow({
    required this.message,
    required this.onTap,
    this.onShowQuote,
  });

  final ChatMessage message;
  final VoidCallback? onTap;
  final VoidCallback? onShowQuote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final reply = message.replyTo;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          if (reply != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: _QuotedMessage(
                  reply: reply,
                  accent: scheme.onTertiaryContainer,
                  background: scheme.surface.withValues(alpha: 0.55),
                  authorColor: scheme.onTertiaryContainer,
                  textColor: scheme.onSurfaceVariant,
                  onTap: onShowQuote,
                ),
              ),
            ),
          Material(
            color: scheme.tertiaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 16,
                      color: scheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${message.senderFirstName} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: 'updated the destination to '),
                            TextSpan(
                              text: message.placeLabel ?? 'a new place',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: scheme.onTertiaryContainer,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            timeAgo(message.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 30,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('No messages yet', style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              'Say hi, share a place, or move the destination — the crew '
              'will see it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadError extends StatelessWidget {
  const _ThreadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 26, color: scheme.error),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Could not load the chat.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _ComposerNoticeBar extends StatelessWidget {
  const _ComposerNoticeBar({
    required this.title,
    required this.preview,
    required this.cancelTooltip,
    required this.onCancel,
  });

  final String title;
  final String preview;
  final String cancelTooltip;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3.5, color: scheme.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: onCancel,
              tooltip: cancelTooltip,
              visualDensity: VisualDensity.compact,
              color: scheme.onSurfaceVariant,
              icon: const Icon(Icons.close_rounded, size: 17),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.sharing,
    required this.replyingTo,
    required this.editing,
    required this.mentionDraft,
    required this.onlineUserIds,
    required this.onCancelReply,
    required this.onCancelEdit,
    required this.onMentionSelected,
    required this.onSend,
    required this.onShareLocation,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool sharing;
  final ChatMessage? replyingTo;
  final ChatMessage? editing;
  final ChatMentionDraft? mentionDraft;
  final Set<String> onlineUserIds;
  final VoidCallback onCancelReply;
  final VoidCallback onCancelEdit;
  final ValueChanged<UserProfile> onMentionSelected;
  final VoidCallback onSend;
  final VoidCallback onShareLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final editingMessage = editing;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: editingMessage != null
                ? _ComposerNoticeBar(
                    title: 'Editing your message',
                    preview: editingMessage.quotePreview,
                    cancelTooltip: 'Cancel edit',
                    onCancel: onCancelEdit,
                  )
                : replyingTo == null
                ? const SizedBox(width: double.infinity)
                : _ComposerNoticeBar(
                    title: 'Replying to ${replyingTo!.senderFirstName}',
                    preview: replyingTo!.quotePreview,
                    cancelTooltip: 'Cancel reply',
                    onCancel: onCancelReply,
                  ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: mentionDraft == null
                ? const SizedBox(width: double.infinity)
                : _MentionPopover(
                    draft: mentionDraft!,
                    onlineUserIds: onlineUserIds,
                    onSelect: onMentionSelected,
                  ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton.filledTonal(
                onPressed: sharing ? null : onShareLocation,
                tooltip: 'Share my location',
                icon: sharing
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: editingMessage != null
                        ? 'Edit your message'
                        : replyingTo == null
                        ? 'Message the crew'
                        : 'Write a reply',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: sending ? null : onSend,
                tooltip: editingMessage != null ? 'Save changes' : 'Send',
                icon: sending
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        editingMessage != null
                            ? Icons.check_rounded
                            : Icons.send_rounded,
                        size: 19,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Members whose name matches the `@` run being typed.
class _MentionPopover extends StatelessWidget {
  const _MentionPopover({
    required this.draft,
    required this.onlineUserIds,
    required this.onSelect,
  });

  final ChatMentionDraft draft;
  final Set<String> onlineUserIds;
  final ValueChanged<UserProfile> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxHeight: 232),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
              child: Text(
                'Tag a member',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            for (final member in draft.matches)
              InkWell(
                onTap: () => onSelect(member),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                  child: Row(
                    children: [
                      MemberAvatar(
                        profile: member,
                        size: 28,
                        isOnline: onlineUserIds.contains(member.id),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          member.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        onlineUserIds.contains(member.id)
                            ? 'Online'
                            : 'Offline',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: onlineUserIds.contains(member.id)
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Keeps the raw `@Name` text while painting it as an accent token.
class _MentionTextEditingController extends TextEditingController {
  _MentionTextEditingController({required this.members});

  List<UserProfile> members;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final composing = value.composing;
    if (withComposing && composing.isValid && !composing.isCollapsed) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final mentions = findMentions(text, members);
    if (mentions.isEmpty) return TextSpan(style: style, text: text);

    final scheme = Theme.of(context).colorScheme;
    final mentionStyle = TextStyle(
      color: scheme.primary,
      fontWeight: FontWeight.w700,
      backgroundColor: scheme.primary.withValues(alpha: 0.12),
    );

    return TextSpan(
      style: style,
      children: [
        for (final segment in mentionSegments(text, mentions))
          if (segment.userId == null)
            TextSpan(text: segment.text)
          else
            TextSpan(text: segment.text, style: mentionStyle),
      ],
    );
  }
}
