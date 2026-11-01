import '../domain/geo_point.dart';
import '../domain/member_status.dart';
import '../domain/privacy_mode.dart';

/// Decodes one `member_status` row into the domain model.
///
/// The row has already been masked by the database, so there is no second
/// masking pass here: a paused row simply arrives without coordinates.
class MemberStatusMapper {
  const MemberStatusMapper._();

  static const Duration onlineWindow = Duration(minutes: 3);

  static MemberStatus fromRow(
    Map<String, dynamic> row, {
    required DateTime now,
  }) {
    final mode = _mode(row['privacy_mode']);
    final latitude = (row['latitude'] as num?)?.toDouble();
    final longitude = (row['longitude'] as num?)?.toDouble();
    final updatedAt = _time(row['updated_at']) ?? now;
    final located =
        mode != PrivacyMode.paused && latitude != null && longitude != null;

    return MemberStatus(
      userId: row['user_id'] as String,
      location: located
          ? GeoPoint(latitude: latitude, longitude: longitude)
          : null,
      batteryPercent: (row['battery_percent'] as num?)?.round(),
      isCharging: row['is_charging'] as bool? ?? false,
      speedKph: (row['speed_kph'] as num?)?.toDouble() ?? 0,
      isOnline: now.difference(updatedAt) <= onlineWindow,
      privacyMode: mode,
      updatedAt: updatedAt,
      arrivedAt: _time(row['arrived_at']),
    );
  }

  static PrivacyMode _mode(Object? value) => switch (value) {
        'approximate' => PrivacyMode.approximate,
        'paused' => PrivacyMode.paused,
        _ => PrivacyMode.exact,
      };

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
