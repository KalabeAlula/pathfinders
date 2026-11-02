import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../application/memories_providers.dart';
import '../../domain/memories_failure.dart';
import '../../domain/memory_photo.dart';
import '../../domain/memory_post.dart';

Future<void> showMemoryComposer(
  BuildContext context, {
  required String circleId,
  required String authorId,
  String? initialPlace,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => MemoryComposerSheet(
      circleId: circleId,
      authorId: authorId,
      initialPlace: initialPlace,
    ),
  );
}

class MemoryComposerSheet extends ConsumerStatefulWidget {
  const MemoryComposerSheet({
    super.key,
    required this.circleId,
    required this.authorId,
    this.initialPlace,
  });

  final String circleId;
  final String authorId;

  /// Pre-filled "Somewhere" label, e.g. the destination just reached.
  final String? initialPlace;

  @override
  ConsumerState<MemoryComposerSheet> createState() =>
      _MemoryComposerSheetState();
}

class _MemoryComposerSheetState extends ConsumerState<MemoryComposerSheet> {
  final _text = TextEditingController();
  final _place = TextEditingController();
  MemoryMood _mood = MemoryMood.cozy;
  MemoryPhotoDraft? _photo;
  bool _picking = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final place = widget.initialPlace?.trim();
    if (place != null && place.isNotEmpty) {
      _place.text = place;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > MemoryPhotoDraft.maxBytes) {
        setState(() {
          _picking = false;
          _error = 'That photo is a little too large. Try a smaller one.';
        });
        return;
      }

      final contentType = MemoryPhotoDraft.contentTypeFor(
        file.mimeType,
        file.name,
      );
      if (contentType == null) {
        setState(() {
          _picking = false;
          _error = 'That image type is not supported. Pick a JPEG or PNG.';
        });
        return;
      }
      setState(() {
        _photo = MemoryPhotoDraft(
          bytes: bytes,
          contentType: contentType,
          extension: MemoryPhotoDraft.extensionFor(contentType),
        );
        _picking = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = 'Could not open your photos. Check access and try again.';
      });
    }
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty && _photo == null) {
      setState(() => _error = 'Add a photo or write a few words first.');
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
          .read(memoriesRepositoryProvider(widget.circleId))
          .addMemory(
            authorId: widget.authorId,
            text: text,
            mood: _mood,
            placeLabel: _place.text,
            photo: _photo,
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

  Widget _photoArea(ThemeData theme, ColorScheme scheme) {
    final photo = _photo;
    if (photo == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _picking ? null : _pickPhoto,
            icon: _picking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text(_picking ? 'Opening your photos…' : 'Add a photo'),
          ),
          const SizedBox(height: 4),
          Text(
            'Only your circle can see it.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              child: Image.memory(
                photo.bytes,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                cacheWidth: 1200,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _photo = null),
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _picking ? null : _pickPhoto,
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Change photo'),
          ),
        ),
      ],
    );
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
            _photoArea(theme, scheme),
            const SizedBox(height: 14),
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
