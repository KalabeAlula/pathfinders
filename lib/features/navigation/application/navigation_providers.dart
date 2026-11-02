import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/mapbox_config.dart';
import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../circle/application/circle_providers.dart';
import '../../circle/domain/circle_member.dart';
import '../../location/application/telemetry_providers.dart';
import '../../location/domain/device_telemetry.dart';
import '../../location/domain/geo_point.dart';
import '../data/arrival_store.dart';
import '../data/mapbox_navigation_gateway.dart';
import '../data/supabase_navigation_repository.dart';
import '../domain/navigation_destination.dart';
import '../domain/navigation_failure.dart';
import '../domain/navigation_gateway.dart';
import '../domain/navigation_repository.dart';
import '../domain/route_geometry.dart';
import 'navigation_state.dart';

part 'navigation_providers.g.dart';

@Riverpod(keepAlive: true)
http.Client httpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
NavigationRepository navigationRepository(Ref ref, String circleId) =>
    SupabaseNavigationRepository(
      ref.watch(supabaseClientProvider),
      circleId: circleId,
    );

@Riverpod(keepAlive: true)
ArrivalStore arrivalStore(Ref ref) =>
    ArrivalStore(ref.watch(sharedPreferencesProvider));

@riverpod
Stream<NavigationDestination?> circleDestination(Ref ref, String circleId) =>
    ref.watch(navigationRepositoryProvider(circleId)).watchDestination();

@Riverpod(keepAlive: true)
NavigationGateway navigationGateway(Ref ref) => MapboxNavigationGateway(
  ref.watch(httpClientProvider),
  accessToken: MapboxConfig.accessToken,
);

/// Keeps one route per member up to date between the live fixes and the
/// shared destination.
@riverpod
class NavigationController extends _$NavigationController {
  final Map<String, MemberRoute> _cache = {};
  final Set<String> _loading = {};
  Timer? _debounce;
  int _run = 0;
  String? _error;
  String? _destinationKey;

  static const _refreshDelay = Duration(milliseconds: 400);
  static const _staleAfter = Duration(minutes: 2);
  static const _moveThresholdMeters = 100.0;
  static const _offRouteThresholdMeters = 60.0;

  @override
  NavigationState build(String circleId) {
    final gateway = ref.watch(navigationGatewayProvider);
    final session = ref.watch(authSessionProvider).value;
    final userId = session?.userId;
    final destination = ref.watch(circleDestinationProvider(circleId)).value;

    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
      _run++;
    });

    if (destination == null || userId == null) {
      _resetCache();
      return NavigationState(isConfigured: gateway.isConfigured);
    }

    final key = '${destination.latitude},${destination.longitude}';
    if (key != _destinationKey) {
      _destinationKey = key;
      _resetCache();
    }

    final snapshot = ref.watch(circleSnapshotProvider(userId)).value;
    final liveReading = ref.watch(
      telemetryControllerProvider(userId).select((state) => state.lastReading),
    );
    final members = snapshot?.members ?? const <CircleMember>[];

    final located = {
      for (final member in members)
        if (_originFor(member, userId, liveReading) != null) member.profile.id,
    };
    _cache.removeWhere((id, _) => !located.contains(id));
    _loading.removeWhere((id) => !located.contains(id));

    if (gateway.isConfigured) {
      _scheduleRefresh(
        userId: userId,
        destination: destination,
        members: members,
        liveReading: liveReading,
      );
    }

    return _state(gateway.isConfigured, destination);
  }

  void _scheduleRefresh({
    required String userId,
    required NavigationDestination destination,
    required List<CircleMember> members,
    required DeviceReading? liveReading,
  }) {
    _debounce?.cancel();
    _debounce = Timer(_refreshDelay, () {
      unawaited(
        _refresh(
          userId: userId,
          destination: destination,
          members: members,
          liveReading: liveReading,
        ),
      );
    });
  }

  Future<void> _refresh({
    required String userId,
    required NavigationDestination destination,
    required List<CircleMember> members,
    required DeviceReading? liveReading,
  }) async {
    if (!ref.mounted) return;
    final gateway = ref.read(navigationGatewayProvider);

    final origins = <String, GeoPoint>{};
    for (final member in members) {
      final origin = _originFor(member, userId, liveReading);
      if (origin != null) origins[member.profile.id] = origin;
    }
    if (origins.isEmpty) return;

    final now = DateTime.now();
    final work = <String, GeoPoint>{};
    for (final entry in origins.entries) {
      // A telemetry rebuild can land while the previous Directions call is
      // still open; never stack a second request for the same member.
      if (_loading.contains(entry.key)) continue;

      final cached = _cache[entry.key];
      if (cached == null) {
        work[entry.key] = entry.value;
        continue;
      }

      final moved = distanceMeters(cached.origin, entry.value);
      final age = now.difference(cached.computedAt);
      final offRoute =
          distanceToLineMeters(entry.value, cached.plan.geometry) >
          _offRouteThresholdMeters;

      if (moved > _moveThresholdMeters || age > _staleAfter || offRoute) {
        work[entry.key] = entry.value;
      }
    }
    if (work.isEmpty) return;

    final run = ++_run;
    final destinationKey = _destinationKey;
    _loading.addAll(work.keys);
    _error = null;
    state = _state(gateway.isConfigured, destination);

    final target = destination.point;
    final outcomes = await Future.wait([
      for (final entry in work.entries)
        _routeFor(
          gateway,
          memberId: entry.key,
          origin: entry.value,
          target: target,
        ),
    ]);
    if (!ref.mounted) return;

    _loading.removeAll(work.keys);

    // Re-read the live destination: a change during the request already
    // cleared the cache, and a label-only update must not be rolled back by
    // a request that started against the previous value.
    final current = ref.read(circleDestinationProvider(circleId)).value;
    if (current == null ||
        '${current.latitude},${current.longitude}' != destinationKey) {
      return;
    }

    String? failure;
    for (final outcome in outcomes) {
      final route = outcome.route;
      if (route == null) {
        failure ??= outcome.error;
        continue;
      }
      final cached = _cache[outcome.memberId];
      // A newer run may already have published a fresher route.
      if (cached == null || !cached.computedAt.isAfter(route.computedAt)) {
        _cache[outcome.memberId] = route;
      }
    }

    if (run == _run) _error = failure;
    // Publish even if a newer run is open, so a paid-for response is not
    // dropped before it reaches the map.
    state = _state(gateway.isConfigured, current);
  }

  Future<_RouteOutcome> _routeFor(
    NavigationGateway gateway, {
    required String memberId,
    required GeoPoint origin,
    required GeoPoint target,
  }) async {
    try {
      final plan = await gateway.route(from: origin, to: target);
      return _RouteOutcome.success(
        MemberRoute(
          memberId: memberId,
          plan: plan,
          origin: origin,
          computedAt: DateTime.now(),
        ),
      );
    } on NavigationFailure catch (failure) {
      return _RouteOutcome.failure(memberId, failure.message);
    } on Exception {
      return _RouteOutcome.failure(
        memberId,
        'Could not calculate a route right now.',
      );
    }
  }

  GeoPoint? _originFor(
    CircleMember member,
    String userId,
    DeviceReading? liveReading,
  ) {
    if (member.profile.id == userId) {
      return liveReading?.point ?? member.status?.location;
    }

    // Peers only get a route while they are actually reporting; a stale last
    // fix would otherwise keep drawing a route for someone who has gone dark.
    final status = member.status;
    if (status == null || status.location == null || !status.isOnline) {
      return null;
    }
    return status.location;
  }

  NavigationState _state(bool isConfigured, NavigationDestination destination) {
    return NavigationState(
      destination: destination,
      routes: Map.unmodifiable(_cache),
      loadingMemberIds: Set.unmodifiable(_loading),
      error: _error,
      isConfigured: isConfigured,
    );
  }

  void _resetCache() {
    _cache.clear();
    _loading.clear();
    _debounce?.cancel();
    _error = null;
  }
}

class _RouteOutcome {
  _RouteOutcome.success(MemberRoute this.route)
    : memberId = route.memberId,
      error = null;

  const _RouteOutcome.failure(this.memberId, this.error) : route = null;

  final String memberId;
  final MemberRoute? route;
  final String? error;
}
