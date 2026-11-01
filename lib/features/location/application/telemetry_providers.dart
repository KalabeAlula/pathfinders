import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../data/geolocator_telemetry_source.dart';
import '../data/supabase_telemetry_repository.dart';
import '../domain/device_telemetry.dart';
import '../domain/privacy_mode.dart';
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
    this.ready = false,
    this.lastSentAt,
    this.error,
  });

  final PrivacyMode mode;
  final TelemetryPermission? permission;
  final bool ready;
  final DateTime? lastSentAt;
  final String? error;

  /// True when this device is allowed to send a fix and the member wants one
  /// to be visible.
  bool get isSharing =>
      permission == TelemetryPermission.granted &&
      mode != PrivacyMode.paused;

  /// True when the member asked for sharing but the platform is blocking it.
  bool get isBlocked =>
      permission != null &&
      permission != TelemetryPermission.granted &&
      permission != TelemetryPermission.unsupported;

  TelemetryState copyWith({
    PrivacyMode? mode,
    TelemetryPermission? permission,
    bool? ready,
    DateTime? lastSentAt,
    String? error,
    bool clearError = false,
  }) {
    return TelemetryState(
      mode: mode ?? this.mode,
      permission: permission ?? this.permission,
      ready: ready ?? this.ready,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives this device's half of the circle telemetry: permission, a fix every
/// [reportInterval], battery, and the member's sharing mode.
@riverpod
class TelemetryController extends _$TelemetryController {
  static const Duration reportInterval = Duration(seconds: 30);

  Timer? _timer;
  bool _sending = false;
  String _userId = '';

  @override
  TelemetryState build(String userId) {
    _userId = userId;
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    unawaited(_bootstrap());
    return const TelemetryState();
  }

  /// Re-asks for access, e.g. after the member returns from system settings.
  Future<void> requestAccess() => _startReporting(requestPermission: true);

  Future<void> setMode(PrivacyMode mode) async {
    if (mode == state.mode) return;

    final previous = state.mode;
    _emit(state.copyWith(mode: mode, clearError: true));

    try {
      await ref.read(telemetryRepositoryProvider(_userId)).setPrivacyMode(mode);
      if (mode != PrivacyMode.paused) unawaited(_tick());
    } on TelemetryFailure catch (error) {
      _emit(state.copyWith(mode: previous, error: error.message));
    }
  }

  Future<void> openAppSettings() =>
      ref.read(deviceTelemetrySourceProvider).openAppSettings();

  Future<void> openLocationSettings() =>
      ref.read(deviceTelemetrySourceProvider).openLocationSettings();

  Future<void> _bootstrap() async {
    try {
      final mode =
          await ref.read(telemetryRepositoryProvider(_userId)).loadPrivacyMode();
      _emit(state.copyWith(mode: mode, ready: true));
    } on TelemetryFailure catch (error) {
      _emit(state.copyWith(ready: true, error: error.message));
    }
    await _startReporting(requestPermission: false);
  }

  Future<void> _startReporting({required bool requestPermission}) async {
    final source = ref.read(deviceTelemetrySourceProvider);
    final permission = requestPermission
        ? await source.requestPermission()
        : await source.checkPermission();
    if (!ref.mounted) return;

    _emit(state.copyWith(permission: permission, clearError: true));

    if (permission != TelemetryPermission.granted) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    _timer?.cancel();
    _timer = Timer.periodic(reportInterval, (_) => unawaited(_tick()));
    await _tick();
  }

  Future<void> _tick() async {
    if (_sending || !ref.mounted) return;
    _sending = true;

    try {
      final source = ref.read(deviceTelemetrySourceProvider);
      final battery = await source.battery();
      final paused = state.mode == PrivacyMode.paused;

      // A paused member never puts coordinates on the wire; the reading still
      // carries battery so presence stays honest.
      final reading = paused ? null : await source.currentReading();

      await ref.read(telemetryRepositoryProvider(_userId)).report(
            point: reading?.point,
            accuracyMeters: reading?.accuracyMeters ?? 0,
            speedKph: reading?.speedKph ?? 0,
            batteryPercent: battery.percent,
            isCharging: battery.isCharging,
          );

      _emit(state.copyWith(lastSentAt: DateTime.now(), clearError: true));
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
    }
  }

  void _emit(TelemetryState next) {
    if (!ref.mounted) return;
    state = next;
  }
}
