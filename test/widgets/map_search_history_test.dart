import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/core/storage/storage_providers.dart';
import 'package:pathfinders/features/navigation/presentation/widgets/map_search_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows stored recent searches when the field is focused', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'search.history.u1': ['Blue Nile', 'Entoto'],
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          home: Scaffold(
            body: MapSearchBar(
              userId: 'u1',
              unreadCount: 0,
              onChat: () {},
              onPlaceSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Recent searches'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Blue Nile'), findsOneWidget);
    expect(find.text('Entoto'), findsOneWidget);
  });
}
