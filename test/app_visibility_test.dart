import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/core/application/app_visibility.dart';

void main() {
  test('the app starts in the foreground', () {
    expect(AppVisibility().isForeground, isTrue);
  });

  test('paused, hidden, and detached count as background', () {
    final visibility = AppVisibility();

    for (final state in [
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.detached,
    ]) {
      visibility.update(AppLifecycleState.resumed);
      visibility.update(state);
      expect(visibility.isForeground, isFalse, reason: '$state');
    }
  });

  test('inactive stays foreground so system overlays do not notify', () {
    final visibility = AppVisibility();

    visibility.update(AppLifecycleState.inactive);

    expect(visibility.isForeground, isTrue);
  });

  test('listeners only hear real transitions', () {
    final visibility = AppVisibility();
    var changes = 0;
    visibility.addListener(() => changes++);

    visibility.update(AppLifecycleState.resumed);
    expect(changes, 0);

    visibility.update(AppLifecycleState.paused);
    visibility.update(AppLifecycleState.paused);
    expect(changes, 1);

    visibility.update(AppLifecycleState.resumed);
    expect(changes, 2);
  });
}
