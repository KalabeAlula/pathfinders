import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'push_token_registration.g.dart';

/// Keeps this device reachable by cloud push for the signed-in member.
///
/// FlutterFire 17 registers through Firebase Installations and hands back the
/// installation ID, which is what the server sends to. The shell watches this
/// for the whole session; signing out disposes it and removes the row, so the
/// device drops off the old account's delivery list.
@riverpod
Future<void> pushTokenRegistration(Ref ref, String userId) async {
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final messaging = FirebaseMessaging.instance;
  final client = Supabase.instance.client;
  String? registered;

  Future<void> save(String target) async {
    registered = target;
    await client.from('device_push_tokens').upsert({
      'user_id': userId,
      'token': target,
      'platform': Platform.operatingSystem,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,token');
  }

  final refresh = messaging.onRegistered.listen((target) {
    save(target).ignore();
  });
  ref.onDispose(() {
    refresh.cancel();
    final target = registered;
    if (target == null) return;
    client
        .from('device_push_tokens')
        .delete()
        .eq('user_id', userId)
        .eq('token', target)
        .ignore();
  });

  if (Platform.isIOS) {
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  try {
    await messaging.register();
  } catch (_) {
    // The next sign-in or registration refresh retries.
  }
}
