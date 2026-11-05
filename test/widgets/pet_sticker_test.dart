import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:pathfinders/features/pet/domain/ethiopian_pet.dart';
import 'package:pathfinders/features/pet/domain/pet_mood.dart';
import 'package:pathfinders/features/pet/presentation/pet_mood_visuals.dart';
import 'package:pathfinders/features/pet/presentation/widgets/animated_pet_sticker.dart';
import 'package:pathfinders/features/pet/presentation/widgets/pet_avatar.dart';

const _stickerPath = 'assets/pets/lovebird/idle.json';

/// A Lottie file with no layers: enough to prove the engine mounted.
const _fixtureSticker =
    '{"v":"5.7.4","fr":30,"ip":0,"op":60,"w":100,"h":100,'
    '"nm":"fixture","ddd":0,"assets":[],"layers":[]}';

Widget _app({
  PetMood mood = PetMood.idle,
  VoidCallback? onTap,
  String? lottieAsset,
  AssetBundle? bundle,
  bool ticker = true,
}) {
  return MaterialApp(
    home: DefaultAssetBundle(
      bundle: bundle ?? rootBundle,
      child: Scaffold(
        body: Center(
          child: TickerMode(
            enabled: ticker,
            child: AnimatedPetSticker(
              pet: EthiopianPet.lovebird,
              mood: mood,
              onTap: onTap,
              lottieAsset: lottieAsset,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('falls back to the procedural portrait when no art ships', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PetAvatar), findsOneWidget);
    expect(find.byType(Lottie), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                '${EthiopianPet.lovebird.commonName}, ${PetMood.idle.label}',
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
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('a hidden sticker stops scheduling frames', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(_app(ticker: false));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a broken sticker file keeps the portrait on screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(lottieAsset: _stickerPath, bundle: _FakeBundle(const {})),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(PetAvatar), findsOneWidget);
  });

  testWidgets('a shipped sticker file replaces the portrait', (tester) async {
    await tester.pumpWidget(
      _app(
        lottieAsset: _stickerPath,
        bundle: _FakeBundle(const {_stickerPath: _fixtureSticker}),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(Lottie), findsOneWidget);
  });
}

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) {
    final asset = assets[key];
    if (asset != null) {
      final bytes = Uint8List.fromList(utf8.encode(asset));
      return Future.value(ByteData.view(bytes.buffer));
    }
    // Everything else (avatars, manifests) still comes from the app bundle.
    return rootBundle.load(key);
  }
}
