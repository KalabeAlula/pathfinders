import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/app/widgets/content_frame.dart';

void main() {
  testWidgets('caps the column and keeps it centred', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentFrame(
            maxWidth: 400,
            child: SizedBox(key: ValueKey('column'), width: double.infinity),
          ),
        ),
      ),
    );

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pump();

    final column = find.byKey(const ValueKey('column'));
    expect(tester.getSize(column).width, 400);
    expect(tester.getTopLeft(column).dx, 400);
  });

  testWidgets('does not narrow a phone-width column', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentFrame(
            maxWidth: 400,
            child: SizedBox(key: ValueKey('column'), width: double.infinity),
          ),
        ),
      ),
    );

    final column = find.byKey(const ValueKey('column'));
    expect(tester.getSize(column).width, 390);
  });
}
