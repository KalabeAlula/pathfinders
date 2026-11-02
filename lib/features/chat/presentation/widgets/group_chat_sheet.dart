import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/member_avatar.dart';
import '../../../../core/utils/time_format.dart';
import '../../../circle/domain/user_profile.dart';
import '../../../location/application/telemetry_providers.dart';
import '../../../location/domain/geo_point.dart';
import '../../../navigation/application/navigation_providers.dart';
import '../../../navigation/domain/navigation_failure.dart';
import '../../application/chat_providers.dart';
import '../../domain/chat_failure.dart';
import '../../domain/chat_message.dart';
import 'chat_map_preview.dart';

Future<void> showGroupChat(
  BuildContext context, {
  required String circleId,
  required String currentUserId,
  required void Function(GeoPoint point, String? label) onShowLocation,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GroupChatSheet(
      circleId: circleId,
      currentUserId: currentUserId,
      onShowLocation: onShowLocation,
    ),
  );
}

/// The circle's thread: text, shared locations and destination updates.
class GroupChatSheet extends ConsumerStatefulWidget {
  const GroupChatSheet({
    super.key,
    required this.circleId,
    required this.currentUserId,
    required this.onShowLocation,
  });

  final String circleId;
  final String currentUserId;

  /// Closes the sheet and points the map at the shared place.
  final void Function(GeoPoint point, String? label) onShowLocation;

  @override
  ConsumerState<GroupChatSheet> createState() => _GroupChatSheetState();
}

class _GroupChatSheetState extends ConsumerState<GroupChatSheet> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _sharing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(chatSeenControllerProvider(widget.circleId).notifier).markSeen();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await ref
          .read(chatRepositoryProvider(widget.circleId))
          .sendText(senderId: widget.currentUserId, text: text);
      if (!mounted) return;
      _text.clear();
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
          );
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
    Navigator.of(context).pop();
    widget.onShowLocation(point, message.placeLabel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final height = math.min(
      media.size.height * 0.88,
      math.max(280.0, media.size.height * 0.88 - keyboard),
    );
    final messages = ref.watch(circleMessagesProvider(widget.circleId));

    ref.listen(circleMessagesProvider(widget.circleId), (_, _) {
      ref.read(chatSeenControllerProvider(widget.circleId).notifier).markSeen();
    });

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              _ChatHeader(
                onClose: () => Navigator.of(context).pop(),
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
                            if (message.isDestinationUpdate) {
                              return _DestinationUpdateRow(
                                message: message,
                                onTap: message.hasLocation
                                    ? () => _showOnMap(message)
                                    : null,
                              );
                            }
                            return _MessageRow(
                              message: message,
                              isMine: message.senderId == widget.currentUserId,
                              onShowLocation: message.hasLocation
                                  ? () => _showOnMap(message)
                                  : null,
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
              _Composer(
                controller: _text,
                sending: _sending,
                sharing: _sharing,
                onSend: _send,
                onShareLocation: _shareLocation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onClose, required this.subtitle});

  final VoidCallback onClose;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 10, 8),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.tertiaryContainer,
                ),
                child: Icon(
                  Icons.forum_rounded,
                  size: 19,
                  color: scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Crew chat', style: theme.textTheme.titleMedium),
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
              IconButton(
                onPressed: onClose,
                tooltip: 'Close chat',
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
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
    required this.onShowLocation,
  });

  final ChatMessage message;
  final bool isMine;
  final VoidCallback? onShowLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bubbleColor = isMine ? scheme.primary : scheme.surfaceContainerHigh;
    final textColor = isMine ? scheme.onPrimary : scheme.onSurface;
    final mutedColor = isMine
        ? scheme.onPrimary.withValues(alpha: 0.72)
        : scheme.onSurfaceVariant;

    final bubble = message.kind == ChatMessageKind.locationShare
        ? _LocationBubble(
            message: message,
            bubbleColor: bubbleColor,
            textColor: textColor,
            mutedColor: mutedColor,
            onTap: onShowLocation,
          )
        : _TextBubble(
            message: message,
            bubbleColor: bubbleColor,
            textColor: textColor,
            mutedColor: mutedColor,
            isMine: isMine,
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

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.message,
    required this.bubbleColor,
    required this.textColor,
    required this.mutedColor,
    required this.isMine,
  });

  final ChatMessage message;
  final Color bubbleColor;
  final Color textColor;
  final Color mutedColor;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Text(
            message.text ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              height: 1.3,
            ),
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
    required this.onTap,
  });

  final ChatMessage message;
  final Color bubbleColor;
  final Color textColor;
  final Color mutedColor;
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
  const _DestinationUpdateRow({required this.message, required this.onTap});

  final ChatMessage message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
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

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.sharing,
    required this.onSend,
    required this.onShareLocation,
  });

  final TextEditingController controller;
  final bool sending;
  final bool sharing;
  final VoidCallback onSend;
  final VoidCallback onShareLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
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
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Message the crew',
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
            tooltip: 'Send',
            icon: sending
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}
