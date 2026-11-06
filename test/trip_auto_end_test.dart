import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/navigation/application/trip_auto_end.dart';

void main() {
  const grace = Duration(seconds: 10);

  TripAutoEnd autoEndFor(List<String> finished, {bool succeeds = true}) {
    return TripAutoEnd(
      grace: grace,
      onFinish: (tripKey) async {
        finished.add(tripKey);
        return succeeds;
      },
    );
  }

  test('finishes only after the whole circle has stayed for the grace', () {
    fakeAsync((async) {
      final finished = <String>[];
      final autoEnd = autoEndFor(finished);

      autoEnd.update(tripKey: 't1', everyoneArrived: true);
      async.elapse(const Duration(seconds: 9));
      expect(finished, isEmpty);

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(finished, ['t1']);
    });
  });

  test('starts the grace again when someone steps out of the radius', () {
    fakeAsync((async) {
      final finished = <String>[];
      final autoEnd = autoEndFor(finished);

      autoEnd.update(tripKey: 't1', everyoneArrived: true);
      async.elapse(const Duration(seconds: 6));
      autoEnd.update(tripKey: 't1', everyoneArrived: false);
      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();
      expect(finished, isEmpty);

      autoEnd.update(tripKey: 't1', everyoneArrived: true);
      async.elapse(const Duration(seconds: 9));
      expect(finished, isEmpty);
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(finished, ['t1']);
    });
  });

  test('fires once per trip while fixes keep rebuilding', () {
    fakeAsync((async) {
      final finished = <String>[];
      final autoEnd = autoEndFor(finished);

      for (var tick = 0; tick < 25; tick++) {
        autoEnd.update(tripKey: 't1', everyoneArrived: true);
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
      }

      expect(finished, ['t1']);
    });
  });

  test('arms again for a new trip', () {
    fakeAsync((async) {
      final finished = <String>[];
      final autoEnd = autoEndFor(finished);

      autoEnd.update(tripKey: 't1', everyoneArrived: true);
      async.elapse(grace);
      async.flushMicrotasks();

      autoEnd.update(tripKey: 't2', everyoneArrived: true);
      async.elapse(grace);
      async.flushMicrotasks();

      expect(finished, ['t1', 't2']);
    });
  });

  test('retries on the next fix when the clear failed', () {
    fakeAsync((async) {
      var attempts = 0;
      var succeed = false;
      final autoEnd = TripAutoEnd(
        grace: grace,
        onFinish: (_) async {
          attempts++;
          return succeed;
        },
      );

      autoEnd.update(tripKey: 't1', everyoneArrived: true);
      async.elapse(grace);
      async.flushMicrotasks();
      expect(attempts, 1);

      autoEnd.update(tripKey: 't1', everyoneArrived: true);
      async.elapse(grace);
      async.flushMicrotasks();
      expect(attempts, 2);

      succeed = true;
      autoEnd.update(tripKey: 't1', everyoneArrived: true);
      async.elapse(grace);
      async.flushMicrotasks();
      expect(attempts, 3);

      autoEnd.update(tripKey: 't1', everyoneArrived: true);
      async.elapse(grace);
      async.flushMicrotasks();
      expect(attempts, 3);
    });
  });

  test('stays idle without a trip or without everyone there', () {
    fakeAsync((async) {
      final finished = <String>[];
      final autoEnd = autoEndFor(finished);

      autoEnd.update(tripKey: null, everyoneArrived: true);
      autoEnd.update(tripKey: 't1', everyoneArrived: false);
      async.elapse(const Duration(minutes: 1));
      async.flushMicrotasks();

      expect(finished, isEmpty);
    });
  });
}
