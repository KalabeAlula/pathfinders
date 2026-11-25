import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../application/memories_providers.dart';
import '../../domain/memories_failure.dart';
import '../../domain/memory_photo.dart';
import '../../domain/memory_post.dart';
import '../memory_mood_colors.dart';

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

  Widget _photoArea(ThemeData theme, ColorScheme scheme) {
    final photo = _photo;
    final radius = BorderRadius.circular(16);
    final subtleBorder = scheme.outlineVariant.withValues(alpha: 0.55);

    if (photo == null) {
      return Material(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: subtleBorder),
        ),
        child: InkWell(
          onTap: _picking ? null : _pickPhoto,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: _picking
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 20,
                          color: scheme.primary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _picking ? 'Opening your photos…' : 'Add a photo',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Optional · JPEG or PNG',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: radius,
          child: Image.memory(
            photo.bytes,
            width: double.infinity,
            height: 172,
            fit: BoxFit.cover,
            cacheWidth: 1200,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _picking ? null : _pickPhoto,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: Colors.black.withValues(alpha: 0.58),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _photo = null),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fieldRadius = BorderRadius.circular(16);
    final subtleBorder = scheme.outlineVariant.withValues(alpha: 0.55);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text('Save a memory', style: theme.textTheme.titleLarge),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: subtleBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Circle only',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
              buildCounter: _thresholdCounter,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'What happened today?',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                contentPadding: const EdgeInsets.all(16),
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
            const SizedBox(height: 14),
            Text(
              'Mood',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MemoryMood.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final mood = MemoryMood.values[index];
                  final selected = mood == _mood;
                  final accent = mood.colors.first;
                  final pillRadius = BorderRadius.circular(999);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _mood = mood),
                      borderRadius: pillRadius,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? accent.withValues(alpha: 0.16)
                              : scheme.surfaceContainerHigh,
                          borderRadius: pillRadius,
                          border: Border.all(
                            color: selected ? accent : subtleBorder,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          '${mood.emoji} ${mood.label}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: selected ? accent : scheme.onSurfaceVariant,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _place,
              maxLength: 80,
              buildCounter: _thresholdCounter,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Add a place (optional)',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.place_outlined,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
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
