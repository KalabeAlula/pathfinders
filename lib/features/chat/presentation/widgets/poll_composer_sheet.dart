import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../location/application/telemetry_providers.dart';
import '../../../location/domain/geo_point.dart';
import '../../../navigation/application/navigation_providers.dart';
import '../../../navigation/domain/navigation_failure.dart';
import '../../../navigation/domain/place_suggestion.dart';
import '../../domain/chat_poll.dart';

/// Question and options for a new vote, or null when the member backs out.
typedef PollComposerResult = ({
  String question,
  List<ChatPollDraftOption> options,
});

Future<PollComposerResult?> showPollComposerSheet(
  BuildContext context, {
  required String userId,
}) {
  return showModalBottomSheet<PollComposerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => PollComposerSheet(userId: userId),
  );
}

class PollComposerSheet extends ConsumerStatefulWidget {
  const PollComposerSheet({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<PollComposerSheet> createState() => _PollComposerSheetState();
}

class _PollComposerSheetState extends ConsumerState<PollComposerSheet> {
  final _question = TextEditingController();
  final _options = <_DraftOption>[];

  static const _maxOptions = 6;

  @override
  void initState() {
    super.initState();
    _question.addListener(_refresh);
    _addOption();
    _addOption();
  }

  @override
  void dispose() {
    _question.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _addOption() {
    if (_options.length >= _maxOptions) return;
    setState(
      () => _options.add(_DraftOption()..controller.addListener(_refresh)),
    );
  }

  void _removeOption(_DraftOption option) {
    if (_options.length <= 2) return;
    setState(() => _options.remove(option));
    option.dispose();
  }

  Future<void> _attachPlace(_DraftOption option) async {
    final proximity = ref
        .read(telemetryControllerProvider(widget.userId))
        .lastReading
        ?.point;
    final place = await showModalBottomSheet<PlaceSuggestion>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _PlacePickerSheet(proximity: proximity),
    );
    if (!mounted || place == null) return;
    setState(() => option.place = place);
  }

  bool get _complete {
    final question = _question.text.trim();
    if (question.isEmpty || question.length > 160) return false;
    if (_options.length < 2) return false;
    return _options.every((option) {
      final label = option.controller.text.trim();
      return label.isNotEmpty && label.length <= 80;
    });
  }

  void _submit() {
    if (!_complete) return;
    Navigator.of(context).pop((
      question: _question.text.trim(),
      options: [
        for (final option in _options)
          ChatPollDraftOption(
            label: option.controller.text.trim(),
            latitude: option.place?.latitude,
            longitude: option.place?.longitude,
            placeLabel: _shortPlace(option.place),
          ),
      ],
    ));
  }

  static String? _shortPlace(PlaceSuggestion? place) {
    if (place == null) return null;
    final name = place.displayName;
    return name.length <= 120 ? name : name.substring(0, 120);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final size = MediaQuery.sizeOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.how_to_vote_rounded,
                    size: 22,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start a vote',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Everyone picks one option. A place is optional.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _question,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(160)],
                decoration: _fieldDecoration(
                  scheme,
                  hint: 'Where should we go tonight?',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Options',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < _options.length; i++)
                _OptionRow(
                  key: ObjectKey(_options[i]),
                  index: i,
                  option: _options[i],
                  canRemove: _options.length > 2,
                  onChanged: _refresh,
                  onAttachPlace: () => _attachPlace(_options[i]),
                  onClearPlace: () => setState(() => _options[i].place = null),
                  onRemove: () => _removeOption(_options[i]),
                ),
              if (_options.length < _maxOptions)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add option'),
                  ),
                ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _complete ? _submit : null,
                icon: const Icon(Icons.how_to_vote_rounded, size: 19),
                label: const Text('Start vote'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  ColorScheme scheme, {
  required String hint,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    filled: true,
    fillColor: scheme.surfaceContainerHigh,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: BorderSide.none,
    ),
  );
}

class _DraftOption {
  _DraftOption();

  final controller = TextEditingController();
  PlaceSuggestion? place;

  void dispose() => controller.dispose();
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.index,
    required this.option,
    required this.canRemove,
    required this.onChanged,
    required this.onAttachPlace,
    required this.onClearPlace,
    required this.onRemove,
  });

  final int index;
  final _DraftOption option;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onAttachPlace;
  final VoidCallback onClearPlace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final place = option.place;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: option.controller,
                  onChanged: (_) => onChanged(),
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [LengthLimitingTextInputFormatter(80)],
                  decoration: _fieldDecoration(
                    scheme,
                    hint: 'Option ${index + 1}',
                    suffix: IconButton(
                      tooltip: place == null ? 'Add a place' : 'Change place',
                      onPressed: onAttachPlace,
                      icon: Icon(
                        place == null
                            ? Icons.add_location_alt_outlined
                            : Icons.place_rounded,
                        size: 19,
                        color: place == null
                            ? scheme.onSurfaceVariant
                            : scheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: 'Remove option',
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (place != null)
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 4),
              child: InputChip(
                avatar: Icon(
                  Icons.place_rounded,
                  size: 15,
                  color: scheme.primary,
                ),
                label: Text(place.displayName),
                labelStyle: Theme.of(context).textTheme.labelSmall,
                visualDensity: VisualDensity.compact,
                onDeleted: onClearPlace,
                deleteIcon: const Icon(Icons.close_rounded, size: 15),
              ),
            ),
        ],
      ),
    );
  }
}

/// Debounced Mapbox search for the place one option points at.
class _PlacePickerSheet extends ConsumerStatefulWidget {
  const _PlacePickerSheet({this.proximity});

  final GeoPoint? proximity;

  @override
  ConsumerState<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends ConsumerState<_PlacePickerSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _results = const [];
  bool _loading = false;
  String? _error;
  int _run = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final clean = value.trim();
    if (clean.length < 2) {
      _run++;
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(clean));
  }

  Future<void> _search(String query) async {
    final run = ++_run;
    try {
      final results = await ref
          .read(navigationGatewayProvider)
          .searchPlaces(query, proximity: widget.proximity);
      if (!mounted || run != _run) return;
      setState(() {
        _results = results;
        _loading = false;
        _error = results.isEmpty ? 'No places matched that search.' : null;
      });
    } on NavigationFailure catch (failure) {
      if (!mounted || run != _run) return;
      setState(() {
        _results = const [];
        _loading = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final size = MediaQuery.sizeOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SizedBox(
        height: math.min(size.height * 0.75, size.height - inset - 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.place_rounded, size: 22, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('Attach a place', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _query,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: _fieldDecoration(
                  scheme,
                  hint: 'Search for a place',
                  suffix: IconButton(
                    onPressed: () => _onChanged(_query.text),
                    icon: const Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
            ),
            Expanded(child: _content(theme, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _content(ThemeData theme, ColorScheme scheme) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Text(
            'Type at least two letters to search.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final place = _results[index];
        return ListTile(
          leading: Icon(Icons.place_outlined, color: scheme.primary),
          title: Text(
            place.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: place.address == null
              ? null
              : Text(
                  place.address!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          onTap: () => Navigator.of(context).pop(place),
        );
      },
    );
  }
}
