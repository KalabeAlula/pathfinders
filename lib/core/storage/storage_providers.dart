import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The process-wide preferences store.
///
/// It is loaded in `main()` and supplied as an override so feature code can
/// read cached state synchronously during provider builds.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError(
    'sharedPreferencesProvider must be overridden in main().',
  ),
);
