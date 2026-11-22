import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Client configuration for the `pathfinders-dce0b` **web** app, plus the
/// public Web Push certificate that lets the browser obtain an FCM token.
///
/// These values are public identifiers, not credentials: they ship inside the
/// page bundle. The VAPID key is the public half of the pair Firebase console
/// generates under Cloud Messaging → Web Push certificates.
///
/// Until Chrome has that certificate the browser keeps the realtime-only
/// behaviour: chat arrives over the live socket and no push is registered.
abstract final class FirebaseWebConfig {
  static const apiKey = 'AIzaSyAPtj1N8--gVdZac2jtjgtTOxQU0FkLh1Y';
  static const appId = '1:163106016796:web:5841354936e81fcacfd9d9';
  static const authDomain = 'pathfinders-dce0b.firebaseapp.com';
  static const projectId = 'pathfinders-dce0b';
  static const storageBucket = 'pathfinders-dce0b.firebasestorage.app';
  static const messagingSenderId = '163106016796';
  static const vapidKey =
      'BAOYPF-Hkwpi1eGVvdhkzwOESgy53t08rShLyz3u5VK6hA5yV5y8VOs1oauU8x8L6GLO-7kOjNIiCwcYr5OOfi8';

  static bool get isConfigured =>
      apiKey.isNotEmpty && appId.isNotEmpty && vapidKey.isNotEmpty;

  static FirebaseOptions get options => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    authDomain: authDomain,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );
}
