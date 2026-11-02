import '../domain/geo_point.dart';
import '../domain/member_status.dart';
import '../domain/privacy_mode.dart';

/// Decodes one `member_status` row into the domain model.
///
/// The row has already been masked by the database, so there is no second
/// masking pass here: a paused row simply arrives without coordinates.
class MemberStatusMapper {
  const MemberStatusMapper._();

  static final RegExp _timezoneSuffix = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

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
      speedKph: _speed(row['speed_kph']),
      isOnline:
          now.toUtc().difference(updatedAt.toUtc()) <=
          MemberStatus.onlineWindow,
      privacyMode: mode,
      updatedAt: updatedAt,
      arrivedAt: _time(row['arrived_at']),
    );
  }

  /// Rows written before the device-side deadband can carry jitter, so the
  /// same threshold is applied on the way in.
  static double _speed(Object? value) {
    final speed = (value as num?)?.toDouble() ?? 0;
    return speed >= MemberStatus.movingThresholdKph ? speed : 0;
  }

  static PrivacyMode _mode(Object? value) => switch (value) {
    'approximate' => PrivacyMode.approximate,
    'paused' => PrivacyMode.paused,
    _ => PrivacyMode.exact,
  };

  static DateTime? _time(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    // A timestamp without an offset is UTC from PostgREST. Reading it as local
    // time would shift it by hours and make an active member look offline.
    final normalized = _timezoneSuffix.hasMatch(text) ? text : '${text}Z';
    return DateTime.tryParse(normalized)?.toLocal();
  }
}
