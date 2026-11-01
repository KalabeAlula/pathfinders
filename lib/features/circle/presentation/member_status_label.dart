import '../../../core/utils/time_format.dart';
import '../../location/domain/member_status.dart';
import '../domain/circle_member.dart';

/// One-line status copy for presence tiles and sheets.
String describeMemberStatus(CircleMember member, DateTime now) {
  final status = member.status;
  if (status == null) return 'No updates yet';
  if (!status.isOnline) {
    return 'Offline · ${timeAgo(status.updatedAt, now: now)}';
  }
  if (status.isPaused) return 'Location paused';
  final dwell = status.dwellTime(now);
  if (status.isMoving) return 'Moving · ${status.speedKph.round()} km/h';
  if (status.isApproximate) return 'Nearby · approximate';
  if (dwell != null) {
    return dwell.inMinutes < 1
        ? 'Just stopped'
        : 'Stopped · ${formatDwell(dwell)}';
  }
  return 'Location shared';
}

/// Richer description used inside the member sheet.
String describeMemberLocation(MemberStatus? status, DateTime now) {
  if (status == null) return 'Waiting for the first update';
  if (status.isPaused) return 'Location paused';
  if (!status.isOnline) {
    return 'Last seen ${timeAgo(status.updatedAt, now: now)}';
  }
  final dwell = status.dwellTime(now);
  if (status.isMoving) return 'Moving at ${status.speedKph.round()} km/h';
  if (status.isApproximate) return 'Sharing an approximate area';
  if (dwell != null) {
    return dwell.inMinutes < 1
        ? 'Just stopped'
        : 'Stopped for ${formatDwell(dwell)}';
  }
  return 'Sharing live location';
}
