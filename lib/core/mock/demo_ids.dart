/// Stable identifiers for the seeded demo world.
///
/// When the real backend lands these are replaced by authenticated ids; keeping
/// them in one place stops the mock data in different features from drifting.
abstract final class DemoIds {
  static const String kaleab = 'user_kaleab';
  static const String hana = 'user_hana';
  static const String dani = 'user_dani';
  static const String sofi = 'user_sofi';

  static const String circle = 'circle_bole_crew';

  static const List<String> memberIds = [kaleab, hana, dani, sofi];
}
