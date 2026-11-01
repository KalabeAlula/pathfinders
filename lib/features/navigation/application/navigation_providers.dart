import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/mapbox_config.dart';
import '../../auth/application/auth_providers.dart';
import '../../circle/application/circle_providers.dart';
import '../../circle/domain/circle_member.dart';
import '../../location/application/telemetry_providers.dart';
import '../../location/domain/device_telemetry.dart';
import '../../location/domain/geo_point.dart';
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
    final telemetry = ref.watch(telemetryControllerProvider(userId));
    final members = snapshot?.members ?? const <CircleMember>[];

    final located = {
      for (final member in members)
        if (_originFor(member, userId, telemetry.lastReading) != null)
          member.profile.id,
    };
    _cache.removeWhere((id, _) => !located.contains(id));
    _loading.removeWhere((id) => !located.contains(id));

    if (gateway.isConfigured) {
      _scheduleRefresh(
        userId: userId,
        destination: destination,
        members: members,
        liveReading: telemetry.lastReading,
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
      final cached = _cache[entry.key];
      if (cached == null) {
        work[entry.key] = entry.value;
        continue;
      }

      final moved = distanceMeters(cached.origin, entry.value);
      final age = now.difference(cached.computedAt);
      final offRoute = distanceToLineMeters(
            entry.value,
            cached.plan.geometry,
          ) >
          _offRouteThresholdMeters;

      if (moved > _moveThresholdMeters || age > _staleAfter || offRoute) {
        work[entry.key] = entry.value;
      }
    }
    if (work.isEmpty) return;

    final run = ++_run;
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
    if (!ref.mounted || run != _run) return;

    _loading.removeAll(work.keys);
    String? failure;
    for (final outcome in outcomes) {
      if (outcome.route != null) {
        _cache[outcome.memberId] = outcome.route!;
      } else {
        failure ??= outcome.error;
      }
    }

    _error = failure;
    state = _state(gateway.isConfigured, destination);
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
    return member.status?.location;
  }

  NavigationState _state(
    bool isConfigured,
    NavigationDestination destination,
  ) {
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
