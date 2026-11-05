import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// The persistent shell chrome: an [IndexedStack] of tabs above a warm
/// Material 3 navigation bar.
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
    required this.children,
    this.overlay,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final int unreadChats;
  final List<Widget> children;

  /// Drawn above every tab, e.g. the warmth banner.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final scaffold = Scaffold(
      backgroundColor: scheme.surface,
      body: IndexedStack(index: index, children: children),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: scheme.surfaceContainerLowest,
            surfaceTintColor: Colors.transparent,
            indicatorColor: scheme.primaryContainer,
            elevation: 0,
            height: 68,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return theme.textTheme.labelSmall?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 24,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: onSelect,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              const NavigationDestination(
                key: ValueKey('tab-map'),
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: 'Map',
              ),
              NavigationDestination(
                key: const ValueKey('tab-chat'),
                icon: _ChatIcon(
                  unread: unreadChats,
                  icon: Icons.chat_bubble_outline_rounded,
                ),
                selectedIcon: _ChatIcon(
                  unread: unreadChats,
                  icon: Icons.chat_bubble_rounded,
                ),
                label: 'Chat',
              ),
              const NavigationDestination(
                key: ValueKey('tab-memories'),
                icon: Icon(Icons.photo_library_outlined),
                selectedIcon: Icon(Icons.photo_library_rounded),
                label: 'Memories',
              ),
              const NavigationDestination(
                key: ValueKey('tab-circle'),
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group_rounded),
                label: 'Circle',
              ),
            ],
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

class _ChatIcon extends StatelessWidget {
  const _ChatIcon({required this.unread, required this.icon});

  final int unread;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (unread <= 0) return Icon(icon);
    return Badge.count(
      count: unread,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary,
      child: Icon(icon),
    );
  }
}
