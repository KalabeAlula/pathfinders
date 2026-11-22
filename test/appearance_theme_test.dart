import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/theme/app_palettes.dart';
import 'package:pathfinders/app/theme/theme_providers.dart';
import 'package:pathfinders/core/storage/storage_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPalettes', () {
    test('lists every identity once, with matching ids', () {
      expect(
        AppPalettes.all.map((palette) => palette.id).toList(),
        AppThemeId.values,
      );
      for (final id in AppThemeId.values) {
        expect(AppPalettes.byId(id).id, id);
      }
    });

    test('keeps each pair in the right brightness with distinct roles', () {
      for (final palette in AppPalettes.all) {
        expect(palette.light.brightness, Brightness.light);
        expect(palette.dark.brightness, Brightness.dark);
        expect(palette.backdrop, isNot(palette.support));
        expect(palette.backdrop, isNot(palette.accent));
        expect(palette.support, isNot(palette.accent));
      }
    });

    test('defaults to the existing sandstone palette', () {
      expect(AppPalettes.defaultId, AppThemeId.sandstone);
    });
  });

  group('AppThemeController', () {
    test('starts on the default and restores a saved choice', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      final first = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(first.dispose);
      expect(first.read(appThemeProvider), AppThemeId.sandstone);

      await first.read(appThemeProvider.notifier).select(AppThemeId.ember);
      expect(first.read(appThemeProvider), AppThemeId.ember);
      expect(preferences.getString(themePreferenceKey), 'ember');

      final second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(second.dispose);
      expect(second.read(appThemeProvider), AppThemeId.ember);
    });

    test('ignores a stored value that is not a known theme', () async {
      SharedPreferences.setMockInitialValues({
        themePreferenceKey: 'not-a-theme',
      });
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      expect(container.read(appThemeProvider), AppPalettes.defaultId);
    });
  });
}
