import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../domain/circle_member.dart';
import 'member_card.dart';

class MemberPresenceHeader extends StatelessWidget {
  const MemberPresenceHeader({
    super.key,
    required this.members,
    required this.currentUserId,
    required this.now,
    required this.onMemberTap,
  });

  final List<CircleMember> members;
  final String currentUserId;
  final DateTime now;
  final ValueChanged<CircleMember> onMemberTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final member = members[index];
          return MemberCard(
            member: member,
            isCurrentUser: member.profile.id == currentUserId,
            now: now,
            onTap: () => onMemberTap(member),
          );
        },
      ),
    );
  }
}
