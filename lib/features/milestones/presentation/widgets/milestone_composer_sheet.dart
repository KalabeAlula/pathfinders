import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/utils/time_format.dart';
import '../../application/milestones_providers.dart';
import '../../domain/milestones_failure.dart';
import '../../domain/shared_milestone.dart';

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
  MilestoneKind _kind = MilestoneKind.birthday;
  late DateTime _date = _defaultDate();
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
    try {
      await ref
          .read(milestonesRepositoryProvider(widget.circleId))
          .addMilestone(
            createdBy: widget.createdBy,
            title: title,
            date: _date,
            kind: _kind,
            subtitle: _subtitle.text,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: "Hana's birthday",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Kind',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in MilestoneKind.values)
                  ChoiceChip(
                    avatar: Icon(kind.icon, size: 16),
                    label: Text(kind.label),
                    selected: kind == _kind,
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text('Date · ${formatMilestoneDate(_date)}'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitle,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional — the plan, the place, the reason',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
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

extension on MilestoneKind {
  String get label => switch (this) {
    MilestoneKind.birthday => 'Birthday',
    MilestoneKind.anniversary => 'Milestone',
    MilestoneKind.trip => 'Trip',
    MilestoneKind.goal => 'Goal',
  };

  IconData get icon => switch (this) {
    MilestoneKind.birthday => Icons.cake_rounded,
    MilestoneKind.anniversary => Icons.favorite_rounded,
    MilestoneKind.trip => Icons.luggage_rounded,
    MilestoneKind.goal => Icons.flag_rounded,
  };
}
