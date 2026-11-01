import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../application/memories_providers.dart';
import '../../domain/memories_failure.dart';
import '../../domain/memory_post.dart';

Future<void> showMemoryComposer(
  BuildContext context, {
  required String circleId,
  required String authorId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => MemoryComposerSheet(
      circleId: circleId,
      authorId: authorId,
    ),
  );
}

class MemoryComposerSheet extends ConsumerStatefulWidget {
  const MemoryComposerSheet({
    super.key,
    required this.circleId,
    required this.authorId,
  });

  final String circleId;
  final String authorId;

  @override
  ConsumerState<MemoryComposerSheet> createState() =>
      _MemoryComposerSheetState();
}

class _MemoryComposerSheetState extends ConsumerState<MemoryComposerSheet> {
  final _text = TextEditingController();
  final _place = TextEditingController();
  MemoryMood _mood = MemoryMood.cozy;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Write a few words first.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(memoriesRepositoryProvider(widget.circleId)).addMemory(
            authorId: widget.authorId,
            text: text,
            mood: _mood,
            placeLabel: _place.text,
          );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Memory saved for the crew.')),
      );
    } on MemoriesFailure catch (failure) {
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
            Text('Save a memory', style: theme.textTheme.titleLarge),
            const SizedBox(height: 3),
            Text(
              'Whatever you want the crew to find here later.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              maxLength: 600,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What happened today?',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Mood',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mood in MemoryMood.values)
                  ChoiceChip(
                    label: Text('${mood.emoji} ${mood.label}'),
                    selected: mood == _mood,
                    onSelected: (_) => setState(() => _mood = mood),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _place,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Somewhere',
                hintText: 'Optional — the place this belongs to',
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
                    : const Text('Save memory'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
