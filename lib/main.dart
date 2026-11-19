import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/config/mapbox_config.dart';
import 'core/config/supabase_config.dart';
import 'core/firebase/firebase_options.dart';
import 'core/storage/storage_providers.dart';
import 'features/chat/data/chat_push_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Thumbnails decode at display size, so a lean cache is enough and keeps
  // low-end devices away from the 100 MB default budget.
  PaintingBinding.instance.imageCache
    ..maximumSize = 200
    ..maximumSizeBytes = 64 * 1024 * 1024;
  runApp(const BootGate());
}

/// Renders the launch splash first, then the app once initialization finishes,
/// so the pre-runApp waits overlap the first frame instead of delaying it.
class BootGate extends StatefulWidget {
  const BootGate({super.key});

  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> {
  SharedPreferences? _preferences;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final supabaseReady = Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      // Chat notifications depend on realtime events arriving while the app is
      // minimized. The default closes the socket on pause, but the location
      // foreground service keeps this process alive, so the socket is left to
      // the OS and reconnects on its own if it is closed.
      realtimeLifecycleOptions: const RealtimeLifecycleOptions.manual(),
    );
    final preferencesReady = SharedPreferences.getInstance();
    // The three initializations are independent, so they run together and the
    // wait is the slowest one instead of their sum.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Chat pushes are data-only, so the app renders the notification itself.
    // Registering the handler early is what lets a push that wakes a stopped
    // process be handled instead of dropped.
    FirebaseMessaging.onBackgroundMessage(chatPushHandler);
    await supabaseReady;
    if (MapboxConfig.isConfigured) {
      MapboxOptions.setAccessToken(MapboxConfig.accessToken);
    }
    final preferences = await preferencesReady;
    if (!mounted) return;
    setState(() => _preferences = preferences);
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    if (preferences != null) {
      return ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const PathfindersApp(),
      );
    }
    return MaterialApp(
      title: 'Pathfinders',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _BootSplash(),
    );
  }
}

/// Mirrors android's launch_background so the static splash hands off without
/// a flash: same surface colour, same centred brand mark.
class _BootSplash extends StatelessWidget {
  const _BootSplash();

  static const _logoSize = 96.0;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/branding/app_icon.png',
          width: _logoSize,
          height: _logoSize,
          cacheWidth: (_logoSize * dpr).round(),
          semanticLabel: 'Pathfinders',
        ),
      ),
    );
  }
}
