/// Public Supabase connection settings.
///
/// Both values are safe to ship: the URL is public and the key is a
/// publishable client key, so every rule is enforced by RLS and the RPCs in
/// `supabase/migrations`. Override per build with
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ijqweyrwyfmtkfsscarg.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_IkZDpZzyFCZsmo4BxEq3CA_st2bhO2j',
  );
}
