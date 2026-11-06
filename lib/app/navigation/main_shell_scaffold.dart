import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import 'glass_dock.dart';

/// The persistent shell chrome: an [IndexedStack] of tabs behind a floating
/// frosted dock.
///
/// Keeping every tab mounted is deliberate. Tabs that hold native surfaces
/// (the Mapbox view) or in-flight streams must not be rebuilt when the member
/// moves between them.
class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({
    super.key,
    required this.index,
    required this.onSelect,
    required this.unreadChats,
    required this.newMemories,
    required this.children,
    this.dockVisible = true,
    this.overlay,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final int unreadChats;
  final int newMemories;
  final List<Widget> children;

  /// False while a full-screen trip cockpit owns the map tab. The dock slides
  /// away instead of vanishing, and stops accepting taps immediately.
  final bool dockVisible;

  /// Drawn above every tab, e.g. the warmth banner.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final scaffold = Scaffold(
      backgroundColor: scheme.surface,
      // The dock floats over the tabs so the frosted glass has content to blur.
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: [
          // Muted tickers mean a hidden tab never schedules animation frames.
          for (var i = 0; i < children.length; i++)
            TickerMode(enabled: i == index, child: children[i]),
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: dockVisible ? Offset.zero : const Offset(0, 1.2),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInCubic,
        child: AnimatedOpacity(
          opacity: dockVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !dockVisible,
            child: GlassDock(
              index: index,
              onSelect: onSelect,
              unreadChats: unreadChats,
              newMemories: newMemories,
            ),
          ),
        ),
      ),
    );

    final banner = overlay;
    if (banner == null) return scaffold;

    return Stack(
      children: [
        Positioned.fill(child: scaffold),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: banner,
        ),
      ],
    );
  }
}
