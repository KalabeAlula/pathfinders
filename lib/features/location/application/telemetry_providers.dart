import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/geolocator_telemetry_source.dart';
import '../data/supabase_telemetry_repository.dart';
import '../domain/device_telemetry.dart';
import '../domain/privacy_mode.dart';
import '../domain/telemetry_cadence.dart';
import '../domain/telemetry_failure.dart';
import '../domain/telemetry_repository.dart';

part 'telemetry_providers.g.dart';

@Riverpod(keepAlive: true)
TelemetryRepository telemetryRepository(Ref ref, String userId) =>
    SupabaseTelemetryRepository(
      ref.watch(supabaseClientProvider),
      userId: userId,
    );

@Riverpod(keepAlive: true)
DeviceTelemetrySource deviceTelemetrySource(Ref ref) =>
    GeolocatorTelemetrySource();

class TelemetryState {
  const TelemetryState({
    this.mode = PrivacyMode.exact,
    this.permission,
    this.backgroundGranted = false,
    this.notificationsGranted,
    this.ready = false,
    this.lastSentAt,
    this.lastReading,
    this.error,
  });

  final PrivacyMode mode;
  final TelemetryPermission? permission;

  /// Whether the OS will still deliver fixes with the app off-screen.
  final bool backgroundGranted;

  /// Whether the member will see the foreground-service notification. Null
  /// until we have asked (or when the platform has no such switch).
  final bool? notificationsGranted;

  final bool ready;
  final DateTime? lastSentAt;

  /// The most recent device fix, for screens that need the local position
  /// immediately rather than after a database round trip.
  final DeviceReading? lastReading;

  final String? error;

  /// True when this device is allowed to send a fix and the member wants one
  /// to be visible.
  bool get isSharing =>
      permission == TelemetryPermission.granted && mode != PrivacyMode.paused;

  /// True when sharing keeps running after the member leaves the app.
  bool get isSharingInBackground => isSharing && backgroundGranted;

  /// True when the member asked for sharing but the platform is blocking it.
  bool get isBlocked =>
      permission != null &&
      permission != TelemetryPermission.granted &&
      permission != TelemetryPermission.unsupported;

  TelemetryState copyWith({
    PrivacyMode? mode,
    TelemetryPermission? permission,
    bool? backgroundGranted,
    bool? notificationsGranted,
    bool? ready,
    DateTime? lastSentAt,
    DeviceReading? lastReading,
    String? error,
    bool clearError = false,
  }) {
    return TelemetryState(
      mode: mode ?? this.mode,
      permission: permission ?? this.permission,
      backgroundGranted: backgroundGranted ?? this.backgroundGranted,
      notificationsGranted: notificationsGranted ?? this.notificationsGranted,
      ready: ready ?? this.ready,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      lastReading: lastReading ?? this.lastReading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives this device's half of the circle telemetry: permission, a fix stream
/// that keeps running off-screen, battery, and the member's sharing mode.
@riverpod
class TelemetryController extends _$TelemetryController {
  Timer? _keepAlive;
  Duration? _keepAlivePeriod;
  StreamSubscription<DeviceReading>? _fixes;
  AppLifecycleListener? _lifecycle;
  TelemetryCadence? _cadence;
  DeviceReading? _lastReading;
  bool _sending = false;
  bool _sendQueued = false;
  bool _askedForNotifications = false;
  String _userId = '';

  @override
  TelemetryState build(String userId) {
    _userId = userId;
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_onResume()));
    ref.onDispose(() {
      _keepAlive?.cancel();
      _keepAlive = null;
      unawaited(_fixes?.cancel());
      _fixes = null;
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    unawaited(_bootstrap());
    return const TelemetryState();
  }

  /// Re-asks for access, e.g. after the member returns from system settings.
  Future<void> requestAccess() => _refreshPermission(request: true);

  /// Raises sharing to "always", which is what lets fixes keep arriving after
  /// the app leaves the screen.
  Future<void> requestBackgroundAccess() async {
    final granted = await ref
        .read(deviceTelemetrySourceProvider)
        .requestBackgroundAccess();
    if (!ref.mounted) return;
    _emit(state.copyWith(backgroundGranted: granted));
  }

  Future<void> setMode(PrivacyMode mode) async {
    if (mode == state.mode) return;

    final previous = state.mode;
    _emit(state.copyWith(mode: mode, clearError: true));

    try {
      await ref.read(telemetryRepositoryProvider(_userId)).setPrivacyMode(mode);
      if (!ref.mounted) return;
      await _syncTracking();
    } on TelemetryFailure catch (error) {
      _emit(state.copyWith(mode: previous, error: error.message));
    }
  }

  Future<void> openAppSettings() =>
      ref.read(deviceTelemetrySourceProvider).openAppSettings();

  Future<void> openLocationSettings() =>
      ref.read(deviceTelemetrySourceProvider).openLocationSettings();

  Future<void> _bootstrap() async {
    // Mark this member online before the privacy round trip. A point-free
    // heartbeat is safe in every mode: the server keeps any existing fix but
    // refreshes `updated_at`.
    unawaited(_sendPresence());
    try {
      final mode = await ref
          .read(telemetryRepositoryProvider(_userId))
          .loadPrivacyMode();
      _emit(state.copyWith(mode: mode, ready: true));
    } on TelemetryFailure catch (error) {
      _emit(state.copyWith(ready: true, error: error.message));
    } catch (_) {
      // A single failed read must not leave the circle without a heartbeat.
      _emit(state.copyWith(ready: true));
    }
    await _refreshPermission();
  }

  /// Back from the background: mark this member online before anything else,
  /// then re-check access in case it changed while we were away.
  Future<void> _onResume() async {
    if (!ref.mounted) return;
    // The OS may have suspended the periodic timer, so start a fresh one.
    _resyncKeepAlive();
    await _send();
    await _refreshPermission();
  }

  Future<void> _sendPresence() async {
    try {
      await ref.read(telemetryRepositoryProvider(_userId)).report();
    } catch (_) {
      // The full send after bootstrap retries with battery and position.
    }
  }

  Future<void> _refreshPermission({bool request = false}) async {
    final source = ref.read(deviceTelemetrySourceProvider);
    final previousPermission = state.permission;
    final previousBackground = state.backgroundGranted;

    TelemetryPermission permission;
    try {
      permission = request
          ? await source.requestPermission()
          : await source.checkPermission();
    } catch (_) {
      permission = TelemetryPermission.denied;
    }
    if (!ref.mounted) return;

    var background = false;
    if (permission == TelemetryPermission.granted) {
      try {
        background = await source.hasBackgroundAccess();
      } catch (_) {
        background = false;
      }
    }
    if (!ref.mounted) return;

    _emit(
      state.copyWith(
        permission: permission,
        backgroundGranted: background,
        clearError: true,
      ),
    );

    // A resume that changed nothing already sent its heartbeat above, so this
    // avoids a duplicate report on every return to the app.
    final changed =
        permission != previousPermission || background != previousBackground;
    if (changed || !state.isSharing) await _syncTracking();
  }

  Future<void> _syncTracking() async {
    final canShare =
        state.permission == TelemetryPermission.granted &&
        state.mode != PrivacyMode.paused;

    if (!canShare) {
      // A paused member must never put a remembered point on the wire.
      _lastReading = null;
      await _stopFixes();
      _restartKeepAlive(TelemetryCadence.batteryOnly.keepAlive);
      await _send();
      return;
    }

    await _ensureNotificationAccess();
    await _send();
  }

  Future<void> _ensureNotificationAccess() async {
    if (_askedForNotifications) return;
    _askedForNotifications = true;

    final granted = await ref
        .read(deviceTelemetrySourceProvider)
        .requestNotificationPermission();
    if (!ref.mounted) return;
    _emit(state.copyWith(notificationsGranted: granted));
  }

  Future<void> _send() async {
    if (!ref.mounted) return;
    if (_sending) {
      // A heartbeat or fix that lands mid-flight still has to reach the
      // server; dropping it is how an active member looks offline.
      _sendQueued = true;
      return;
    }
    _sending = true;

    try {
      final source = ref.read(deviceTelemetrySourceProvider);
      final battery = await source.battery();
      final paused = state.mode == PrivacyMode.paused;
      final canShare =
          state.permission == TelemetryPermission.granted && !paused;

      if (canShare) {
        final cadence = TelemetryCadence.forBattery(
          percent: battery.percent,
          isCharging: battery.isCharging,
        );
        if (_fixes == null || cadence != _cadence) {
          _cadence = cadence;
          _startFixes(cadence);
        }
        _restartKeepAlive(cadence.keepAlive);
        await _primeReading(source);
      } else {
        _lastReading = null;
        await _stopFixes();
        _restartKeepAlive(TelemetryCadence.batteryOnly.keepAlive);
      }

      final reading = canShare ? _lastReading : null;
      await ref
          .read(telemetryRepositoryProvider(_userId))
          .report(
            point: reading?.point,
            accuracyMeters: reading?.accuracyMeters ?? 0,
            speedKph: reading?.speedKph ?? 0,
            batteryPercent: battery.percent,
            isCharging: battery.isCharging,
          );

      if (!ref.mounted) return;
      _emit(
        state.copyWith(lastSentAt: DateTime.now().toUtc(), clearError: true),
      );
    } on TelemetryFailure catch (error) {
      _emit(state.copyWith(error: error.message));
    } catch (_) {
      _emit(
        state.copyWith(
          error: 'Could not share your location. We will try again shortly.',
        ),
      );
    } finally {
      _sending = false;
      if (_sendQueued && ref.mounted) {
        _sendQueued = false;
        unawaited(_send());
      }
    }
  }

  /// Gives the map something to show before the first streamed fix lands.
  Future<void> _primeReading(DeviceTelemetrySource source) async {
    if (_lastReading != null) return;
    final reading = await source.currentReading();
    _lastReading ??= reading;
    if (reading != null && ref.mounted) {
      _emit(state.copyWith(lastReading: reading));
    }
  }

  void _startFixes(TelemetryCadence cadence) {
    final old = _fixes;
    StreamSubscription<DeviceReading>? sub;

    try {
      sub = ref
          .read(deviceTelemetrySourceProvider)
          .positionUpdates(
            interval: cadence.interval,
            distanceFilter: cadence.distanceFilter,
          )
          .listen(
            (reading) {
              if (!ref.mounted) return;
              _lastReading = reading;
              _emit(state.copyWith(lastReading: reading));
              unawaited(_send());
            },
            onError: (Object _) {
              // Access can be withdrawn while the stream runs. Drop it and let
              // the next heartbeat rebuild it rather than retrying in a loop.
              if (identical(_fixes, sub)) {
                _fixes = null;
                _cadence = null;
              }
              unawaited(sub?.cancel());
            },
            cancelOnError: true,
          );
    } catch (_) {
      _cadence = null;
    }

    _fixes = sub;
    unawaited(old?.cancel());
  }

  Future<void> _stopFixes() async {
    final sub = _fixes;
    _fixes = null;
    _cadence = null;
    await sub?.cancel();
  }

  void _restartKeepAlive(Duration period) {
    if (_keepAlivePeriod == period && _keepAlive != null) return;
    _keepAlivePeriod = period;
    _resyncKeepAlive();
  }

  /// Re-arms the heartbeat without changing its period. The OS can suspend
  /// timers while the app is backgrounded, so resume calls this even when the
  /// period is unchanged.
  void _resyncKeepAlive() {
    final period = _keepAlivePeriod;
    if (period == null) return;
    _keepAlive?.cancel();
    _keepAlive = Timer.periodic(period, (_) => unawaited(_send()));
  }

  void _emit(TelemetryState next) {
    if (!ref.mounted) return;
    state = next;
  }
}
