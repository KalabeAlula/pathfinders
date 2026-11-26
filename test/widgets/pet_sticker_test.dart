import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinders/features/pet/domain/ethiopian_pet.dart';
import 'package:pathfinders/features/pet/domain/pet_mood.dart';
import 'package:pathfinders/features/pet/presentation/pet_mood_visuals.dart';
import 'package:pathfinders/features/pet/presentation/widgets/animated_pet_sticker.dart';
import 'package:pathfinders/features/pet/presentation/widgets/pet_avatar.dart';

// Mock Supabase URL for testing (network requests will fail, triggering fallback)
const _mockStickerUrl =
    'https://test.supabase.co/storage/v1/object/public/pet-stickers/fox/idle_1.webp';

Widget _app({
  PetMood mood = PetMood.idle,
  VoidCallback? onTap,
  String? stickerAsset,
  bool ticker = true,
  bool particles = true,
}) {
  return MaterialApp(
    home: Scaffold(
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
  );
}

void main() {
  testWidgets(
    'falls back to the procedural portrait when remote sticker fails to load',
    (tester) async {
      // Using a mock URL that will fail to load, triggering the fallback
      await tester.pumpWidget(_app(stickerAsset: _mockStickerUrl));
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
    },
  );

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
    await tester.pumpWidget(_app(stickerAsset: _mockStickerUrl));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(_app(ticker: false));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PetAvatar), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a failed network sticker keeps the portrait on screen', (
    tester,
  ) async {
    await tester.pumpWidget(_app(stickerAsset: _mockStickerUrl));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(PetAvatar), findsOneWidget);
  });
}
