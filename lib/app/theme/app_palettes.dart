import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colour identities the member can switch between.
enum AppThemeId {
  sandstone,
  highland,
  bale,
  ember,
  rift,
  juniper,
  dusk,
  kaffa,
  solstice,
  nordic,
  oatmeal,
  obsidian,
  mint,
  midnight,
  swiss,
  harbor,
}

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
    AppThemeId.solstice => 'Solstice',
    AppThemeId.nordic => 'Nordic',
    AppThemeId.oatmeal => 'Oatmeal',
    AppThemeId.obsidian => 'Obsidian',
    AppThemeId.mint => 'Mint',
    AppThemeId.midnight => 'Midnight',
    AppThemeId.swiss => 'Swiss',
    AppThemeId.harbor => 'Harbor',
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
    AppThemeId.solstice => 'Alabaster and gold',
    AppThemeId.nordic => 'Ice and cobalt',
    AppThemeId.oatmeal => 'Sage and terracotta',
    AppThemeId.obsidian => 'Graphite and champagne',
    AppThemeId.mint => 'Pine and coral',
    AppThemeId.midnight => 'Indigo and lavender',
    AppThemeId.swiss => 'Charcoal and vermilion',
    AppThemeId.harbor => 'Navy and teal',
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

  static final solstice = AppPalette(
    id: AppThemeId.solstice,
    light: _solsticeLight,
    dark: _solsticeDark,
  );

  static final nordic = AppPalette(
    id: AppThemeId.nordic,
    light: _nordicLight,
    dark: _nordicDark,
  );

  static final oatmeal = AppPalette(
    id: AppThemeId.oatmeal,
    light: _oatmealLight,
    dark: _oatmealDark,
  );

  static final obsidian = AppPalette(
    id: AppThemeId.obsidian,
    light: _obsidianLight,
    dark: _obsidianDark,
  );

  static final mint = AppPalette(
    id: AppThemeId.mint,
    light: _mintLight,
    dark: _mintDark,
  );

  static final midnight = AppPalette(
    id: AppThemeId.midnight,
    light: _midnightLight,
    dark: _midnightDark,
  );

  static final swiss = AppPalette(
    id: AppThemeId.swiss,
    light: _swissLight,
    dark: _swissDark,
  );

  static final harbor = AppPalette(
    id: AppThemeId.harbor,
    light: _harborLight,
    dark: _harborDark,
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
    solstice,
    nordic,
    oatmeal,
    obsidian,
    mint,
    midnight,
    swiss,
    harbor,
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
    AppThemeId.solstice => solstice,
    AppThemeId.nordic => nordic,
    AppThemeId.oatmeal => oatmeal,
    AppThemeId.obsidian => obsidian,
    AppThemeId.mint => mint,
    AppThemeId.midnight => midnight,
    AppThemeId.swiss => swiss,
    AppThemeId.harbor => harbor,
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

  // Solstice — alabaster backdrop (60%), slate support (30%), burnished gold accent (10%).
  static final _solsticeLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF936508),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF936508),
        onPrimary: const Color(0xFFFFFDF6),
        primaryContainer: const Color(0xFFF5E5B8),
        onPrimaryContainer: const Color(0xFF3A2600),
        secondary: const Color(0xFF505763),
        onSecondary: const Color(0xFFF8F9FA),
        secondaryContainer: const Color(0xFFDEE1E7),
        onSecondaryContainer: const Color(0xFF20242B),
        tertiary: const Color(0xFF476C6B),
        onTertiary: const Color(0xFFF4FBFB),
        tertiaryContainer: const Color(0xFFD2E5E4),
        onTertiaryContainer: const Color(0xFF132F2F),
        surface: const Color(0xFFF5F3ED),
        onSurface: const Color(0xFF1E1D19),
        onSurfaceVariant: const Color(0xFF5C584F),
        surfaceContainerLowest: const Color(0xFFFDFCF9),
        surfaceContainerLow: const Color(0xFFF9F7F2),
        surfaceContainer: const Color(0xFFEFEDE5),
        surfaceContainerHigh: const Color(0xFFE9E6DC),
        surfaceContainerHighest: const Color(0xFFE3DFD4),
        outline: const Color(0xFFAFA99C),
        outlineVariant: const Color(0xFFDED9CD),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF2C2A24),
        onInverseSurface: const Color(0xFFF5F3ED),
      );

  // Solstice Dark — obsidian backdrop (60%), pewter slate support (30%), radiant gold accent (10%).
  static final _solsticeDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF936508),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFEBC058),
        onPrimary: const Color(0xFF2C1F02),
        primaryContainer: const Color(0xFF5E4710),
        onPrimaryContainer: const Color(0xFFF7E8BA),
        secondary: const Color(0xFFB5BAC4),
        onSecondary: const Color(0xFF1F232A),
        secondaryContainer: const Color(0xFF3A3F49),
        onSecondaryContainer: const Color(0xFFDEE1E7),
        tertiary: const Color(0xFF97BEBC),
        onTertiary: const Color(0xFF112F2E),
        tertiaryContainer: const Color(0xFF2E4E4D),
        onTertiaryContainer: const Color(0xFFD2E5E4),
        surface: const Color(0xFF131210),
        onSurface: const Color(0xFFECE9E1),
        onSurfaceVariant: const Color(0xFFC2BDB2),
        surfaceContainerLowest: const Color(0xFF0E0D0B),
        surfaceContainerLow: const Color(0xFF1A1815),
        surfaceContainer: const Color(0xFF211F1B),
        surfaceContainerHigh: const Color(0xFF282621),
        surfaceContainerHighest: const Color(0xFF302D27),
        outline: const Color(0xFF716C61),
        outlineVariant: const Color(0xFF3A3730),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFECE9E1),
        onInverseSurface: const Color(0xFF2C2A24),
      );

  // Nordic — ice-white backdrop, slate support, cobalt accent.
  static final _nordicLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF2563EB),
        onPrimary: const Color(0xFFF8FAFF),
        primaryContainer: const Color(0xFFDBE6FE),
        onPrimaryContainer: const Color(0xFF0B2A6B),
        secondary: const Color(0xFF475569),
        onSecondary: const Color(0xFFF8FAFC),
        secondaryContainer: const Color(0xFFE2E8F0),
        onSecondaryContainer: const Color(0xFF1E293B),
        tertiary: const Color(0xFF0E7490),
        onTertiary: const Color(0xFFF1FBFD),
        tertiaryContainer: const Color(0xFFCFEFF6),
        onTertiaryContainer: const Color(0xFF083344),
        surface: const Color(0xFFF8FAFC),
        onSurface: const Color(0xFF0F172A),
        onSurfaceVariant: const Color(0xFF556074),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: const Color(0xFFF3F6FA),
        surfaceContainer: const Color(0xFFEDF1F7),
        surfaceContainerHigh: const Color(0xFFE7ECF4),
        surfaceContainerHighest: const Color(0xFFE2E8F0),
        outline: const Color(0xFF9AA8BC),
        outlineVariant: const Color(0xFFD6DEEA),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF1E293B),
        onInverseSurface: const Color(0xFFF1F5F9),
      );

  static final _nordicDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF60A5FA),
        onPrimary: const Color(0xFF08203F),
        primaryContainer: const Color(0xFF1E3A6E),
        onPrimaryContainer: const Color(0xFFDBE6FE),
        secondary: const Color(0xFF94A3B8),
        onSecondary: const Color(0xFF16202E),
        secondaryContainer: const Color(0xFF334155),
        onSecondaryContainer: const Color(0xFFE2E8F0),
        tertiary: const Color(0xFF67E8F9),
        onTertiary: const Color(0xFF083344),
        tertiaryContainer: const Color(0xFF155E75),
        onTertiaryContainer: const Color(0xFFCFEFF6),
        surface: const Color(0xFF0F172A),
        onSurface: const Color(0xFFE6EBF5),
        onSurfaceVariant: const Color(0xFFA9B4C6),
        surfaceContainerLowest: const Color(0xFF0A1120),
        surfaceContainerLow: const Color(0xFF152036),
        surfaceContainer: const Color(0xFF1B2740),
        surfaceContainerHigh: const Color(0xFF223048),
        surfaceContainerHighest: const Color(0xFF293750),
        outline: const Color(0xFF64748B),
        outlineVariant: const Color(0xFF33415A),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFE2E8F0),
        onInverseSurface: const Color(0xFF1E293B),
      );

  // Oatmeal — warm oatmeal backdrop, sage support, terracotta accent.
  static final _oatmealLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFC2593F),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFFC2593F),
        onPrimary: const Color(0xFFFFF8F5),
        primaryContainer: const Color(0xFFF7DDD3),
        onPrimaryContainer: const Color(0xFF4A1C10),
        secondary: const Color(0xFF5F7363),
        onSecondary: const Color(0xFFFAFCF8),
        secondaryContainer: const Color(0xFFDFE8DF),
        onSecondaryContainer: const Color(0xFF26332A),
        tertiary: const Color(0xFF9A6B2F),
        onTertiary: const Color(0xFFFFF8EE),
        tertiaryContainer: const Color(0xFFF2E2C8),
        onTertiaryContainer: const Color(0xFF3E2A0C),
        surface: const Color(0xFFFAF7F2),
        onSurface: const Color(0xFF262119),
        onSurfaceVariant: const Color(0xFF655E52),
        surfaceContainerLowest: const Color(0xFFFFFDF9),
        surfaceContainerLow: const Color(0xFFFCF9F3),
        surfaceContainer: const Color(0xFFF2EDE4),
        surfaceContainerHigh: const Color(0xFFEBE5DA),
        surfaceContainerHighest: const Color(0xFFE4DCCF),
        outline: const Color(0xFFB0A797),
        outlineVariant: const Color(0xFFE2DACE),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF2C2820),
        onInverseSurface: const Color(0xFFF7F2EA),
      );

  static final _oatmealDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFC2593F),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFE88B72),
        onPrimary: const Color(0xFF3B140A),
        primaryContainer: const Color(0xFF6A3324),
        onPrimaryContainer: const Color(0xFFF7DDD3),
        secondary: const Color(0xFF9FB2A2),
        onSecondary: const Color(0xFF1E2B22),
        secondaryContainer: const Color(0xFF3A4A3E),
        onSecondaryContainer: const Color(0xFFDFE8DF),
        tertiary: const Color(0xFFDDB874),
        onTertiary: const Color(0xFF3B2907),
        tertiaryContainer: const Color(0xFF55411B),
        onTertiaryContainer: const Color(0xFFF2E2C8),
        surface: const Color(0xFF161412),
        onSurface: const Color(0xFFECE7DE),
        onSurfaceVariant: const Color(0xFFBDB6A9),
        surfaceContainerLowest: const Color(0xFF100E0D),
        surfaceContainerLow: const Color(0xFF1C1916),
        surfaceContainer: const Color(0xFF24211D),
        surfaceContainerHigh: const Color(0xFF2B2722),
        surfaceContainerHighest: const Color(0xFF332E28),
        outline: const Color(0xFF746D61),
        outlineVariant: const Color(0xFF3C362F),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFECE7DE),
        onInverseSurface: const Color(0xFF2C2820),
      );

  // Obsidian — alabaster backdrop, graphite support, champagne-gold accent.
  static final _obsidianLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF936508),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF936508),
        onPrimary: const Color(0xFFFFFDF6),
        primaryContainer: const Color(0xFFF2E2B8),
        onPrimaryContainer: const Color(0xFF3A2600),
        secondary: const Color(0xFF4A4E5A),
        onSecondary: const Color(0xFFF9F9FB),
        secondaryContainer: const Color(0xFFDFE1E7),
        onSecondaryContainer: const Color(0xFF1D1F26),
        tertiary: const Color(0xFF4F6F86),
        onTertiary: const Color(0xFFF4F9FC),
        tertiaryContainer: const Color(0xFFD5E4EE),
        onTertiaryContainer: const Color(0xFF152D3D),
        surface: const Color(0xFFF5F4F0),
        onSurface: const Color(0xFF1D1C19),
        onSurfaceVariant: const Color(0xFF5A574F),
        surfaceContainerLowest: const Color(0xFFFDFCF9),
        surfaceContainerLow: const Color(0xFFF9F8F3),
        surfaceContainer: const Color(0xFFEFEEE8),
        surfaceContainerHigh: const Color(0xFFE9E7E0),
        surfaceContainerHighest: const Color(0xFFE3E1D9),
        outline: const Color(0xFFA9A59A),
        outlineVariant: const Color(0xFFDDD9CF),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF2B2A26),
        onInverseSurface: const Color(0xFFF5F4F0),
      );

  static final _obsidianDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFE5B84B),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFE5B84B),
        onPrimary: const Color(0xFF2B2105),
        primaryContainer: const Color(0xFF5A4511),
        onPrimaryContainer: const Color(0xFFF6E5B4),
        secondary: const Color(0xFFA1A6B3),
        onSecondary: const Color(0xFF1D2026),
        secondaryContainer: const Color(0xFF3A3E48),
        onSecondaryContainer: const Color(0xFFE2E4E9),
        tertiary: const Color(0xFF9BB7D4),
        onTertiary: const Color(0xFF122739),
        tertiaryContainer: const Color(0xFF33475C),
        onTertiaryContainer: const Color(0xFFD3E2F0),
        surface: const Color(0xFF111215),
        onSurface: const Color(0xFFE7E7EA),
        onSurfaceVariant: const Color(0xFFB3B4BD),
        surfaceContainerLowest: const Color(0xFF0C0D0F),
        surfaceContainerLow: const Color(0xFF17181C),
        surfaceContainer: const Color(0xFF1E2026),
        surfaceContainerHigh: const Color(0xFF25272E),
        surfaceContainerHighest: const Color(0xFF2D2F37),
        outline: const Color(0xFF6E7079),
        outlineVariant: const Color(0xFF34363E),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFE7E7EA),
        onInverseSurface: const Color(0xFF1D1E22),
      );

  // Mint — pale mint backdrop, deep-pine support, coral accent.
  static final _mintLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFD96248),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFFD96248),
        onPrimary: const Color(0xFFFFF7F4),
        primaryContainer: const Color(0xFFF8DCD4),
        onPrimaryContainer: const Color(0xFF4C1A0F),
        secondary: const Color(0xFF2D5A4C),
        onSecondary: const Color(0xFFF5FBF8),
        secondaryContainer: const Color(0xFFD3E7DE),
        onSecondaryContainer: const Color(0xFF14352C),
        tertiary: const Color(0xFFA9782C),
        onTertiary: const Color(0xFFFFF8EC),
        tertiaryContainer: const Color(0xFFF0E1C3),
        onTertiaryContainer: const Color(0xFF3D2A08),
        surface: const Color(0xFFF3F8F6),
        onSurface: const Color(0xFF16211D),
        onSurfaceVariant: const Color(0xFF57655F),
        surfaceContainerLowest: const Color(0xFFFAFDFC),
        surfaceContainerLow: const Color(0xFFEFF7F3),
        surfaceContainer: const Color(0xFFE4EFEA),
        surfaceContainerHigh: const Color(0xFFDDEAE4),
        surfaceContainerHighest: const Color(0xFFD6E4DD),
        outline: const Color(0xFF9DB2A9),
        outlineVariant: const Color(0xFFD2E2DA),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF22302B),
        onInverseSurface: const Color(0xFFF1F8F5),
      );

  static final _mintDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFD96248),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFF2957E),
        onPrimary: const Color(0xFF43180D),
        primaryContainer: const Color(0xFF6E3726),
        onPrimaryContainer: const Color(0xFFF8DCD4),
        secondary: const Color(0xFF8AB8A8),
        onSecondary: const Color(0xFF10241D),
        secondaryContainer: const Color(0xFF2E4A3F),
        onSecondaryContainer: const Color(0xFFD3E7DE),
        tertiary: const Color(0xFFD9B26E),
        onTertiary: const Color(0xFF382703),
        tertiaryContainer: const Color(0xFF524015),
        onTertiaryContainer: const Color(0xFFF0E1C3),
        surface: const Color(0xFF0F1715),
        onSurface: const Color(0xFFE3ECE7),
        onSurfaceVariant: const Color(0xFFB2C2BB),
        surfaceContainerLowest: const Color(0xFF0A100F),
        surfaceContainerLow: const Color(0xFF151F1C),
        surfaceContainer: const Color(0xFF1B2824),
        surfaceContainerHigh: const Color(0xFF22302B),
        surfaceContainerHighest: const Color(0xFF2A3933),
        outline: const Color(0xFF66776F),
        outlineVariant: const Color(0xFF2E3D37),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFE3ECE7),
        onInverseSurface: const Color(0xFF22302B),
      );

  // Midnight — cool paper backdrop, periwinkle support, violet accent.
  static final _midnightLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF6D4AFF),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF6D4AFF),
        onPrimary: const Color(0xFFF8F7FF),
        primaryContainer: const Color(0xFFE2DBFF),
        onPrimaryContainer: const Color(0xFF24105E),
        secondary: const Color(0xFF555B75),
        onSecondary: const Color(0xFFF8F9FC),
        secondaryContainer: const Color(0xFFDEE1EB),
        onSecondaryContainer: const Color(0xFF1A1E2C),
        tertiary: const Color(0xFF2F7A70),
        onTertiary: const Color(0xFFF2FBF8),
        tertiaryContainer: const Color(0xFFCDE8E1),
        onTertiaryContainer: const Color(0xFF0D332C),
        surface: const Color(0xFFF5F5FA),
        onSurface: const Color(0xFF1A1A24),
        onSurfaceVariant: const Color(0xFF5B5C6B),
        surfaceContainerLowest: const Color(0xFFFDFDFF),
        surfaceContainerLow: const Color(0xFFF9F9FD),
        surfaceContainer: const Color(0xFFEDEDF4),
        surfaceContainerHigh: const Color(0xFFE6E6EF),
        surfaceContainerHighest: const Color(0xFFE0E0EA),
        outline: const Color(0xFFA2A3B4),
        outlineVariant: const Color(0xFFD8D9E4),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF262634),
        onInverseSurface: const Color(0xFFF5F5FA),
      );

  static final _midnightDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFA78BFA),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFA78BFA),
        onPrimary: const Color(0xFF281050),
        primaryContainer: const Color(0xFF46308A),
        onPrimaryContainer: const Color(0xFFE6DCFE),
        secondary: const Color(0xFF8E95B2),
        onSecondary: const Color(0xFF1B1D26),
        secondaryContainer: const Color(0xFF343849),
        onSecondaryContainer: const Color(0xFFE0E2EB),
        tertiary: const Color(0xFF89D4CE),
        onTertiary: const Color(0xFF0B2F2B),
        tertiaryContainer: const Color(0xFF2B4A46),
        onTertiaryContainer: const Color(0xFFCDEDEA),
        surface: const Color(0xFF12131A),
        onSurface: const Color(0xFFE6E7EE),
        onSurfaceVariant: const Color(0xFFAEB1C2),
        surfaceContainerLowest: const Color(0xFF0C0D12),
        surfaceContainerLow: const Color(0xFF181924),
        surfaceContainer: const Color(0xFF1E202B),
        surfaceContainerHigh: const Color(0xFF252736),
        surfaceContainerHighest: const Color(0xFF2D2F40),
        outline: const Color(0xFF656A80),
        outlineVariant: const Color(0xFF303345),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFE6E7EE),
        onInverseSurface: const Color(0xFF1B1D26),
      );

  // Swiss — warm paper backdrop, charcoal support, vermilion accent.
  static final _swissLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFDC2626),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFFDC2626),
        onPrimary: const Color(0xFFFFF7F6),
        primaryContainer: const Color(0xFFF9D4D0),
        onPrimaryContainer: const Color(0xFF4B0C0A),
        secondary: const Color(0xFF44403C),
        onSecondary: const Color(0xFFFAFAF9),
        secondaryContainer: const Color(0xFFE2DEDA),
        onSecondaryContainer: const Color(0xFF231F1D),
        tertiary: const Color(0xFF6B7280),
        onTertiary: const Color(0xFFF9FAFB),
        tertiaryContainer: const Color(0xFFE1E4E8),
        onTertiaryContainer: const Color(0xFF1F2937),
        surface: const Color(0xFFF5F5F4),
        onSurface: const Color(0xFF1C1917),
        onSurfaceVariant: const Color(0xFF57534E),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: const Color(0xFFFAFAF9),
        surfaceContainer: const Color(0xFFEFEEEC),
        surfaceContainerHigh: const Color(0xFFE9E7E5),
        surfaceContainerHighest: const Color(0xFFE7E5E4),
        outline: const Color(0xFFA8A29E),
        outlineVariant: const Color(0xFFDCD9D6),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF292524),
        onInverseSurface: const Color(0xFFF5F5F4),
      );

  static final _swissDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFDC2626),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFF87171),
        onPrimary: const Color(0xFF450A0A),
        primaryContainer: const Color(0xFF6B1A1A),
        onPrimaryContainer: const Color(0xFFFAD4D0),
        secondary: const Color(0xFFA8A29E),
        onSecondary: const Color(0xFF1F1D1B),
        secondaryContainer: const Color(0xFF3B3733),
        onSecondaryContainer: const Color(0xFFE7E3DF),
        tertiary: const Color(0xFFD6D3D1),
        onTertiary: const Color(0xFF262321),
        tertiaryContainer: const Color(0xFF44403C),
        onTertiaryContainer: const Color(0xFFF5F5F4),
        surface: const Color(0xFF141413),
        onSurface: const Color(0xFFE7E5E4),
        onSurfaceVariant: const Color(0xFFB7B2AE),
        surfaceContainerLowest: const Color(0xFF0E0E0D),
        surfaceContainerLow: const Color(0xFF1B1A19),
        surfaceContainer: const Color(0xFF242321),
        surfaceContainerHigh: const Color(0xFF2B2A28),
        surfaceContainerHighest: const Color(0xFF33322F),
        outline: const Color(0xFF6B6663),
        outlineVariant: const Color(0xFF33312E),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFE7E5E4),
        onInverseSurface: const Color(0xFF262321),
      );

  // Harbor — warm linen backdrop, deep-navy support, teal accent.
  static final _harborLight =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D9488),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF0D9488),
        onPrimary: const Color(0xFFF2FDFB),
        primaryContainer: const Color(0xFFCDEFE9),
        onPrimaryContainer: const Color(0xFF06312D),
        secondary: const Color(0xFF1E293B),
        onSecondary: const Color(0xFFF8FAFC),
        secondaryContainer: const Color(0xFFEDEBE4),
        onSecondaryContainer: const Color(0xFF26313F),
        tertiary: const Color(0xFFA06A2E),
        onTertiary: const Color(0xFFFFF8EE),
        tertiaryContainer: const Color(0xFFF1E2CC),
        onTertiaryContainer: const Color(0xFF3F2A0D),
        surface: const Color(0xFFFAF9F6),
        onSurface: const Color(0xFF1C2530),
        onSurfaceVariant: const Color(0xFF5D6672),
        surfaceContainerLowest: const Color(0xFFFFFEFB),
        surfaceContainerLow: const Color(0xFFF6F4EF),
        surfaceContainer: const Color(0xFFF1EFE9),
        surfaceContainerHigh: const Color(0xFFEDEBE4),
        surfaceContainerHighest: const Color(0xFFE4E0D8),
        outline: const Color(0xFFA9A69C),
        outlineVariant: const Color(0xFFDDD9D0),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF22303F),
        onInverseSurface: const Color(0xFFF5F3EE),
      );

  static final _harborDark =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D9488),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF2DD4BF),
        onPrimary: const Color(0xFF042F2A),
        primaryContainer: const Color(0xFF115E56),
        onPrimaryContainer: const Color(0xFFCDEFE9),
        secondary: const Color(0xFF94A3B8),
        onSecondary: const Color(0xFF1C2430),
        secondaryContainer: const Color(0xFF2C3849),
        onSecondaryContainer: const Color(0xFFE2E8F0),
        tertiary: const Color(0xFFD9B27C),
        onTertiary: const Color(0xFF3B2A0A),
        tertiaryContainer: const Color(0xFF55411C),
        onTertiaryContainer: const Color(0xFFF1E2CC),
        surface: const Color(0xFF0E131A),
        onSurface: const Color(0xFFE6EBF1),
        onSurfaceVariant: const Color(0xFFA9B3C0),
        surfaceContainerLowest: const Color(0xFF090C11),
        surfaceContainerLow: const Color(0xFF141A22),
        surfaceContainer: const Color(0xFF19222E),
        surfaceContainerHigh: const Color(0xFF202A38),
        surfaceContainerHighest: const Color(0xFF283342),
        outline: const Color(0xFF5F6C7D),
        outlineVariant: const Color(0xFF2B3543),
        error: const Color(0xFFF2B8B5),
        onError: const Color(0xFF601410),
        inverseSurface: const Color(0xFFE6EBF1),
        onInverseSurface: const Color(0xFF1C2430),
      );
}
