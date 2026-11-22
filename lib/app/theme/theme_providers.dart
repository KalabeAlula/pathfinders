import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import 'app_palettes.dart';

const themePreferenceKey = 'appearance.theme';

/// The palette the whole app renders with, restored synchronously from the
/// last choice so the first frame already uses it.
final appThemeProvider = NotifierProvider<AppThemeController, AppThemeId>(
  AppThemeController.new,
);

class AppThemeController extends Notifier<AppThemeId> {
  @override
  AppThemeId build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getString(themePreferenceKey);
    return AppThemeId.values.firstWhere(
      (id) => id.name == stored,
      orElse: () => AppPalettes.defaultId,
    );
  }

  Future<void> select(AppThemeId id) async {
    if (state == id) return;
    state = id;
    await ref
        .read(sharedPreferencesProvider)
        .setString(themePreferenceKey, id.name);
  }
}
