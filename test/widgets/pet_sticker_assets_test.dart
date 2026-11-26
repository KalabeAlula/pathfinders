import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every shipped pet PNG portrait must load and decode cleanly.
///
/// Animated WebP stickers are now hosted in Supabase Storage and are not
/// tested here (they're tested via integration/E2E tests with real network).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pets = ['fox', 'seagull', 'dog', 'orangutan'];

  for (final pet in pets) {
    testWidgets('$pet static portrait decodes', (tester) async {
      await tester.runAsync(() async {
        final bytes = await rootBundle.load('assets/pets/$pet.png');
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();

        expect(frame.image.width, 256);
        expect(frame.image.height, 256);
        frame.image.dispose();
        codec.dispose();
      });
    });

    testWidgets('$pet static portrait renders in widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Image.asset('assets/pets/$pet.png', width: 256, height: 256),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsOneWidget);
    });
  }
}
