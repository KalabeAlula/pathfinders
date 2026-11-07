import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/mapbox_config.dart';
import 'core/config/supabase_config.dart';
import 'core/firebase/firebase_options.dart';
import 'core/storage/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Thumbnails decode at display size, so a lean cache is enough and keeps
  // low-end devices away from the 100 MB default budget.
  PaintingBinding.instance.imageCache
    ..maximumSize = 200
    ..maximumSizeBytes = 64 * 1024 * 1024;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    // Chat notifications depend on realtime events arriving while the app is
    // minimized. The default closes the socket on pause, but the location
    // foreground service keeps this process alive, so the socket is left to
    // the OS and reconnects on its own if it is closed.
    realtimeLifecycleOptions: const RealtimeLifecycleOptions.manual(),
  );
  if (MapboxConfig.isConfigured) {
    MapboxOptions.setAccessToken(MapboxConfig.accessToken);
  }
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const PathfindersApp(),
    ),
  );
}
