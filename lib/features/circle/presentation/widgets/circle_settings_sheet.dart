import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/widgets/onboarding_shell.dart';
import '../../../pet/domain/ethiopian_pet.dart';
import '../../../pet/presentation/widgets/pet_avatar.dart';
import '../../application/circle_providers.dart';
import '../../domain/circle_failure.dart';
import '../../domain/circle_member.dart';
import '../../domain/circle_snapshot.dart';
import 'group_type_badge.dart';

Future<void> showCircleSettings(
  BuildContext context, {
  required String userId,
  required CircleSnapshot snapshot,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CircleSettingsSheet(userId: userId, snapshot: snapshot),
  );
}

/// Details for the active circle: members, companion, invite code, and the
/// membership actions (leave, or delete for the creator).
class CircleSettingsSheet extends ConsumerStatefulWidget {
  const CircleSettingsSheet({
    super.key,
    required this.userId,
    required this.snapshot,
  });

  final String userId;
  final CircleSnapshot snapshot;

  @override
  ConsumerState<CircleSettingsSheet> createState() =>
      _CircleSettingsSheetState();
}

class _CircleSettingsSheetState extends ConsumerState<CircleSettingsSheet> {
  final _nameController = TextEditingController();

  bool _busy = false;
  String? _error;
  bool _hadMembership = false;
  late String _name = widget.snapshot.circle.name;
  late String _inviteCode = widget.snapshot.circle.inviteCode;
  late String? _creatorId = widget.snapshot.circle.createdBy;
  late List<CircleMember> _members = [...widget.snapshot.members];

  String get _circleId => widget.snapshot.circle.id;
  String get _circleName => _name;
  bool get _isCreator => _creatorId == widget.userId;

  @override
  void initState() {
    super.initState();
    _hadMembership =
        ref
            .read(circlesProvider(widget.userId))
            .value
            ?.any((circle) => circle.id == _circleId) ??
        false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _copyInviteCode() async {
    await Clipboard.setData(ClipboardData(text: _inviteCode));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Invite code $_inviteCode copied.')));
  }

  Future<void> _rename() async {
    final scheme = Theme.of(context).colorScheme;
    _nameController.text = _name;
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void submit() {
              final value = _nameController.text.trim();
              if (value.isEmpty) {
                setDialogState(() => error = 'Give your circle a name.');
                return;
              }
              Navigator.of(dialogContext).pop(value);
            }

            return AlertDialog(
              title: const Text('Rename circle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const ValueKey('circle-name-field'),
                    controller: _nameController,
                    autofocus: true,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    decoration: const InputDecoration(labelText: 'Circle name'),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(color: scheme.error, fontSize: 12),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(onPressed: submit, child: const Text('Save')),
              ],
            );
          },
        );
      },
    );
    if (newName == null || newName == _name) return;

    await _run(
      () async {
        await ref
            .read(activeCircleControllerProvider(widget.userId).notifier)
            .renameCircle(_circleId, newName);
        if (mounted) setState(() => _name = newName);
      },
      successMessage: 'Circle renamed to $newName.',
      closeSheet: false,
    );
  }

  Future<void> _confirmRotate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rotate invite code?'),
        content: Text(
          'The current code stops working right away. Everyone already in '
          '$_name stays a member.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Rotate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(
      () async {
        final code = await ref
            .read(activeCircleControllerProvider(widget.userId).notifier)
            .rotateInviteCode(_circleId);
        if (mounted) setState(() => _inviteCode = code);
      },
      successMessage: 'New invite code ready. The old code no longer works.',
      closeSheet: false,
    );
  }

  Future<void> _confirmRemove(CircleMember member) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${member.profile.firstName}?'),
        content: const Text(
          'They will lose access to shared routes, chat, and memories. '
          'They can rejoin with the invite code.',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(
      () async {
        await ref
            .read(activeCircleControllerProvider(widget.userId).notifier)
            .removeMember(_circleId, member.profile.id);
        if (!mounted) return;
        setState(() {
          _members.removeWhere((item) => item.profile.id == member.profile.id);
        });
      },
      successMessage: '${member.profile.firstName} was removed from $_name.',
      closeSheet: false,
    );
  }

  Future<void> _pickNewOwner() async {
    final candidates = [
      for (final member in _members)
        if (member.profile.id != widget.userId) member,
    ];
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite someone before transferring ownership.'),
        ),
      );
      return;
    }

    final selectedId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? choice;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Transfer ownership'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'They will become the creator and can rename, remove '
                    'members, or delete this circle. You will stay a member.',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final member in candidates)
                    ListTile(
                      key: ValueKey('transfer-${member.profile.id}'),
                      contentPadding: EdgeInsets.zero,
                      selected: choice == member.profile.id,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(member.profile.avatarColor),
                        child: Text(
                          member.profile.firstName.characters.first
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(member.profile.displayName),
                      trailing: choice == member.profile.id
                          ? Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: Theme.of(dialogContext)
                                  .colorScheme
                                  .primary,
                            )
                          : null,
                      onTap: () =>
                          setDialogState(() => choice = member.profile.id),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const ValueKey('confirm-transfer'),
                onPressed: choice == null
                    ? null
                    : () => Navigator.of(dialogContext).pop(choice),
                child: const Text('Make creator'),
              ),
            ],
          ),
        );
      },
    );
    if (selectedId == null) return;

    final newOwner = _members.firstWhere(
      (member) => member.profile.id == selectedId,
    );
    await _run(
      () async {
        await ref
            .read(activeCircleControllerProvider(widget.userId).notifier)
            .transferOwnership(_circleId, selectedId);
        if (mounted) setState(() => _creatorId = selectedId);
      },
      successMessage:
          '${newOwner.profile.firstName} is now the creator of $_name.',
      closeSheet: false,
    );
  }

  Future<void> _confirmLeave() async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Leave $_circleName?'),
        content: const Text(
          'You will lose access to shared routes and memories.',
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
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(
      () => ref
          .read(activeCircleControllerProvider(widget.userId).notifier)
          .leaveCircle(_circleId),
      successMessage: 'You left $_circleName.',
    );
  }

  Future<void> _confirmDelete() async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete $_circleName?'),
        content: const Text(
          'This will permanently remove all shared routes, chat, and memories '
          'for all members. This action cannot be undone.',
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
    if (confirmed != true) return;

    await _run(
      () => ref
          .read(activeCircleControllerProvider(widget.userId).notifier)
          .deleteCircle(_circleId),
      successMessage: '$_circleName was deleted.',
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String successMessage,
    bool closeSheet = true,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await action();
      if (!mounted) return;
      if (closeSheet) navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } on CircleFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If this member is removed (or the circle is deleted) while the sheet is
    // open, leave the sheet so the gate can show what happened.
    ref.listen(circlesProvider(widget.userId), (_, next) {
      if (_busy) return;
      final memberships = next.value;
      if (memberships == null) return;
      if (memberships.any((circle) => circle.id == _circleId)) {
        _hadMembership = true;
        return;
      }
      if (_hadMembership) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    // Ownership can change on another device. Keep the creator tools or the
    // member view in step with the live snapshot instead of the one that was
    // on screen when the sheet opened.
    ref.listen(circleSnapshotProvider(widget.userId), (_, next) {
      if (_busy) return;
      final snapshot = next.value;
      if (snapshot == null || snapshot.circle.id != _circleId) return;
      setState(() {
        _creatorId = snapshot.circle.createdBy;
        _name = snapshot.circle.name;
        _inviteCode = snapshot.circle.inviteCode;
        _members = [...snapshot.members];
      });
    });

    final scheme = Theme.of(context).colorScheme;
    final circle = widget.snapshot.circle;
    final companion = EthiopianPet.byId(circle.petId);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Circle details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GroupTypeBadge(type: circle.type),
                  if (_isCreator) ...[
                    const SizedBox(width: 2),
                    IconButton(
                      key: const ValueKey('rename-circle'),
                      tooltip: 'Rename circle',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: _busy ? null : _rename,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_members.length} of ${circle.capacity} members',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  PetAvatar(pet: companion, size: 38),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      '${companion.commonName} ${circle.petName} · '
                      'Level ${circle.petLevel}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Members',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final member in _members)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(member.profile.avatarColor),
                        child: Text(
                          member.profile.firstName.characters.first
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          member.profile.id == widget.userId
                              ? '${member.profile.displayName} (you)'
                              : member.profile.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (member.profile.id == _creatorId)
                        Text(
                          'Creator',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      if (_isCreator && member.profile.id != widget.userId)
                        PopupMenuButton<String>(
                          key: ValueKey('member-menu-${member.profile.id}'),
                          tooltip: 'Member actions',
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          onSelected: (_) => _confirmRemove(member),
                          itemBuilder: (_) => const [
                            PopupMenuItem<String>(
                              value: 'remove',
                              child: Text('Remove from circle'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invite code',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  letterSpacing: 0.6,
                                ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _inviteCode,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(letterSpacing: 4),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Share this code so someone can join $_name.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.tonalIcon(
                      key: const ValueKey('copy-invite-code'),
                      onPressed: _copyInviteCode,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy'),
                    ),
                    if (_isCreator)
                      IconButton(
                        key: const ValueKey('rotate-invite-code'),
                        tooltip: 'Rotate invite code',
                        onPressed: _busy ? null : _confirmRotate,
                        icon: const Icon(Icons.autorenew_rounded, size: 18),
                      ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                InlineError(message: _error!),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (_isCreator) ...[
                OutlinedButton.icon(
                  key: const ValueKey('transfer-ownership'),
                  onPressed: _busy ? null : _pickNewOwner,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Transfer Ownership'),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  key: const ValueKey('delete-circle'),
                  onPressed: _busy ? null : _confirmDelete,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete Circle'),
                ),
              ] else
                OutlinedButton.icon(
                  key: const ValueKey('leave-circle'),
                  onPressed: _busy ? null : _confirmLeave,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Leave Circle'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
