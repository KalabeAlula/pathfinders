import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/phosphor_glyphs.dart';

/// Spacing shared by the floating dock and the tab bodies that scroll behind
/// it. Tabs add [contentInset] to their bottom padding so composers, HUD cards
/// and the memories FAB stay clear of the glass.
abstract final class ShellDock {
  static const double height = 68;
  static const double sideMargin = 12;

  /// Gap between the dock and the OS gesture/navigation area. The 24dp floor
  /// keeps labels off a three-button bar, where the window already ends above
  /// the system buttons and reports no bottom inset.
  static double bottomGap(BuildContext context) =>
      math.max(MediaQuery.viewPaddingOf(context).bottom + 12, 24);

  static double contentInset(BuildContext context) =>
      bottomGap(context) + height + 12;
}

/// A floating, frosted pill holding the five destinations.
///
/// The dock floats over the tab body (`Scaffold.extendBody`), so the blur has
/// live content underneath instead of a flat background.
class GlassDock extends StatelessWidget {
  const GlassDock({
    super.key,
    required this.index,
    required this.onSelect,
    required this.unreadChats,
    required this.newMemories,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final int unreadChats;
  final int newMemories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final radius = BorderRadius.circular(AppRadius.sheet);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ShellDock.sideMargin,
        0,
        ShellDock.sideMargin,
        ShellDock.bottomGap(context),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest.withValues(alpha: 0.82),
                borderRadius: radius,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.65),
                ),
              ),
              // NavigationBar folds the OS inset into its height. The dock
              // owns that spacing, so strip it from the inner copy.
              child: MediaQuery(
                data: media.copyWith(
                  padding: media.padding.copyWith(bottom: 0),
                  viewPadding: media.viewPadding.copyWith(bottom: 0),
                ),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    indicatorColor: scheme.primaryContainer.withValues(
                      alpha: 0.55,
                    ),
                    elevation: 0,
                    height: ShellDock.height,
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return theme.textTheme.labelSmall?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        size: 24,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      );
                    }),
                  ),
                  child: NavigationBar(
                    selectedIndex: index,
                    onDestinationSelected: onSelect,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      _destination(
                        key: 'tab-circle',
                        label: 'Circle',
                        icon: _glyph(
                          ShellGlyphs.circle,
                          accent: scheme.tertiary,
                        ),
                        selectedIcon: _glyph(ShellGlyphs.circleSelected),
                      ),
                      _destination(
                        key: 'tab-chat',
                        label: 'Chat',
                        icon: _glyph(
                          ShellGlyphs.chat,
                          accent: scheme.tertiary,
                          badge: unreadChats,
                        ),
                        selectedIcon: _glyph(
                          ShellGlyphs.chatSelected,
                          badge: unreadChats,
                        ),
                      ),
                      _destination(
                        key: 'tab-map',
                        label: 'Map',
                        icon: _glyph(
                          ShellGlyphs.map,
                          accent: scheme.tertiary,
                        ),
                        selectedIcon: _glyph(ShellGlyphs.mapSelected),
                      ),
                      _destination(
                        key: 'tab-memories',
                        label: 'Memories',
                        icon: _glyph(
                          ShellGlyphs.memories,
                          accent: scheme.tertiary,
                          badge: newMemories,
                        ),
                        selectedIcon: _glyph(
                          ShellGlyphs.memoriesSelected,
                          badge: newMemories,
                        ),
                      ),
                      _destination(
                        key: 'tab-profile',
                        label: 'Profile',
                        icon: _glyph(
                          ShellGlyphs.profile,
                          accent: scheme.tertiary,
                        ),
                        selectedIcon: _glyph(ShellGlyphs.profileSelected),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _destination({
    required String key,
    required String label,
    required Widget icon,
    required Widget selectedIcon,
  }) => NavigationDestination(
    key: ValueKey(key),
    icon: icon,
    selectedIcon: selectedIcon,
    label: label,
  );

  Widget _glyph(GlyphPair glyph, {Color? accent, int badge = 0}) {
    final Widget icon = accent == null
        ? PhosphorGlyph(glyph)
        : PhosphorGlyph(glyph, secondaryColor: accent);
    if (badge <= 0) return icon;
    return _DockBadge(count: badge, child: icon);
  }
}

class _DockBadge extends StatelessWidget {
  const _DockBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Badge.count(
      count: count,
      backgroundColor: scheme.primary,
      textColor: scheme.onPrimary,
      child: child,
    );
  }
}
