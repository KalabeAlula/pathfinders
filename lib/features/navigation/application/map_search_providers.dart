import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../location/application/telemetry_providers.dart';
import '../domain/navigation_failure.dart';
import '../domain/place_suggestion.dart';
import 'navigation_providers.dart';

part 'map_search_providers.g.dart';

class MapSearchState {
  const MapSearchState({
    this.query = '',
    this.results = const [],
    this.loading = false,
    this.error,
  });

  final String query;
  final List<PlaceSuggestion> results;
  final bool loading;
  final String? error;

  bool get hasResults => results.isNotEmpty;
  bool get isActive => loading || results.isNotEmpty || error != null;
}

/// Debounced Mapbox autocomplete for the map's search bar.
///
/// Results are biased around the member's last GPS fix so nearby cafes and
/// streets rank above far-away matches.
@riverpod
class MapSearchController extends _$MapSearchController {
  Timer? _debounce;
  int _run = 0;
  String _userId = '';

  @override
  MapSearchState build(String userId) {
    _userId = userId;
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
      _run++;
    });
    return const MapSearchState();
  }

  void search(String value) {
    final clean = value.trim();
    _debounce?.cancel();

    if (clean.length < 2) {
      _run++;
      state = MapSearchState(query: clean);
      return;
    }

    state = MapSearchState(query: clean, loading: true);
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_runSearch(clean)),
    );
  }

  /// Hides the suggestion list without touching the text field.
  void dismiss() {
    _debounce?.cancel();
    _run++;
    state = MapSearchState(query: state.query);
  }

  void reset() {
    _debounce?.cancel();
    _run++;
    state = const MapSearchState();
  }

  Future<void> _runSearch(String query) async {
    final run = ++_run;
    final proximity = ref
        .read(telemetryControllerProvider(_userId))
        .lastReading
        ?.point;

    try {
      final results = await ref
          .read(navigationGatewayProvider)
          .searchPlaces(query, proximity: proximity);
      if (!_isCurrent(run, query)) return;
      state = MapSearchState(
        query: query,
        results: results,
        error: results.isEmpty ? 'No places matched that search.' : null,
      );
    } on NavigationFailure catch (failure) {
      if (!_isCurrent(run, query)) return;
      state = MapSearchState(query: query, error: failure.message);
    }
  }

  bool _isCurrent(int run, String query) =>
      ref.mounted && run == _run && state.query == query;
}
