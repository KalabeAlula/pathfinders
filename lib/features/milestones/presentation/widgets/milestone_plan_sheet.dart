import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/utils/time_format.dart';
import '../../../chat/application/chat_providers.dart';
import '../../../location/domain/geo_point.dart';
import '../../../navigation/application/navigation_providers.dart';
import '../../../navigation/domain/navigation_failure.dart';
import '../../application/milestones_providers.dart';
import '../../domain/milestones_failure.dart';
import '../../domain/shared_milestone.dart';
import '../milestone_copy.dart';
import '../milestone_style.dart';

Future<void> showMilestonePlan(
  BuildContext context, {
  required String circleId,
  required String currentUserId,
  required SharedMilestone milestone,
  DateTime? now,
  void Function(GeoPoint point, String label)? onPlanMeetup,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => MilestonePlanSheet(
      circleId: circleId,
      currentUserId: currentUserId,
      milestone: milestone,
      now: now,
      onPlanMeetup: onPlanMeetup,
    ),
  );
}

/// The plan behind a countdown: when, where, and a one-tap hand-off to chat
/// or to the map's destination picker.
class MilestonePlanSheet extends ConsumerStatefulWidget {
  const MilestonePlanSheet({
    super.key,
    required this.circleId,
    required this.currentUserId,
    required this.milestone,
    this.now,
    this.onPlanMeetup,
  });

  final String circleId;
  final String currentUserId;
  final SharedMilestone milestone;
  final DateTime? now;

  /// Receives the geocoded meetup point and hands it to the map picker.
  final void Function(GeoPoint point, String label)? onPlanMeetup;

  @override
  ConsumerState<MilestonePlanSheet> createState() => _MilestonePlanSheetState();
}

class _MilestonePlanSheetState extends ConsumerState<MilestonePlanSheet> {
  final _placeController = TextEditingController();
  bool _sending = false;
  bool _planning = false;
  late String? _place;
  bool _editingPlace = false;
  bool _savingPlace = false;
  String? _placeError;
  late DateTime? _start;
  bool _editingWhen = false;
  bool _savingWhen = false;
  TimeOfDay? _draftTime;
  String? _whenError;

  @override
  void initState() {
    super.initState();
    _place = widget.milestone.place;
    _start = widget.milestone.startsAt;
  }

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }

  void _startPlace() {
    _placeController.text = _place ?? '';
    setState(() {
      _editingPlace = true;
      _editingWhen = false;
      _whenError = null;
      _placeError = null;
    });
  }

  void _startWhen() {
    setState(() {
      _editingWhen = true;
      _editingPlace = false;
      _placeError = null;
      _whenError = null;
      _draftTime = _start == null ? null : TimeOfDay.fromDateTime(_start!);
    });
  }

  void _cancelWhen() {
    setState(() {
      _editingWhen = false;
      _whenError = null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _draftTime ?? const TimeOfDay(hour: 19, minute: 0),
      helpText: 'What time?',
    );
    if (picked != null && mounted) setState(() => _draftTime = picked);
  }

  Future<void> _saveTime() async {
    if (_savingWhen) return;
    final time = _draftTime;
    if (time == null) {
      setState(() => _whenError = 'Pick a time first.');
      return;
    }

    final previous = _start;
    final date = widget.milestone.date;
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _savingWhen = true;
      _whenError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(milestonesRepositoryProvider(widget.circleId))
          .setStartTime(milestoneId: widget.milestone.id, startsAt: start);
      if (!mounted) return;
      setState(() {
        _start = start;
        _editingWhen = false;
        _savingWhen = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            previous == null
                ? 'Time added to the countdown.'
                : 'Time updated on the countdown.',
          ),
        ),
      );
    } on MilestonesFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _savingWhen = false;
        _whenError = failure.message;
      });
    }
  }

  Future<void> _clearTime() async {
    if (_savingWhen) return;

    setState(() {
      _savingWhen = true;
      _whenError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(milestonesRepositoryProvider(widget.circleId))
          .setStartTime(milestoneId: widget.milestone.id, startsAt: null);
      if (!mounted) return;
      setState(() {
        _start = null;
        _editingWhen = false;
        _savingWhen = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Time removed from the countdown.')),
      );
    } on MilestonesFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _savingWhen = false;
        _whenError = failure.message;
      });
    }
  }

  void _cancelPlace() {
    setState(() {
      _editingPlace = false;
      _placeError = null;
    });
  }

  Future<void> _savePlace() async {
    if (_savingPlace) return;
    final spot = _placeController.text.trim();
    if (spot.isEmpty) {
      setState(() => _placeError = 'Type where you’re meeting first.');
      return;
    }

    final previous = _place;
    setState(() {
      _savingPlace = true;
      _placeError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(milestonesRepositoryProvider(widget.circleId))
          .setPlace(milestoneId: widget.milestone.id, place: spot);
      if (!mounted) return;
      setState(() {
        _place = spot;
        _editingPlace = false;
        _savingPlace = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            previous == null
                ? 'Place added to the countdown.'
                : 'Place updated on the countdown.',
          ),
        ),
      );
    } on MilestonesFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _savingPlace = false;
        _placeError = failure.message;
      });
    }
  }

  Future<void> _clearPlace() async {
    if (_savingPlace) return;

    setState(() {
      _savingPlace = true;
      _placeError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(milestonesRepositoryProvider(widget.circleId))
          .setPlace(milestoneId: widget.milestone.id, place: null);
      if (!mounted) return;
      setState(() {
        _place = null;
        _editingPlace = false;
        _savingPlace = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Place removed from the countdown.')),
      );
    } on MilestonesFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _savingPlace = false;
        _placeError = failure.message;
      });
    }
  }

  Future<void> _share() async {
    if (_sending) return;
    setState(() => _sending = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(chatRepositoryProvider(widget.circleId))
          .sendText(
            senderId: widget.currentUserId,
            text: milestoneShareText(
              widget.milestone.withPlan(place: _place, startsAt: _start),
            ),
          );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Shared the plan in the crew chat.')),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not reach the crew chat.')),
      );
    }
  }

  Future<void> _planMeetup() async {
    final place = _place?.trim();
    final handoff = widget.onPlanMeetup;
    if (_planning || place == null || place.isEmpty || handoff == null) return;

    setState(() => _planning = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final spots = await ref
          .read(navigationGatewayProvider)
          .searchPlaces(place);
      if (!mounted) return;

      if (spots.isEmpty) {
        setState(() => _planning = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Could not find “$place” on the map.'),
          ),
        );
        return;
      }

      final spot = spots.first;
      navigator.pop();
      handoff(
        GeoPoint(latitude: spot.latitude, longitude: spot.longitude),
        spot.displayName,
      );
    } on NavigationFailure catch (failure) {
      if (!mounted) return;
      setState(() => _planning = false);
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Widget get _shareIcon => _sending
      ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Icon(Icons.campaign_rounded, size: 18);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final milestone = widget.milestone;
    final kind = milestone.kind;
    final now = widget.now ?? DateTime.now();
    final start = _start;
    final place = _place;
    final note = milestone.subtitle;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: kind.colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                  ),
                  child: Icon(kind.icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    kind.label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                _CountdownChip(
                  label: formatCountdown(milestone.daysFrom(now)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(milestone.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            if (!_editingWhen)
              _DetailRow(
                icon: Icons.event_rounded,
                label: 'When',
                value:
                    '${formatMilestoneDate(milestone.date)}'
                    '${start == null ? '' : ' · ${formatEventTime(start)}'}',
                trailing: TextButton(
                  key: const ValueKey('edit-when'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _startWhen,
                  child: Text(start == null ? 'Add time' : 'Edit'),
                ),
              ),
            if (_editingWhen) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Start time',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const ValueKey('pick-time'),
                onPressed: _savingWhen ? null : _pickTime,
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: Text(
                  _draftTime == null
                      ? 'Pick a time'
                      : formatEventTime(
                          DateTime(
                            2000,
                            1,
                            1,
                            _draftTime!.hour,
                            _draftTime!.minute,
                          ),
                        ),
                ),
              ),
              if (_whenError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _whenError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ],
              Row(
                children: [
                  TextButton(
                    onPressed: _savingWhen ? null : _cancelWhen,
                    child: const Text('Cancel'),
                  ),
                  if (start != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      key: const ValueKey('clear-time'),
                      onPressed: _savingWhen ? null : _clearTime,
                      child: const Text('Remove time'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('save-time'),
                  onPressed: _savingWhen ? null : _saveTime,
                  child: _savingWhen
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save time'),
                ),
              ),
            ],
            if (place != null && !_editingPlace) ...[
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                icon: Icons.place_rounded,
                label: 'Where',
                value: place,
                trailing: TextButton(
                  key: const ValueKey('edit-place'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _startPlace,
                  child: const Text('Edit'),
                ),
              ),
            ],
            if (_editingPlace) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('place-field'),
                controller: _placeController,
                autofocus: true,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Place',
                  hintText: 'Where are you meeting?',
                  prefixIcon: Icon(Icons.place_rounded, size: 20),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _savePlace(),
              ),
              if (_placeError != null) ...[
                Text(
                  _placeError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                children: [
                  TextButton(
                    onPressed: _savingPlace ? null : _cancelPlace,
                    child: const Text('Cancel'),
                  ),
                  if (place != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      key: const ValueKey('clear-place'),
                      onPressed: _savingPlace ? null : _clearPlace,
                      child: const Text('Remove place'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('save-place'),
                  onPressed: _savingPlace ? null : _savePlace,
                  child: _savingPlace
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save place'),
                ),
              ),
            ] else if (place == null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                key: const ValueKey('add-place'),
                onPressed: _startPlace,
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: const Text('Add a place'),
              ),
            ],
            if (note != null) ...[
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                icon: Icons.sticky_note_2_rounded,
                label: 'Note',
                value: note,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (place != null && widget.onPlanMeetup != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('plan-meetup'),
                  onPressed: _planning ? null : _planMeetup,
                  icon: _planning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.flag_rounded, size: 18),
                  label: Text(
                    _planning
                        ? 'Finding the place…'
                        : 'Set as group destination',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Opens the map with this place ready. Confirm there to send '
                'the whole crew.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            SizedBox(
              width: double.infinity,
              child: place == null
                  ? FilledButton.icon(
                      key: const ValueKey('share-countdown-plan'),
                      onPressed: _sending ? null : _share,
                      icon: _shareIcon,
                      label: const Text('Share with the crew'),
                    )
                  : OutlinedButton.icon(
                      key: const ValueKey('share-countdown-plan'),
                      onPressed: _sending ? null : _share,
                      icon: _shareIcon,
                      label: const Text('Share with the crew'),
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Posts the plan to the group chat so everyone can get ready.',
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

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
