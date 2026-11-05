import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/application/app_visibility.dart';
import '../features/auth/presentation/session_gate.dart';
import 'theme/app_theme.dart';

class PathfindersApp extends ConsumerStatefulWidget {
  const PathfindersApp({super.key});

  @override
  ConsumerState<PathfindersApp> createState() => _PathfindersAppState();
}

class _PathfindersAppState extends ConsumerState<PathfindersApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appVisibilityProvider).update(state);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathfinders',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final iconBrightness = isDark ? Brightness.light : Brightness.dark;
        final visibility = ref.watch(appVisibilityProvider);
        return AnimatedBuilder(
          animation: visibility,
          // A minimized app keeps no ticker running, so animations cost nothing
          // in the background.
          builder: (context, overlay) => TickerMode(
            enabled: visibility.isForeground,
            child: overlay!,
          ),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: iconBrightness,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarIconBrightness: iconBrightness,
              systemNavigationBarContrastEnforced: false,
            ),
            child: child!,
          ),
        );
      },
      home: const SessionGate(),
    );
  }
}
