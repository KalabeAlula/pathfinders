import '../../location/domain/member_status.dart';
import 'user_profile.dart';

class CircleMember {
  const CircleMember({required this.profile, required this.status});

  final UserProfile profile;
  final MemberStatus? status;
}
