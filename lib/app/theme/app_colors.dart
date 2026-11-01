import 'package:flutter/material.dart';

/// Warm earth-tone palette shared by both themes.
///
/// Feature code should normally read colours from the active [ColorScheme].
/// These constants exist for brand moments (map markers, mood gradients) where
/// the hue must stay recognisable regardless of brightness.
abstract final class AppColors {
  static const clay = Color(0xFFB86B4F);
  static const sage = Color(0xFF7C8C6B);
  static const honey = Color(0xFFC7974C);
  static const ink = Color(0xFF2C2823);
  static const sand = Color(0xFFF6F0E7);
  static const linen = Color(0xFFFFFBF5);
  static const cocoa = Color(0xFF3A3028);
  static const ember = Color(0xFFE0A487);

  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: clay,
    brightness: Brightness.light,
  ).copyWith(
    primary: clay,
    onPrimary: const Color(0xFFFFF8F3),
    primaryContainer: const Color(0xFFF4DDD1),
    onPrimaryContainer: const Color(0xFF4A2418),
    secondary: sage,
    onSecondary: const Color(0xFFFFFBF3),
    secondaryContainer: const Color(0xFFE3E8D7),
    onSecondaryContainer: const Color(0xFF2E3A24),
    tertiary: honey,
    onTertiary: const Color(0xFF3A2708),
    tertiaryContainer: const Color(0xFFF6E4C4),
    onTertiaryContainer: const Color(0xFF4A340B),
    surface: sand,
    onSurface: ink,
    onSurfaceVariant: const Color(0xFF6D6256),
    surfaceContainerLowest: linen,
    surfaceContainerLow: const Color(0xFFFBF5EC),
    surfaceContainer: const Color(0xFFF3EBDF),
    surfaceContainerHigh: const Color(0xFFEEE4D6),
    surfaceContainerHighest: const Color(0xFFE8DCCB),
    outline: const Color(0xFFB3A593),
    outlineVariant: const Color(0xFFE1D5C5),
    error: const Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    inverseSurface: const Color(0xFF332E28),
    onInverseSurface: const Color(0xFFF7F0E6),
  );

  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: clay,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFFE4A78C),
    onPrimary: const Color(0xFF4A2418),
    primaryContainer: const Color(0xFF5A3427),
    onPrimaryContainer: const Color(0xFFF4DDD1),
    secondary: const Color(0xFFAEBD9C),
    onSecondary: const Color(0xFF2E3A24),
    secondaryContainer: const Color(0xFF3C4A31),
    onSecondaryContainer: const Color(0xFFE3E8D7),
    tertiary: const Color(0xFFE0B778),
    onTertiary: const Color(0xFF3A2708),
    tertiaryContainer: const Color(0xFF57431D),
    onTertiaryContainer: const Color(0xFFF6E4C4),
    surface: const Color(0xFF191613),
    onSurface: const Color(0xFFEFE7DC),
    onSurfaceVariant: const Color(0xFFC3B6A6),
    surfaceContainerLowest: const Color(0xFF14110F),
    surfaceContainerLow: const Color(0xFF201C18),
    surfaceContainer: const Color(0xFF26211C),
    surfaceContainerHigh: const Color(0xFF2E2822),
    surfaceContainerHighest: const Color(0xFF383129),
    outline: const Color(0xFF6F6458),
    outlineVariant: const Color(0xFF3D362E),
    error: const Color(0xFFF2B8B5),
    onError: const Color(0xFF601410),
    inverseSurface: const Color(0xFFEFE7DC),
    onInverseSurface: const Color(0xFF332E28),
  );
}
