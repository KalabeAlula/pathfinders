import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/widgets/onboarding_shell.dart';
import '../../pet/domain/ethiopian_pet.dart';
import '../../pet/presentation/widgets/pet_avatar.dart';
import '../application/circle_providers.dart';
import '../domain/circle.dart';
import '../domain/circle_failure.dart';
import '../domain/group_type.dart';
import 'widgets/group_type_badge.dart';

/// Four steps: name, type, companion, invite. The group is created when the
/// member leaves the companion step, so the invite screen shows a real code.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  static const _stepTitles = [
    'Name it',
    'Choose the shape',
    'Pick a companion',
    'Invite your people',
  ];

  final _name = TextEditingController();
  final _petName = TextEditingController(
    text: GroupType.friends.defaultPet.defaultName,
  );

  int _step = 0;
  GroupType _type = GroupType.friends;
  EthiopianPet _companion = GroupType.friends.defaultPet;
  bool _busy = false;
  String? _error;
  Circle? _created;

  @override
  void dispose() {
    _name.dispose();
    _petName.dispose();
    super.dispose();
  }

  void _advance() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      final name = _name.text.trim();
      if (name.isEmpty) {
        setState(() => _error = 'Give your group a name.');
        return;
      }
      if (name.length > 40) {
        setState(() => _error = 'Keep the name under 40 characters.');
        return;
      }
    }
    setState(() {
      _error = null;
      _step += 1;
    });
  }

  void _back() {
    if (_step == 0 || _created != null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _error = null;
      _step -= 1;
    });
  }

  void _selectType(GroupType type) {
    if (type == _type) return;
    final previousDefault = _companion.defaultName;
    final next = type.defaultPet;
    final currentName = _petName.text.trim();
    setState(() {
      _type = type;
      _companion = next;
      if (currentName.isEmpty || currentName == previousDefault) {
        _petName.text = next.defaultName;
      }
    });
  }

  void _selectCompanion(EthiopianPet companion) {
    if (companion.id == _companion.id) return;
    final previousDefault = _companion.defaultName;
    final currentName = _petName.text.trim();
    setState(() {
      _companion = companion;
      if (currentName.isEmpty || currentName == previousDefault) {
        _petName.text = companion.defaultName;
      }
    });
  }

  Future<void> _create() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final petName = _petName.text.trim();
    if (petName.isEmpty) {
      setState(() => _error = 'Give your companion a name.');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final circle =
          await ref.read(circleRepositoryProvider(widget.userId)).createCircle(
                name: _name.text.trim(),
                type: _type,
                petId: _companion.id,
                petName: petName,
              );
      ref.invalidate(circlesProvider(widget.userId));
      await ref
          .read(activeCircleControllerProvider(widget.userId).notifier)
          .select(circle.id);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _created = circle;
        _step = 3;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('${circle.name} is ready.')),
      );
    } on CircleFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Something went wrong. Try again.';
      });
    }
  }

  Future<void> _copy(String text, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(confirmation)),
    );
  }

  Future<void> _copyInviteCode() async {
    final created = _created;
    if (created == null) return;
    await _copy(
      created.inviteCode,
      'Invite code ${created.inviteCode} copied.',
    );
  }

  Future<void> _copyInviteMessage() async {
    final created = _created;
    if (created == null) return;
    await _copy(
      'Join "${created.name}" on Pathfinders with code ${created.inviteCode}.',
      'Invite message copied.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _step == 0 || _created != null ? 'Close' : 'Back',
          icon: Icon(
            _step == 0 || _created != null
                ? Icons.close_rounded
                : Icons.arrow_back_rounded,
          ),
          onPressed: _back,
        ),
        title: const Text('New group'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepRail(step: _step, labels: _stepTitles),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _bodyFor(context),
                  ),
                ),
              ),
            ),
            _actions(context),
          ],
        ),
      ),
    );
  }

  Widget _bodyFor(BuildContext context) {
    return switch (_step) {
      0 => _nameStep(context),
      1 => _typeStep(context),
      2 => _companionStep(context),
      _ => _inviteStep(context),
    };
  }

  Widget _nameStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Name your group', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Something everyone will recognise at a glance.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          key: const ValueKey('group-name'),
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 40,
          onSubmitted: (_) => _advance(),
          decoration: onboardingFieldDecoration(
            context,
            label: 'Group name',
            hint: 'Bole Crew',
            icon: Icons.groups_rounded,
          ).copyWith(counterText: ''),
        ),
      ],
    );
  }

  Widget _typeStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose the shape',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'The type sets how many people can join, and which companions fit.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final type in GroupType.values) ...[
          _TypeCard(
            type: type,
            selected: type == _type,
            onTap: () => _selectType(type),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _companionStep(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pick a companion',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Your group companion lives on the dashboard and grows as you care '
          'for it together.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final companion in _type.pets) ...[
          _CompanionChoice(
            companion: companion,
            selected: companion.id == _companion.id,
            onTap: () => _selectCompanion(companion),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.xl),
        TextField(
          key: const ValueKey('pet-name'),
          controller: _petName,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _create(),
          decoration: onboardingFieldDecoration(
            context,
            label: 'Companion name',
            hint: _companion.defaultName,
            icon: Icons.pets_rounded,
          ).copyWith(counterText: ''),
        ),
      ],
    );
  }

  Widget _inviteStep(BuildContext context) {
    final created = _created;
    if (created == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer,
            ),
            alignment: Alignment.center,
            child: PetAvatar(pet: _companion, size: 76),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '“${created.name}” is ready',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '${_type.label} · ${created.petName} · up to ${_type.capacity} people',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              Text(
                'INVITE CODE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 8,
                      letterSpacing: 1.3,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                created.inviteCode,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 6,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Share this code with the people you want in. They can join with it '
          'from their circle screen.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.tonalIcon(
          onPressed: _copyInviteCode,
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy invite code'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: _copyInviteMessage,
          icon: const Icon(Icons.ios_share_rounded, size: 18),
          label: const Text('Copy invite message'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${created.memberIds.length} of ${created.capacity} seats filled',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: GroupTypeBadge(type: created.type),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) ...[
            InlineError(message: _error!),
            const SizedBox(height: AppSpacing.md),
          ],
          AuthSubmitButton(
            label: _step == 2
                ? 'Create group'
                : _step == 3
                    ? 'Open group'
                    : 'Continue',
            busy: _busy,
            onPressed: switch (_step) {
              2 => _create,
              3 => () => Navigator.of(context).pop(),
              _ => _advance,
            },
          ),
        ],
      ),
    );
  }
}

class _StepRail extends StatelessWidget {
  const _StepRail({required this.step, required this.labels});

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Step ${step + 1} of ${labels.length} · ${labels[step]}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final GroupType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${type.label}, up to ${type.capacity} people',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primaryContainer.withValues(alpha: 0.4)
                  : scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.tile),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  switch (type) {
                    GroupType.couple => Icons.favorite_rounded,
                    GroupType.friends => Icons.groups_rounded,
                    GroupType.family => Icons.diversity_3_rounded,
                  },
                  size: 24,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              type.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${type.capacity} seats',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.blurb,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: selected ? scheme.primary : scheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanionChoice extends StatelessWidget {
  const _CompanionChoice({
    required this.companion,
    required this.selected,
    required this.onTap,
  });

  final EthiopianPet companion;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${companion.commonName}, native to ${companion.habitat}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primaryContainer.withValues(alpha: 0.45)
                  : scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.tile),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                PetAvatar(pet: companion, size: 54),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              companion.commonName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            companion.amharicName,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.landscape_rounded,
                            size: 13,
                            color: scheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Native to ${companion.habitat}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: selected ? scheme.primary : scheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
