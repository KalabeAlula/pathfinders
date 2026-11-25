import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/pet/domain/ethiopian_pet.dart';
import 'package:pathfinders/features/pet/domain/pet_mood.dart';
import 'package:pathfinders/features/pet/presentation/pet_mood_visuals.dart';
import 'package:pathfinders/features/pet/presentation/widgets/animated_pet_sticker.dart';
import 'package:pathfinders/features/pet/presentation/widgets/pet_avatar.dart';

const _stickerPath = 'assets/pets/fox/idle_1.webp';

// 1x1 transparent PNG bytes for testing the image sticker slot.
final _transparentPngBytes = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

Widget _app({
  PetMood mood = PetMood.idle,
  VoidCallback? onTap,
  String? stickerAsset,
  AssetBundle? bundle,
  bool ticker = true,
  bool particles = true,
}) {
  return MaterialApp(
    home: DefaultAssetBundle(
      bundle: bundle ?? rootBundle,
      child: Scaffold(
        body: Center(
          child: TickerMode(
            enabled: ticker,
            child: AnimatedPetSticker(
              pet: EthiopianPet.fox,
              mood: mood,
              onTap: onTap,
              stickerAsset: stickerAsset,
              showParticles: particles,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('falls back to the procedural portrait when art fails to load', (
    tester,
  ) async {
    await tester.pumpWidget(_app(stickerAsset: 'assets/pets/missing.webp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PetAvatar), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                '${EthiopianPet.fox.commonName}, ${PetMood.idle.label}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a tap haptics, lifts a heart, and runs the callback', (
    tester,
  ) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    var taps = 0;
    await tester.pumpWidget(_app(onTap: () => taps++));
    await tester.pump();

    await tester.tap(find.byType(AnimatedPetSticker));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(taps, 1);
    expect(haptics, ['HapticFeedbackType.mediumImpact']);
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);

    // Pump past the speech bubble timer (1.4s) to avoid pending timer error.
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('arriving in a trip bursts hearts without a tap', (tester) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_app(mood: PetMood.traveling, particles: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);

    await tester.pumpWidget(_app(mood: PetMood.celebrating, particles: false));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
    expect(haptics, isEmpty);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('a sticker born in a celebration bursts once, then settles', (
    tester,
  ) async {
    await tester.pumpWidget(_app(mood: PetMood.celebrating, particles: false));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);

    // A rebuild while still celebrating is not a new arrival.
    await tester.pumpWidget(_app(mood: PetMood.celebrating, particles: false));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('a hidden sticker pauses to static portrait and stops frames', (
    tester,
  ) async {
    await tester.pumpWidget(_app(stickerAsset: 'assets/pets/missing.webp'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(_app(ticker: false));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PetAvatar), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a broken sticker file keeps the portrait on screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        stickerAsset: _stickerPath,
        bundle: _FakeBundle({
          _stickerPath: Uint8List.fromList([1, 2, 3, 4]),
        }),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(PetAvatar), findsOneWidget);
  });

  testWidgets('a shipped sticker file replaces the portrait', (tester) async {
    await tester.pumpWidget(
      _app(
        stickerAsset: _stickerPath,
        bundle: _FakeBundle({_stickerPath: _transparentPngBytes}),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);
  });
}

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.assets);

  final Map<String, Uint8List> assets;

  @override
  Future<ByteData> load(String key) {
    final asset = assets[key];
    if (asset != null) {
      return Future.value(ByteData.view(asset.buffer));
    }
    return rootBundle.load(key);
  }
}
