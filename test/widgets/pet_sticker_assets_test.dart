import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every shipped pet PNG and animated WebP sticker must load and decode cleanly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pets = ['fox', 'seagull', 'dog', 'orangutan'];
  const moods = ['idle', 'traveling', 'celebrating', 'sleeping'];

  for (final pet in pets) {
    testWidgets('$pet static portrait decodes', (tester) async {
      final bytes = await rootBundle.load('assets/pets/$pet.png');
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();

      expect(frame.image.width, 256);
      expect(frame.image.height, 256);
      frame.image.dispose();
      codec.dispose();
    });

    for (final mood in moods) {
      for (var i = 1; i <= 3; i++) {
        testWidgets('$pet ${mood}_$i animated WebP decodes', (tester) async {
          final bytes = await rootBundle.load(
            'assets/pets/$pet/${mood}_$i.webp',
          );
          final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(),
          );
          expect(codec.frameCount, greaterThan(1));
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 256);
          expect(frame.image.height, 256);
          frame.image.dispose();
          codec.dispose();
        });
      }
    }

    testWidgets('$pet idle_1 sticker renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Image.asset(
              'assets/pets/$pet/idle_1.webp',
              width: 84,
              height: 84,
              gaplessPlayback: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsOneWidget);
    });
  }
}
