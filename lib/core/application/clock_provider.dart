import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// Ticks so relative copy ("4m ago", dwell time) stays honest on a screen that
/// otherwise only rebuilds when data changes.
@Riverpod(keepAlive: true)
Stream<DateTime> appClock(Ref ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 20), (_) => DateTime.now());
}
