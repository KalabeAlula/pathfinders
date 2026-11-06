import 'dart:async';

import '../domain/arrival.dart';

/// Arms a one-shot timer while the whole circle is inside the destination.
///
/// Rebuilt on every fix, so it cannot simply count down from the first
/// everyone-here reading: any false reading cancels the timer, and the next
/// true one starts the grace period again.
class TripAutoEnd {
  TripAutoEnd({required this.onFinish, this.grace = arrivalAutoEndGrace});

  /// Clears the trip. Returns false when the clear failed, so the next fix can
  /// try again instead of leaving the circle stuck in a finished trip.
  final Future<bool> Function(String tripKey) onFinish;
  final Duration grace;

  Timer? _timer;
  String? _armedTrip;

  void update({required String? tripKey, required bool everyoneArrived}) {
    if (tripKey == null || !everyoneArrived) {
      cancel();
      return;
    }
    if (_armedTrip == tripKey) return;

    _timer?.cancel();
    _armedTrip = tripKey;
    _timer = Timer(grace, () {
      _timer = null;
      unawaited(_finish(tripKey));
    });
  }

  Future<void> _finish(String tripKey) async {
    final finished = await onFinish(tripKey);
    if (!finished && _armedTrip == tripKey) {
      _armedTrip = null;
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _armedTrip = null;
  }
}
