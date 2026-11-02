import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/location/domain/geo_point.dart';
import 'package:pathfinders/features/navigation/domain/arrival.dart';
import 'package:pathfinders/features/navigation/domain/navigation_destination.dart';

const _target = GeoPoint(latitude: 9.0, longitude: 38.75);

GeoPoint _north(double degrees) => GeoPoint(
  latitude: _target.latitude + degrees,
  longitude: _target.longitude,
);

NavigationDestination _destination({DateTime? updatedAt}) {
  return NavigationDestination(
    latitude: _target.latitude,
    longitude: _target.longitude,
    label: 'Blue Nile Cinema',
    setBy: 'me',
    updatedAt: updatedAt ?? DateTime.utc(2026, 11, 2, 9),
  );
}

void main() {
  group('arrival radius', () {
    test('accepts a fix inside forty metres', () {
      expect(isWithinArrivalRadius(_north(0.0002), _target), isTrue);
    });

    test('rejects a fix beyond forty metres', () {
      expect(isWithinArrivalRadius(_north(0.0005), _target), isFalse);
    });

    test('ignores a fix whose accuracy is too vague', () {
      expect(
        isWithinArrivalRadius(
          _north(0.0002),
          _target,
          accuracyMeters: arrivalAccuracyCeilingMeters + 1,
        ),
        isFalse,
      );
      expect(
        isWithinArrivalRadius(
          _north(0.0002),
          _target,
          accuracyMeters: arrivalAccuracyCeilingMeters,
        ),
        isTrue,
      );
    });
  });

  group('allMembersWithinArrivalRadius', () {
    test('is true only when every member has an arriving fix', () {
      expect(
        allMembersWithinArrivalRadius([
          _north(0.0001),
          _north(0.0002),
        ], _target),
        isTrue,
      );
      expect(
        allMembersWithinArrivalRadius([
          _north(0.0001),
          _north(0.0005),
        ], _target),
        isFalse,
      );
    });

    test('is false when a member has no fix or the circle is empty', () {
      expect(
        allMembersWithinArrivalRadius([_north(0.0001), null], _target),
        isFalse,
      );
      expect(allMembersWithinArrivalRadius(const [], _target), isFalse);
    });
  });

  group('destinationTripKey', () {
    test('is stable for the same trip', () {
      final destination = _destination();

      expect(
        destinationTripKey(destination),
        destinationTripKey(_destination(updatedAt: destination.updatedAt)),
      );
    });

    test('changes when the destination is set again', () {
      final first = _destination();
      final second = _destination(
        updatedAt: first.updatedAt.add(const Duration(minutes: 5)),
      );

      expect(destinationTripKey(first), isNot(destinationTripKey(second)));
    });
  });
}
