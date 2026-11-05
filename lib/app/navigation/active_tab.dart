import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_tab.g.dart';

/// The four persistent destinations of the main shell.
enum AppTab { map, chat, memories, circle }

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
