import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_tab.g.dart';

/// The five persistent destinations of the main shell, in bar order.
enum AppTab { circle, chat, map, memories, profile }

/// Remembers the selected destination so it survives rebuilds triggered by
/// circle data, nudges, or telemetry.
@Riverpod(keepAlive: true)
class ActiveTabController extends _$ActiveTabController {
  @override
  AppTab build() => AppTab.map;

  void select(AppTab tab) {
    if (state != tab) state = tab;
  }
}
