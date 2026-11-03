import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/nudges/presentation/widgets/nudge_overlay.dart';
import 'package:pathfinders/features/nudges/presentation/widgets/nudge_tile.dart';

Widget _app({required Widget child, double textScale = 1.2}) {
  return MaterialApp(
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: appChild!,
    ),
    home: Scaffold(body: child),
  );
}

void _usePhone(WidgetTester tester, {Size size = const Size(720, 1600)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('nudge tile fits a 360dp phone at 1.2x text', (tester) async {
    _usePhone(tester);

    await tester.pumpWidget(
      _app(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 124,
            child: Row(
              children: [
                const Expanded(flex: 3, child: SizedBox.expand()),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: NudgeTile(onSend: () {})),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Nudge'), findsOneWidget);
    expect(find.text('Send warmth'), findsOneWidget);
  });

  testWidgets('nudge tile survives 1.4x text in a short tile', (tester) async {
    _usePhone(tester);

    await tester.pumpWidget(
      _app(
        textScale: 1.4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 124,
            width: 128,
            child: NudgeTile(onSend: () {}),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('nudge overlay fits a narrow screen with scaled text', (
    tester,
  ) async {
    _usePhone(tester);

    await tester.pumpWidget(
      _app(
        child: const NudgeOverlay(
          title: 'Thinking of you',
          message: 'Kaleab sent the whole crew a little warmth.',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  });
}
