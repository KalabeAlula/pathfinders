import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

/// Client configuration for the `pathfinders-dce0b` Firebase project.
///
/// These values are public identifiers, not credentials: the API keys are
/// restricted to the app's package name and bundle ID.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Pathfinders does not ship on ${defaultTargetPlatform.name}.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsgIXLdE2a7-Nh5rHKwLEumO4REZfquRI',
    appId: '1:163106016796:android:74461de1d9163621cfd9d9',
    messagingSenderId: '163106016796',
    projectId: 'pathfinders-dce0b',
    storageBucket: 'pathfinders-dce0b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDsSrjuMOkzVtygzQ_a0mtQLSW0gy8bnW8',
    appId: '1:163106016796:ios:c986a1ecd30c27c0cfd9d9',
    messagingSenderId: '163106016796',
    projectId: 'pathfinders-dce0b',
    storageBucket: 'pathfinders-dce0b.firebasestorage.app',
    iosBundleId: 'com.pathfinders.pathfinders',
  );
}
