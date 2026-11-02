import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../location/application/telemetry_providers.dart';
import '../data/search_history_store.dart';
import '../domain/navigation_failure.dart';
import '../domain/place_suggestion.dart';
import 'navigation_providers.dart';

part 'map_search_providers.g.dart';

@riverpod
SearchHistoryStore searchHistoryStore(Ref ref, String userId) =>
    SearchHistoryStore(ref.watch(sharedPreferencesProvider), userId: userId);

class MapSearchState {
  const MapSearchState({
    this.query = '',
    this.results = const [],
    this.loading = false,
    this.error,
    this.history = const [],
  });

  final String query;
  final List<PlaceSuggestion> results;
  final bool loading;
  final String? error;

  /// Recent searches, newest first.
  final List<String> history;

  bool get hasResults => results.isNotEmpty;
  bool get hasHistory => history.isNotEmpty;
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
  SearchHistoryStore? _historyStore;

  @override
  MapSearchState build(String userId) {
    _userId = userId;
    _historyStore = ref.watch(searchHistoryStoreProvider(userId));
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
      _run++;
    });
    return MapSearchState(history: _historyStore!.read());
  }

  void search(String value) {
    final clean = value.trim();
    _debounce?.cancel();

    if (clean.length < 2) {
      _run++;
      state = MapSearchState(query: clean, history: state.history);
      return;
    }

    state = MapSearchState(query: clean, loading: true, history: state.history);
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_runSearch(clean)),
    );
  }

  /// Hides the suggestion list without touching the text field.
  void dismiss() {
    _debounce?.cancel();
    _run++;
    state = MapSearchState(query: state.query, history: state.history);
  }

  void reset() {
    _debounce?.cancel();
    _run++;
    state = MapSearchState(history: state.history);
  }

  /// Records a query the member actually used.
  Future<void> remember(String query) async {
    final store = _historyStore;
    if (store == null) return;
    await store.remember(query);
    if (!ref.mounted) return;
    state = MapSearchState(
      query: state.query,
      results: state.results,
      loading: state.loading,
      error: state.error,
      history: store.read(),
    );
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
        history: state.history,
      );
    } on NavigationFailure catch (failure) {
      if (!_isCurrent(run, query)) return;
      state = MapSearchState(
        query: query,
        error: failure.message,
        history: state.history,
      );
    }
  }

  bool _isCurrent(int run, String query) =>
      ref.mounted && run == _run && state.query == query;
}
