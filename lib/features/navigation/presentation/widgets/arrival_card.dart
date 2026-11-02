import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../memories/presentation/widgets/memory_composer_sheet.dart';
import '../../application/arrival_controller.dart';
import '../../application/navigation_providers.dart';
import '../../domain/arrival.dart';
import '../../domain/navigation_failure.dart';

/// Shown once the local member is inside the shared destination's radius.
///
/// The card doubles as the end-of-trip prompt: once every located member is
/// here, it offers to clear the destination for the whole circle.
class ArrivalCard extends ConsumerStatefulWidget {
  const ArrivalCard({
    super.key,
    required this.circleId,
    required this.currentUserId,
    this.compact = false,
  });

  final String circleId;
  final String currentUserId;
  final bool compact;

  @override
  ConsumerState<ArrivalCard> createState() => _ArrivalCardState();
}

class _ArrivalCardState extends ConsumerState<ArrivalCard> {
  String? _dismissedTrip;

  Future<void> _saveMoment(String trip, String place) async {
    await showMemoryComposer(
      context,
      circleId: widget.circleId,
      authorId: widget.currentUserId,
      initialPlace: place,
    );
    if (!mounted) return;
    setState(() => _dismissedTrip = trip);
  }

  Future<void> _endNavigation() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(navigationRepositoryProvider(widget.circleId))
          .clearDestination();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Navigation ended.')),
      );
    } on NavigationFailure catch (failure) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Distance ticks every fix, but this card only changes at the arrival
    // boundary; selecting the flags keeps it out of the GPS rebuild path.
    final arrival = ref.watch(
      arrivalControllerProvider(widget.circleId).select(
        (state) => (
          destination: state.destination,
          arrived: state.arrived,
          everyoneArrived: state.everyoneArrived,
        ),
      ),
    );
    final destination = arrival.destination;
    if (destination == null || !arrival.arrived) {
      return const SizedBox.shrink();
    }

    final trip = destinationTripKey(destination);
    if (_dismissedTrip == trip) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = widget.compact;

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: compact ? AppSpacing.sm : AppSpacing.md,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(14, compact ? 10 : 12, 8, 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(AppRadius.tile),
            border: Border.all(color: scheme.tertiary.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.tertiaryContainer,
                    ),
                    child: Icon(
                      Icons.celebration_rounded,
                      size: 18,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You've arrived at ${destination.label}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Save this moment for the crew.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _dismissedTrip = trip),
                    tooltip: 'Not now',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => _saveMoment(trip, destination.label),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Save this memory'),
              ),
              if (arrival.everyoneArrived) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "Everyone's here.",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _endNavigation,
                      child: const Text('End navigation'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
