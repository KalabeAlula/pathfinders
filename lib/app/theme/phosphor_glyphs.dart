import 'package:flutter/material.dart';

/// A Phosphor glyph in one of two weights.
///
/// Duotone icons ship as two codepoints: a filled secondary layer drawn under
/// the line-art primary. Solid glyphs only carry the primary.
class GlyphPair {
  const GlyphPair.duotone(this.primary, IconData this.secondary);
  const GlyphPair.solid(this.primary) : secondary = null;

  final IconData primary;
  final IconData? secondary;
}

/// The handful of Phosphor icons the shell uses, vendored so the app does not
/// depend on `phosphor_flutter` (its `IconData` subclassing no longer builds).
abstract final class ShellGlyphs {
  static const circle = GlyphPair.duotone(
    IconData(0xe68f, fontFamily: 'PhosphorDuotone'),
    IconData(0xe68e, fontFamily: 'PhosphorDuotone'),
  );
  static const circleSelected = GlyphPair.solid(
    IconData(0xe68e, fontFamily: 'PhosphorFill'),
  );

  static const chat = GlyphPair.duotone(
    IconData(0xe16d, fontFamily: 'PhosphorDuotone'),
    IconData(0xe16c, fontFamily: 'PhosphorDuotone'),
  );
  static const chatSelected = GlyphPair.solid(
    IconData(0xe16c, fontFamily: 'PhosphorFill'),
  );

  static const map = GlyphPair.duotone(
    IconData(0xe31b, fontFamily: 'PhosphorDuotone'),
    IconData(0xe31a, fontFamily: 'PhosphorDuotone'),
  );
  static const mapSelected = GlyphPair.solid(
    IconData(0xe31a, fontFamily: 'PhosphorFill'),
  );

  static const memories = GlyphPair.duotone(
    IconData(0xe6a3, fontFamily: 'PhosphorDuotone'),
    IconData(0xe6a2, fontFamily: 'PhosphorDuotone'),
  );
  static const memoriesSelected = GlyphPair.solid(
    IconData(0xe6a2, fontFamily: 'PhosphorFill'),
  );

  static const profile = GlyphPair.duotone(
    IconData(0xe4c5, fontFamily: 'PhosphorDuotone'),
    IconData(0xe4c4, fontFamily: 'PhosphorDuotone'),
  );
  static const profileSelected = GlyphPair.solid(
    IconData(0xe4c4, fontFamily: 'PhosphorFill'),
  );
}

/// Renders a [GlyphPair], tinting the duotone secondary layer with
/// [secondaryColor] under the usual Phosphor 20% wash.
class PhosphorGlyph extends StatelessWidget {
  const PhosphorGlyph(
    this.glyph, {
    super.key,
    this.size,
    this.color,
    this.secondaryColor,
    this.secondaryOpacity = 0.20,
  });

  final GlyphPair glyph;
  final double? size;
  final Color? color;
  final Color? secondaryColor;
  final double secondaryOpacity;

  @override
  Widget build(BuildContext context) {
    final secondary = glyph.secondary;
    if (secondary == null) {
      return Icon(glyph.primary, size: size, color: color);
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: secondaryOpacity,
          child: Icon(secondary, size: size, color: secondaryColor ?? color),
        ),
        Icon(glyph.primary, size: size, color: color),
      ],
    );
  }
}
