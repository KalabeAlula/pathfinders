import 'package:flutter/material.dart';

/// Centres a tab's column on wide windows so the phone-first layouts do not
/// stretch across a desktop browser.
///
/// The frame only caps the width; below [maxWidth] the child fills the window
/// exactly as before, so the phone layout is untouched.
class ContentFrame extends StatelessWidget {
  const ContentFrame({super.key, required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Width caps for the signed-in tabs.
abstract final class ContentWidths {
  static const circle = 760.0;
  static const chat = 860.0;
  static const memories = 1120.0;
  static const profile = 760.0;

  /// The search bar and destination card stay a HUD card on desktop windows.
  static const mapHud = 560.0;
}
