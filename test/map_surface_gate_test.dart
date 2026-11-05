import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/navigation/presentation/map_tab.dart';

void main() {
  test('mounts the native map only while the map tab is on screen', () {
    expect(
      shouldMountNativeMap(
        tabActive: true,
        foreground: true,
        configured: true,
      ),
      isTrue,
    );
  });

  test('detaches the native map on every other tab', () {
    expect(
      shouldMountNativeMap(
        tabActive: false,
        foreground: true,
        configured: true,
      ),
      isFalse,
    );
  });

  test('detaches the native map while the app is backgrounded', () {
    expect(
      shouldMountNativeMap(
        tabActive: true,
        foreground: false,
        configured: true,
      ),
      isFalse,
    );
  });

  test('does not mount a map without a Mapbox token', () {
    expect(
      shouldMountNativeMap(
        tabActive: true,
        foreground: true,
        configured: false,
      ),
      isFalse,
    );
  });
}
