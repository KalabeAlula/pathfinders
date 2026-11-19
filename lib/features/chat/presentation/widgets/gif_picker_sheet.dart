import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/config/gif_config.dart';
import '../../data/giphy_client.dart';

/// Opens the Giphy picker and returns the rendition to post, or null when the
/// member backs out without choosing.
Future<String?> showGifPickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const GifPickerSheet(),
  );
}

class GifPickerSheet extends StatefulWidget {
  const GifPickerSheet({super.key});

  @override
  State<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<GifPickerSheet> {
  final _search = TextEditingController();
  final _httpClient = http.Client();
  late final _giphy = GiphyClient(_httpClient);
  Timer? _debounce;

  List<GifResult> _results = const [];
  bool _loading = true;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load(null);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _httpClient.close();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _load(value.trim()),
    );
  }

  Future<void> _load(String? query) async {
    if (!GifConfig.isConfigured) {
      setState(() => _loading = false);
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = query == null || query.isEmpty
          ? await _giphy.trending()
          : await _giphy.search(query);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on GifSearchFailure catch (failure) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = failure.message;
        _loading = false;
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
        height: math.min(size.height * 0.7, size.height - inset - 96),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.gif_box_rounded, size: 22, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('Send a GIF', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _search,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search GIPHY',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(child: _content(theme, scheme)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Powered by '),
                    TextSpan(
                      text: 'GIPHY',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(ThemeData theme, ColorScheme scheme) {
    if (!GifConfig.isConfigured) {
      return _Message(
        icon: Icons.key_off_rounded,
        title: 'GIF search is not set up in this build',
        body:
            'Add a GIPHY_API_KEY entry to mapbox.env.json and rebuild to '
            'turn the picker on.',
      );
    }

    final error = _error;
    if (error != null) {
      final query = _search.text.trim();
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: 'GIPHY did not answer',
        body: error,
        action: TextButton(
          onPressed: () => _load(query.isEmpty ? null : query),
          child: const Text('Try again'),
        ),
      );
    }

    if (_loading && _results.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_results.isEmpty) {
      return const _Message(
        icon: Icons.gif_box_outlined,
        title: 'No GIFs found',
        body: 'Try a different search.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) =>
          _GifTile(gif: _results[index], scheme: scheme),
    );
  }
}

class _GifTile extends StatelessWidget {
  const _GifTile({required this.gif, required this.scheme});

  final GifResult gif;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: gif.title,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop(gif.url);
          },
          child: Image.network(
            gif.previewUrl,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : ColoredBox(color: scheme.surfaceContainerHigh),
            errorBuilder: (_, _, _) => ColoredBox(
              color: scheme.surfaceContainerHigh,
              child: Icon(
                Icons.gif_box_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: scheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 4), action!],
          ],
        ),
      ),
    );
  }
}
