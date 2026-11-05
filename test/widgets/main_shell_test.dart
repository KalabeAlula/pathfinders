import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/navigation/main_shell_scaffold.dart';
import 'package:pathfinders/app/theme/app_theme.dart';

void main() {
  testWidgets('renders the five destinations in order above the tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const _ShellHarness());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(IndexedStack), findsOneWidget);

    final destinations = tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .destinations
        .map((destination) => (destination as NavigationDestination).label)
        .toList();
    expect(destinations, ['Circle', 'Chat', 'Map', 'Memories', 'Profile']);

    for (final key in ['circle', 'chat', 'map', 'memories', 'profile']) {
      expect(find.byKey(ValueKey('tab-$key')), findsOneWidget);
    }

    // Circle is the first tab and the starting index.
    expect(find.text('Circle page'), findsOneWidget);
    expect(find.text('Map page'), findsNothing);
  });

  testWidgets('tapping a destination switches tabs and preserves state', (
    tester,
  ) async {
    await tester.pumpWidget(const _ShellHarness());

    await tester.tap(find.byKey(const ValueKey('tab-map')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Increment'));
    await tester.tap(find.text('Increment'));
    await tester.pump();
    expect(find.text('Map count 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-chat')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.text('Chat page'), findsOneWidget);
    // The map stays mounted offstage so its native surface is never rebuilt.
    expect(find.text('Map page', skipOffstage: false), findsOneWidget);
    expect(find.text('Map page'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tab-memories')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
    expect(find.text('Memories page'), findsOneWidget);
    expect(find.text('Chat page'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tab-profile')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      4,
    );
    expect(find.text('Profile page'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-map')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.text('Map page'), findsOneWidget);
    expect(find.text('Map count 2'), findsOneWidget);
  });

  testWidgets('shows the unread chat badge only when there are unread chats', (
    tester,
  ) async {
    await tester.pumpWidget(const _ShellHarness(unreadChats: 3));

    expect(find.byType(Badge), findsWidgets);
    expect(find.text('3'), findsWidgets);

    await tester.pumpWidget(const _ShellHarness(unreadChats: 0));
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsNothing);
    expect(find.text('3'), findsNothing);
  });

  testWidgets('draws the overlay banner above the shell', (tester) async {
    await tester.pumpWidget(const _ShellHarness(overlay: Text('Warmth!')));

    final banner = find.text('Warmth!');
    expect(banner, findsOneWidget);
    expect(tester.getTopLeft(banner).dy, lessThan(60));

    // The banner floats above a full-bleed shell rather than pushing it down.
    expect(tester.getTopLeft(find.byType(IndexedStack)).dy, 0);
  });
}

class _ShellHarness extends StatefulWidget {
  const _ShellHarness({this.unreadChats = 0, this.overlay});

  final int unreadChats;
  final Widget? overlay;

  @override
  State<_ShellHarness> createState() => _ShellHarnessState();
}

class _ShellHarnessState extends State<_ShellHarness> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: MainShellScaffold(
        index: _index,
        onSelect: (index) => setState(() => _index = index),
        unreadChats: widget.unreadChats,
        overlay: widget.overlay,
        children: const [
          Center(child: Text('Circle page')),
          Center(child: Text('Chat page')),
          _MapPage(),
          Center(child: Text('Memories page')),
          Center(child: Text('Profile page')),
        ],
      ),
    );
  }
}

class _MapPage extends StatefulWidget {
  const _MapPage();

  @override
  State<_MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<_MapPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Map page'),
          Text('Map count $_count'),
          TextButton(
            onPressed: () => setState(() => _count++),
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
