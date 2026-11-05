import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// Every shipped sticker has to parse and draw: a malformed file would
/// silently fall back to the procedural portrait.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const moods = ['idle', 'traveling', 'celebrating', 'sleeping'];

  for (final mood in moods) {
    testWidgets('gelada $mood sticker parses and renders', (tester) async {
      final path = 'assets/pets/gelada/$mood.json';
      final composition = await LottieComposition.fromByteData(
        await rootBundle.load(path),
      );

      expect(composition.warnings, isEmpty);
      expect(composition.layers, isNotEmpty);
      expect(composition.frameRate, 30);
      expect(composition.images['image_0']?.fileName, 'sticker.png');

      await tester.pumpWidget(
        MaterialApp(
          home: Center(child: Lottie.asset(path, width: 84, height: 84)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(Lottie), findsOneWidget);
    });
  }
}
