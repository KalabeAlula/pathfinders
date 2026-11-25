import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/utils/time_format.dart';
import '../../application/milestones_providers.dart';
import '../../domain/milestones_failure.dart';
import '../../domain/shared_milestone.dart';
import '../milestone_style.dart';

Future<void> showMilestoneComposer(
  BuildContext context, {
  required String circleId,
  required String createdBy,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        MilestoneComposerSheet(circleId: circleId, createdBy: createdBy),
  );
}

class MilestoneComposerSheet extends ConsumerStatefulWidget {
  const MilestoneComposerSheet({
    super.key,
    required this.circleId,
    required this.createdBy,
  });

  final String circleId;
  final String createdBy;

  @override
  ConsumerState<MilestoneComposerSheet> createState() =>
      _MilestoneComposerSheetState();
}

class _MilestoneComposerSheetState
    extends ConsumerState<MilestoneComposerSheet> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _place = TextEditingController();
  MilestoneKind _kind = MilestoneKind.birthday;
  late DateTime _date = _defaultDate();
  TimeOfDay? _time;
  bool _saving = false;
  String? _error;

  static DateTime _defaultDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: DateTime(today.year + 10),
      helpText: 'When is it?',
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 19, minute: 0),
      helpText: 'What time?',
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give it a name first.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final time = _time;
    try {
      await ref
          .read(milestonesRepositoryProvider(widget.circleId))
          .addMilestone(
            createdBy: widget.createdBy,
            title: title,
            date: _date,
            kind: _kind,
            subtitle: _subtitle.text,
            startsAt: time == null
                ? null
                : DateTime(
                    _date.year,
                    _date.month,
                    _date.day,
                    time.hour,
                    time.minute,
                  ),
            place: _place.text,
          );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Countdown added to the dashboard.')),
      );
    } on MilestonesFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  static Widget? _thresholdCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    if (maxLength == null || currentLength < (maxLength * 0.75).floor()) {
      return null;
    }
    final scheme = Theme.of(context).colorScheme;
    return Text(
      '$currentLength/$maxLength',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: currentLength >= maxLength
            ? scheme.error
            : scheme.onSurfaceVariant,
      ),
    );
  }

  String _relativeDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_date.year, _date.month, _date.day);
    final days = target.difference(today).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'in ${days}d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtleBorder = scheme.outlineVariant.withValues(alpha: 0.55);
    final fieldRadius = BorderRadius.circular(16);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a countdown', style: theme.textTheme.titleLarge),
            const SizedBox(height: 3),
            Text(
              'A date the whole circle is looking forward to.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: true,
              maxLength: 80,
              buildCounter: _thresholdCounter,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "What are you counting down to?",
                hintStyle: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: fieldRadius,
                  borderSide: BorderSide(color: subtleBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: fieldRadius,
                  borderSide: BorderSide(color: subtleBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: fieldRadius,
                  borderSide: BorderSide(color: scheme.primary, width: 1.5),
                ),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Kind',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < MilestoneKind.values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _KindCard(
                      kind: MilestoneKind.values[i],
                      selected: MilestoneKind.values[i] == _kind,
                      onTap: () =>
                          setState(() => _kind = MilestoneKind.values[i]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _PickerButton(
                    onTap: _pickDate,
                    icon: Icons.event_rounded,
                    child: Text.rich(
                      TextSpan(
                        text: formatMilestoneDate(_date),
                        children: [
                          TextSpan(
                            text: ' · ${_relativeDateLabel()}',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _PickerButton(
                    onTap: _pickTime,
                    icon: Icons.schedule_rounded,
                    child: Text(
                      _time == null
                          ? 'Add time'
                          : formatEventTime(
                              DateTime(2000, 1, 1, _time!.hour, _time!.minute),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _time == null
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                        fontWeight: _time == null
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: fieldRadius,
                border: Border.all(color: subtleBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _place,
                    maxLength: 80,
                    buildCounter: _thresholdCounter,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Place (optional)',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.place_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 40,
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: subtleBorder),
                  TextField(
                    controller: _subtitle,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 120,
                    buildCounter: _thresholdCounter,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Note — the plan, the reason (optional)',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.notes_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: fieldRadius),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add countdown'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final MilestoneKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = kind.colors.first;
    final radius = BorderRadius.circular(14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : scheme.surfaceContainerHigh,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? accent
                  : scheme.outlineVariant.withValues(alpha: 0.55),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                kind.icon,
                size: 20,
                color: selected ? accent : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 5),
              Text(
                kind.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? accent : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.onTap,
    required this.icon,
    required this.child,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);

    return Material(
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
