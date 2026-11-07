import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/firebase/firebase_options.dart';
import '../domain/chat_notification.dart';
import 'local_chat_notifier.dart';

/// Posts the push that `notify-chat` sent for a new message.
///
/// Registered in `main()` as the background handler, so it runs in Firebase's
/// background isolate while the app is away — or when the push is what starts
/// the process. Payloads are data-only, which keeps grouping, the channel and
/// tap routing in the app's hands.
@pragma('vm:entry-point')
Future<void> chatPushHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  final data = message.data;
  final circleId = data['circle_id'];
  final messageId = data['message_id'];
  final title = data['title'];
  final body = data['body'];
  if (circleId is! String ||
      messageId is! String ||
      title is! String ||
      body is! String) {
    return;
  }

  // The plugin and its channels belong to the isolate that posts, so the
  // background engine initialises its own copy.
  final preferences = await SharedPreferences.getInstance();
  await LocalChatNotifier(preferences).show(
    ChatNotification.fromPush(
      messageId: messageId,
      circleId: circleId,
      senderName: data['sender_name'] as String? ?? '',
      title: title,
      body: body,
    ),
    circleName: data['circle_name'] as String? ?? 'Circle',
  );
}
