import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/navigation/active_tab.dart';

void main() {
  test('exposes the five destinations in circle-to-profile order', () {
    expect(AppTab.values, const [
      AppTab.circle,
      AppTab.chat,
      AppTab.map,
      AppTab.memories,
      AppTab.profile,
    ]);
    expect(AppTab.map.index, 2);
    expect(AppTab.profile.index, 4);
  });

  test('defaults to the map and remembers explicit selections', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(activeTabControllerProvider), AppTab.map);

    final controller = container.read(activeTabControllerProvider.notifier);
    controller.select(AppTab.memories);
    expect(container.read(activeTabControllerProvider), AppTab.memories);

    controller.select(AppTab.chat);
    expect(container.read(activeTabControllerProvider), AppTab.chat);

    controller.select(AppTab.circle);
    expect(container.read(activeTabControllerProvider), AppTab.circle);

    controller.select(AppTab.profile);
    expect(container.read(activeTabControllerProvider), AppTab.profile);
  });

  test('reselecting the active tab keeps the same state instance', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(activeTabControllerProvider.notifier);
    controller.select(AppTab.chat);
    final selected = container.read(activeTabControllerProvider);

    controller.select(AppTab.chat);
    expect(container.read(activeTabControllerProvider), same(selected));
  });
}
