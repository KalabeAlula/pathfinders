import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_visibility.g.dart';

/// Whether the app is on screen.
///
/// Features that have both an in-app cue and a system notification use this
/// to avoid showing the two at once: the banner is for the foreground, the
/// notification for the background.
class AppVisibility extends ChangeNotifier {
  bool _isForeground = true;

  bool get isForeground => _isForeground;

  void update(AppLifecycleState state) {
    final isForeground =
        state != AppLifecycleState.paused &&
        state != AppLifecycleState.hidden &&
        state != AppLifecycleState.detached;
    if (isForeground == _isForeground) return;
    _isForeground = isForeground;
    notifyListeners();
  }
}

@Riverpod(keepAlive: true)
AppVisibility appVisibility(Ref ref) {
  final visibility = AppVisibility();
  ref.onDispose(visibility.dispose);
  return visibility;
}
