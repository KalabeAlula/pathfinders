import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../pet/domain/ethiopian_pet.dart';
import '../../../pet/presentation/widgets/pet_avatar.dart';
import '../../application/circle_providers.dart';
import '../../domain/circle_failure.dart';
import '../../domain/circle_summary.dart';
import '../create_group_screen.dart';
import 'group_type_badge.dart';

Future<void> showGroupSwitcher(
  BuildContext context, {
  required String userId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GroupSwitcherSheet(userId: userId),
  );
}

/// Lists every group the member belongs to and lets them switch the active one
/// without leaving Home.
class GroupSwitcherSheet extends ConsumerWidget {
  const GroupSwitcherSheet({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final activeId = ref.watch(activeCircleControllerProvider(userId));
    final groups = ref.watch(circlesProvider(userId));

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
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
              Text('Your groups', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                'Switch what you are sharing with, or start another one.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              groups.when(
                data: (items) => items.isEmpty
                    ? Text(
                        'You are not in a group yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, index) {
                            final circle = items[index];
                            return _GroupRow(
                              circle: circle,
                              active: circle.id == activeId,
                              onTap: () => _selectGroup(
                                context,
                                ref,
                                circle,
                                isActive: circle.id == activeId,
                              ),
                            );
                          },
                        ),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  ),
                ),
                error: (error, stack) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        error is CircleFailure
                            ? error.message
                            : 'Could not load your groups.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.error,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(circlesProvider(userId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute<void>(
                      builder: (_) => CreateGroupScreen(userId: userId),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create New Group'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectGroup(
    BuildContext context,
    WidgetRef ref,
    CircleSummary circle, {
    required bool isActive,
  }) async {
    if (!isActive) {
      await ref
          .read(activeCircleControllerProvider(userId).notifier)
          .select(circle.id);
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.circle,
    required this.active,
    required this.onTap,
  });

  final CircleSummary circle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final companion = EthiopianPet.byId(circle.petId);
    final seats = '${circle.memberCount} of ${circle.type.capacity} members';

    return Semantics(
      button: true,
      selected: active,
      label: 'Switch to ${circle.name}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: active
                  ? scheme.primaryContainer.withValues(alpha: 0.45)
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.tile),
              border: Border.all(
                color: active ? scheme.primary : scheme.outlineVariant,
                width: active ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                PetAvatar(pet: companion, size: 42),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              circle.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 7),
                          GroupTypeBadge(type: circle.type),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$seats · ${companion.commonName} ${circle.petName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  active
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
