import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/location/presentation/widgets/background_location_disclosure.dart';

void main() {
  testWidgets('explains background location before permission is requested', (
    tester,
  ) async {
    bool? consent;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                consent = await showBackgroundLocationDisclosure(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Share location when closed?'), findsOneWidget);
    expect(find.textContaining('even when the app is closed'), findsOneWidget);
    expect(find.textContaining('until you pause sharing'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(consent, isFalse);
    expect(find.text('Share location when closed?'), findsNothing);
  });

  testWidgets('only reports consent after Continue', (tester) async {
    bool? consent;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                consent = await showBackgroundLocationDisclosure(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(consent, isTrue);
  });

  testWidgets('fits a narrow screen at 1.3x text', (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showBackgroundLocationDisclosure(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Continue'), findsOneWidget);
  });
}
