import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colour identities the member can switch between.
enum AppThemeId { sandstone, highland, bale, ember, rift, juniper, dusk, kaffa }

extension AppThemeIdInfo on AppThemeId {
  String get label => switch (this) {
    AppThemeId.sandstone => 'Sandstone',
    AppThemeId.highland => 'Highland',
    AppThemeId.bale => 'Bale',
    AppThemeId.ember => 'Ember',
    AppThemeId.rift => 'Rift',
    AppThemeId.juniper => 'Juniper',
    AppThemeId.dusk => 'Dusk',
    AppThemeId.kaffa => 'Kaffa',
  };

  String get tagline => switch (this) {
    AppThemeId.sandstone => 'Warm clay and sage',
    AppThemeId.highland => 'Moss and amber',
    AppThemeId.bale => 'Lake teal and coral',
    AppThemeId.ember => 'Blush and berry',
    AppThemeId.rift => 'Mist and indigo',
    AppThemeId.juniper => 'Linen and pine',
    AppThemeId.dusk => 'Pearl and plum',
    AppThemeId.kaffa => 'Cream and espresso',
  };
}

/// One colour identity expressed as a Material scheme pair.
///
/// Every palette follows the 60-30-10 balance: the surface family carries
/// about 60% of a screen, the surface containers and secondary family about
/// 30%, and the primary family the remaining 10% of interactive accent.
class AppPalette {
  const AppPalette({required this.id, required this.light, required this.dark});

  final AppThemeId id;
  final ColorScheme light;
  final ColorScheme dark;

  /// The three bands the profile swatch shows, always in their light form so
  /// the identity reads the same whichever mode is active.
  Color get backdrop => light.surface;
  Color get support => light.secondary;
  Color get accent => light.primary;
}

abstract final class AppPalettes {
  static const defaultId = AppThemeId.sandstone;

  static final sandstone = AppPalette(
    id: AppThemeId.sandstone,
    light: AppColors.lightScheme,
    dark: AppColors.darkScheme,
  );

  static final highland = AppPalette(
    id: AppThemeId.highland,
    light: _highlandLight,
    dark: _highlandDark,
  );

  static final bale = AppPalette(
    id: AppThemeId.bale,
    light: _baleLight,
    dark: _baleDark,
  );

  static final ember = AppPalette(
    id: AppThemeId.ember,
    light: _emberLight,
    dark: _emberDark,
  );

  static final rift = AppPalette(
    id: AppThemeId.rift,
    light: _riftLight,
    dark: _riftDark,
  );

  static final juniper = AppPalette(
    id: AppThemeId.juniper,
    light: _juniperLight,
    dark: _juniperDark,
  );

  static final dusk = AppPalette(
    id: AppThemeId.dusk,
    light: _duskLight,
    dark: _duskDark,
  );

  static final kaffa = AppPalette(
    id: AppThemeId.kaffa,
    light: _kaffaLight,
    dark: _kaffaDark,
  );

  static final all = <AppPalette>[
    sandstone,
    highland,
    bale,
    ember,
    rift,
    juniper,
    dusk,
    kaffa,
  ];

  static AppPalette byId(AppThemeId id) => switch (id) {
    AppThemeId.sandstone => sandstone,
    AppThemeId.highland => highland,
    AppThemeId.bale => bale,
    AppThemeId.ember => ember,
    AppThemeId.rift => rift,
    AppThemeId.juniper => juniper,
    AppThemeId.dusk => dusk,
    AppThemeId.kaffa => kaffa,
  };

  // Highland — moss backdrop, sage support, ochre accent.
  static final _highlandLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF9A6428),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF9A6428),
        onPrimary: const Color(0xFFFFF8EE),
        primaryContainer: const Color(0xFFF4E2C6),
        onPrimaryContainer: const Color(0xFF46290A),
        secondary: const Color(0xFF6C7F5B),
        onSecondary: const Color(0xFFFBFDF6),
        secondaryContainer: const Color(0xFFE1E9D5),
        onSecondaryContainer: const Color(0xFF2C3A22),
        tertiary: const Color(0xFF4F7F86),
        onTertiary: const Color(0xFFF2FBFB),
        tertiaryContainer: const Color(0xFFD6EAEA),
        onTertiaryContainer: const Color(0xFF163438),
        surface: const Color(0xFFF3F4EE),
        onSurface: const Color(0xFF20241B),
        onSurfaceVariant: const Color(0xFF66695C),
        surfaceContainerLowest: const Color(0xFFFDFDF9),
        surfaceContainerLow: const Color(0xFFF8F9F3),
        surfaceContainer: const Color(0xFFEFF1E8),
        surfaceContainerHigh: const Color(0xFFE8EBE0),
        surfaceContainerHighest: const Color(0xFFE0E4D7),
        outline: const Color(0xFFABB09E),
        outlineVariant: const Color(0xFFDCE0D2),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF2C2F27),
        onInverseSurface: const Color(0xFFF2F3EB),
      );

  static final _highlandDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF9A6428),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFE6B878),
        onPrimary: const Color(0xFF4A2E0E),
        primaryContainer: const Color(0xFF6B4A1D),
        onPrimaryContainer: const Color(0xFFF4E2C6),
        secondary: const Color(0xFFB9C8A5),
        onSecondary: const Color(0xFF2C3A22),
        secondaryContainer: const Color(0xFF47543A),
        onSecondaryContainer: const Color(0xFFE1E9D5),
        tertiary: const Color(0xFF9FC9CB),
        onTertiary: const Color(0xFF103336),
        tertiaryContainer: const Color(0xFF35575A),
        onTertiaryContainer: const Color(0xFFD6EAEA),
        surface: const Color(0xFF141711),
        onSurface: const Color(0xFFE9EBDD),
        onSurfaceVariant: const Color(0xFFBFC3B1),
        surfaceContainerLowest: const Color(0xFF0F120D),
        surfaceContainerLow: const Color(0xFF1B1F18),
        surfaceContainer: const Color(0xFF22261E),
        surfaceContainerHigh: const Color(0xFF2A2F26),
        surfaceContainerHighest: const Color(0xFF333A2E),
        outline: const Color(0xFF6F7562),
        outlineVariant: const Color(0xFF3A4034),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFE9EBDD),
        onInverseSurface: const Color(0xFF2C2F27),
      );

  // Bale — sea-mist backdrop, deep teal support, coral accent.
  static final _baleLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFC35E44),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFFC35E44),
        onPrimary: const Color(0xFFFFF6F2),
        primaryContainer: const Color(0xFFF7DCCF),
        onPrimaryContainer: const Color(0xFF4B1E12),
        secondary: const Color(0xFF3E6F74),
        onSecondary: const Color(0xFFF2FBFA),
        secondaryContainer: const Color(0xFFCFE4E2),
        onSecondaryContainer: const Color(0xFF153236),
        tertiary: const Color(0xFF8A6A3A),
        onTertiary: const Color(0xFFFFF8EC),
        tertiaryContainer: const Color(0xFFEEDFC4),
        onTertiaryContainer: const Color(0xFF422F0E),
        surface: const Color(0xFFEFF5F4),
        onSurface: const Color(0xFF1C2829),
        onSurfaceVariant: const Color(0xFF5D6D6D),
        surfaceContainerLowest: const Color(0xFFFAFDFC),
        surfaceContainerLow: const Color(0xFFF4F9F8),
        surfaceContainer: const Color(0xFFE9F1F0),
        surfaceContainerHigh: const Color(0xFFE1EBEA),
        surfaceContainerHighest: const Color(0xFFD8E4E3),
        outline: const Color(0xFF9FB0B0),
        outlineVariant: const Color(0xFFD5E0DF),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF26312F),
        onInverseSurface: const Color(0xFFF1F7F6),
      );

  static final _baleDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFC35E44),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFEFAE97),
        onPrimary: const Color(0xFF522014),
        primaryContainer: const Color(0xFF6B3424),
        onPrimaryContainer: const Color(0xFFF7DCCF),
        secondary: const Color(0xFF9CC6C4),
        onSecondary: const Color(0xFF123436),
        secondaryContainer: const Color(0xFF2F5154),
        onSecondaryContainer: const Color(0xFFCFE4E2),
        tertiary: const Color(0xFFDCC08A),
        onTertiary: const Color(0xFF412F0E),
        tertiaryContainer: const Color(0xFF5E4820),
        onTertiaryContainer: const Color(0xFFEEDFC4),
        surface: const Color(0xFF101718),
        onSurface: const Color(0xFFE4ECEB),
        onSurfaceVariant: const Color(0xFFB2C0BF),
        surfaceContainerLowest: const Color(0xFF0B1112),
        surfaceContainerLow: const Color(0xFF161D1E),
        surfaceContainer: const Color(0xFF1D2627),
        surfaceContainerHigh: const Color(0xFF252F30),
        surfaceContainerHighest: const Color(0xFF2E3A3B),
        outline: const Color(0xFF687978),
        outlineVariant: const Color(0xFF313D3E),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFE4ECEB),
        onInverseSurface: const Color(0xFF26312F),
      );

  // Ember — blush backdrop, sage support, berry accent.
  static final _emberLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF8C4A56),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF8C4A56),
        onPrimary: const Color(0xFFFFF5F5),
        primaryContainer: const Color(0xFFF3D9DC),
        onPrimaryContainer: const Color(0xFF451B24),
        secondary: const Color(0xFF62795A),
        onSecondary: const Color(0xFFFBFDF7),
        secondaryContainer: const Color(0xFFDDE7D5),
        onSecondaryContainer: const Color(0xFF26331F),
        tertiary: const Color(0xFFA97B3E),
        onTertiary: const Color(0xFFFFF8EC),
        tertiaryContainer: const Color(0xFFF1E0C2),
        onTertiaryContainer: const Color(0xFF3E2C0C),
        surface: const Color(0xFFFAF0E9),
        onSurface: const Color(0xFF2B211D),
        onSurfaceVariant: const Color(0xFF6E5D55),
        surfaceContainerLowest: const Color(0xFFFFFBF7),
        surfaceContainerLow: const Color(0xFFFDF5EF),
        surfaceContainer: const Color(0xFFF6E9DF),
        surfaceContainerHigh: const Color(0xFFF1E1D5),
        surfaceContainerHighest: const Color(0xFFEBD9CB),
        outline: const Color(0xFFB5A091),
        outlineVariant: const Color(0xFFE5D4C7),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF332824),
        onInverseSurface: const Color(0xFFF9EEE7),
      );

  static final _emberDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF8C4A56),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFE9A9B4),
        onPrimary: const Color(0xFF4B2029),
        primaryContainer: const Color(0xFF63323C),
        onPrimaryContainer: const Color(0xFFF3D9DC),
        secondary: const Color(0xFFAEC0A1),
        onSecondary: const Color(0xFF26331F),
        secondaryContainer: const Color(0xFF3F4E37),
        onSecondaryContainer: const Color(0xFFDDE7D5),
        tertiary: const Color(0xFFDDBB7E),
        onTertiary: const Color(0xFF3C2A0C),
        tertiaryContainer: const Color(0xFF58431C),
        onTertiaryContainer: const Color(0xFFF1E0C2),
        surface: const Color(0xFF171210),
        onSurface: const Color(0xFFEFE2DA),
        onSurfaceVariant: const Color(0xFFC9B6AB),
        surfaceContainerLowest: const Color(0xFF110D0B),
        surfaceContainerLow: const Color(0xFF1E1714),
        surfaceContainer: const Color(0xFF251D19),
        surfaceContainerHigh: const Color(0xFF2D241F),
        surfaceContainerHighest: const Color(0xFF372C26),
        outline: const Color(0xFF76655C),
        outlineVariant: const Color(0xFF3F332D),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFEFE2DA),
        onInverseSurface: const Color(0xFF332824),
      );

  // Rift — cool mist backdrop, slate support, indigo accent.
  static final _riftLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF3D548E),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF3D548E),
        onPrimary: const Color(0xFFF7F9FF),
        primaryContainer: const Color(0xFFDCE4F8),
        onPrimaryContainer: const Color(0xFF16254A),
        secondary: const Color(0xFF55697E),
        onSecondary: const Color(0xFFF6F9FC),
        secondaryContainer: const Color(0xFFD9E3ED),
        onSecondaryContainer: const Color(0xFF1E2D3C),
        tertiary: const Color(0xFF8C6B43),
        onTertiary: const Color(0xFFFFF8F0),
        tertiaryContainer: const Color(0xFFF1E2CE),
        onTertiaryContainer: const Color(0xFF3E2B14),
        surface: const Color(0xFFEFF2F7),
        onSurface: const Color(0xFF1A2029),
        onSurfaceVariant: const Color(0xFF555F6E),
        surfaceContainerLowest: const Color(0xFFFAFBFD),
        surfaceContainerLow: const Color(0xFFF4F6FA),
        surfaceContainer: const Color(0xFFE9EDF4),
        surfaceContainerHigh: const Color(0xFFE2E7F0),
        surfaceContainerHighest: const Color(0xFFDCE2EC),
        outline: const Color(0xFF9EA9BA),
        outlineVariant: const Color(0xFFD4DBE6),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF262C36),
        onInverseSurface: const Color(0xFFF1F4F9),
      );

  static final _riftDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF3D548E),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFA5B9EE),
        onPrimary: const Color(0xFF142349),
        primaryContainer: const Color(0xFF2B3B64),
        onPrimaryContainer: const Color(0xFFDCE4F8),
        secondary: const Color(0xFFA3B7CC),
        onSecondary: const Color(0xFF1B2A38),
        secondaryContainer: const Color(0xFF36485A),
        onSecondaryContainer: const Color(0xFFD9E3ED),
        tertiary: const Color(0xFFD8B88E),
        onTertiary: const Color(0xFF3E2B14),
        tertiaryContainer: const Color(0xFF5A4326),
        onTertiaryContainer: const Color(0xFFF1E2CE),
        surface: const Color(0xFF10141B),
        onSurface: const Color(0xFFE3E7F0),
        onSurfaceVariant: const Color(0xFFB6C0CF),
        surfaceContainerLowest: const Color(0xFF0B0E13),
        surfaceContainerLow: const Color(0xFF161B24),
        surfaceContainer: const Color(0xFF1C222D),
        surfaceContainerHigh: const Color(0xFF242B37),
        surfaceContainerHighest: const Color(0xFF2C333F),
        outline: const Color(0xFF687385),
        outlineVariant: const Color(0xFF313947),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFE3E7F0),
        onInverseSurface: const Color(0xFF262C36),
      );

  // Juniper — linen backdrop, driftwood support, pine accent.
  static final _juniperLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF2F664C),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF2F664C),
        onPrimary: const Color(0xFFF4FBF7),
        primaryContainer: const Color(0xFFD3EAD8),
        onPrimaryContainer: const Color(0xFF0F3322),
        secondary: const Color(0xFF786B5D),
        onSecondary: const Color(0xFFFDFBF8),
        secondaryContainer: const Color(0xFFE8DFD5),
        onSecondaryContainer: const Color(0xFF332B22),
        tertiary: const Color(0xFF9E5B45),
        onTertiary: const Color(0xFFFFF7F4),
        tertiaryContainer: const Color(0xFFF5DDD4),
        onTertiaryContainer: const Color(0xFF451E12),
        surface: const Color(0xFFF3F3EE),
        onSurface: const Color(0xFF1F221D),
        onSurfaceVariant: const Color(0xFF5A5C52),
        surfaceContainerLowest: const Color(0xFFFCFCF9),
        surfaceContainerLow: const Color(0xFFF7F7F2),
        surfaceContainer: const Color(0xFFEDEDE7),
        surfaceContainerHigh: const Color(0xFFE6E6DF),
        surfaceContainerHighest: const Color(0xFFDFDFD6),
        outline: const Color(0xFFA9ABA0),
        outlineVariant: const Color(0xFFDADBD2),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF2B2E29),
        onInverseSurface: const Color(0xFFF2F2ED),
      );

  static final _juniperDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF2F664C),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF8FD0AF),
        onPrimary: const Color(0xFF0D3423),
        primaryContainer: const Color(0xFF224F3A),
        onPrimaryContainer: const Color(0xFFD3EAD8),
        secondary: const Color(0xFFC4B6A6),
        onSecondary: const Color(0xFF332B22),
        secondaryContainer: const Color(0xFF4E4337),
        onSecondaryContainer: const Color(0xFFE8DFD5),
        tertiary: const Color(0xFFE2A28D),
        onTertiary: const Color(0xFF441D11),
        tertiaryContainer: const Color(0xFF633223),
        onTertiaryContainer: const Color(0xFFF5DDD4),
        surface: const Color(0xFF121512),
        onSurface: const Color(0xFFE6EAE4),
        onSurfaceVariant: const Color(0xFFB9BEB6),
        surfaceContainerLowest: const Color(0xFF0D100D),
        surfaceContainerLow: const Color(0xFF181C18),
        surfaceContainer: const Color(0xFF1F241F),
        surfaceContainerHigh: const Color(0xFF262C26),
        surfaceContainerHighest: const Color(0xFF2E342D),
        outline: const Color(0xFF6C7269),
        outlineVariant: const Color(0xFF353B34),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFE6EAE4),
        onInverseSurface: const Color(0xFF2B2E29),
      );

  // Dusk — pearl backdrop, dusty slate support, plum accent.
  static final _duskLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF6E4878),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF6E4878),
        onPrimary: const Color(0xFFFCF7FE),
        primaryContainer: const Color(0xFFEEDBF3),
        onPrimaryContainer: const Color(0xFF35193D),
        secondary: const Color(0xFF5B6878),
        onSecondary: const Color(0xFFF7F9FC),
        secondaryContainer: const Color(0xFFDCE3EC),
        onSecondaryContainer: const Color(0xFF1F2B38),
        tertiary: const Color(0xFF547864),
        onTertiary: const Color(0xFFF4FBF7),
        tertiaryContainer: const Color(0xFFD6E9DD),
        onTertiaryContainer: const Color(0xFF193325),
        surface: const Color(0xFFF4F1F6),
        onSurface: const Color(0xFF221E26),
        onSurfaceVariant: const Color(0xFF5E5766),
        surfaceContainerLowest: const Color(0xFFFDFBFE),
        surfaceContainerLow: const Color(0xFFF8F5FA),
        surfaceContainer: const Color(0xFFEEEAF1),
        surfaceContainerHigh: const Color(0xFFE8E3EC),
        surfaceContainerHighest: const Color(0xFFE2DCE7),
        outline: const Color(0xFFADA4B5),
        outlineVariant: const Color(0xFFDCD5E2),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF2E2933),
        onInverseSurface: const Color(0xFFF4F0F7),
      );

  static final _duskDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF6E4878),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFD6AEE0),
        onPrimary: const Color(0xFF3A1B43),
        primaryContainer: const Color(0xFF52325C),
        onPrimaryContainer: const Color(0xFFEEDBF3),
        secondary: const Color(0xFFABB7C7),
        onSecondary: const Color(0xFF1F2B38),
        secondaryContainer: const Color(0xFF3A4654),
        onSecondaryContainer: const Color(0xFFDCE3EC),
        tertiary: const Color(0xFFA3C8B2),
        onTertiary: const Color(0xFF173324),
        tertiaryContainer: const Color(0xFF32513F),
        onTertiaryContainer: const Color(0xFFD6E9DD),
        surface: const Color(0xFF151218),
        onSurface: const Color(0xFFEAE4EF),
        onSurfaceVariant: const Color(0xFFC2BAC9),
        surfaceContainerLowest: const Color(0xFF100D12),
        surfaceContainerLow: const Color(0xFF1C1820),
        surfaceContainer: const Color(0xFF231E28),
        surfaceContainerHigh: const Color(0xFF2B2530),
        surfaceContainerHighest: const Color(0xFF322C38),
        outline: const Color(0xFF72697A),
        outlineVariant: const Color(0xFF3B3442),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFEAE4EF),
        onInverseSurface: const Color(0xFF2E2933),
      );

  // Kaffa — cream backdrop, olive-taupe support, espresso accent.
  static final _kaffaLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B422E),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF6B422E),
        onPrimary: const Color(0xFFFFF8F4),
        primaryContainer: const Color(0xFFF2DFD4),
        onPrimaryContainer: const Color(0xFF3B1F11),
        secondary: const Color(0xFF6C6E54),
        onSecondary: const Color(0xFFFBFBF5),
        secondaryContainer: const Color(0xFFE3E4D2),
        onSecondaryContainer: const Color(0xFF2D2F1D),
        tertiary: const Color(0xFF9A6D27),
        onTertiary: const Color(0xFFFFF9EE),
        tertiaryContainer: const Color(0xFFF4E4C4),
        onTertiaryContainer: const Color(0xFF412A08),
        surface: const Color(0xFFF6F2EA),
        onSurface: const Color(0xFF26201A),
        onSurfaceVariant: const Color(0xFF63594D),
        surfaceContainerLowest: const Color(0xFFFFFDF9),
        surfaceContainerLow: const Color(0xFFFAF7F0),
        surfaceContainer: const Color(0xFFF0EBE1),
        surfaceContainerHigh: const Color(0xFFEAE4D8),
        surfaceContainerHighest: const Color(0xFFE5DDD0),
        outline: const Color(0xFFB2A799),
        outlineVariant: const Color(0xFFE0D7CA),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF322B24),
        onInverseSurface: const Color(0xFFF6F1E9),
      );

  static final _kaffaDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B422E),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFDFB098),
        onPrimary: const Color(0xFF3F2113),
        primaryContainer: const Color(0xFF5B3522),
        onPrimaryContainer: const Color(0xFFF2DFD4),
        secondary: const Color(0xFFB9BB9E),
        onSecondary: const Color(0xFF2D2F1D),
        secondaryContainer: const Color(0xFF474934),
        onSecondaryContainer: const Color(0xFFE3E4D2),
        tertiary: const Color(0xFFDFB874),
        onTertiary: const Color(0xFF3F2907),
        tertiaryContainer: const Color(0xFF5C4217),
        onTertiaryContainer: const Color(0xFFF4E4C4),
        surface: const Color(0xFF161310),
        onSurface: const Color(0xFFEDE6DC),
        onSurfaceVariant: const Color(0xFFC6BCB0),
        surfaceContainerLowest: const Color(0xFF100E0C),
        surfaceContainerLow: const Color(0xFF1D1915),
        surfaceContainer: const Color(0xFF241F1B),
        surfaceContainerHigh: const Color(0xFF2C2621),
        surfaceContainerHighest: const Color(0xFF352E27),
        outline: const Color(0xFF746B60),
        outlineVariant: const Color(0xFF3E372F),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFEDE6DC),
        onInverseSurface: const Color(0xFF322B24),
      );
}
