import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../circle/domain/circle_member.dart';
import '../../circle/domain/circle_snapshot.dart';
import '../application/nudge_providers.dart';
import '../domain/nudge.dart';
import '../domain/nudge_repository.dart';
import 'widgets/warmth_picker.dart';

Future<void> sendWarmth(
  BuildContext context,
  WidgetRef ref, {
  required CircleSnapshot snapshot,
  required String currentUserId,
  required CircleMember member,
  required NudgeWarmth warmth,
}) async {
  final senderName =
      snapshot.memberById(currentUserId)?.profile.firstName ?? 'Someone';
  try {
    await ref
        .read(nudgeControllerProvider(snapshot.circle.id, currentUserId).notifier)
        .send(
          senderId: currentUserId,
          senderName: senderName,
          targetId: member.profile.id,
          targetName: member.profile.firstName,
          warmth: warmth,
        );
  } on NudgeFailure catch (failure) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not send that warmth. Try again.')),
    );
  }
}

Future<void> pickWarmth(
  BuildContext context,
  WidgetRef ref, {
  required CircleSnapshot snapshot,
  required String currentUserId,
  required CircleMember member,
}) async {
  final choice = await showWarmthPicker(
    context,
    type: snapshot.circle.type,
    memberName: member.profile.firstName,
  );
  if (choice == null || !context.mounted) return;
  await sendWarmth(
    context,
    ref,
    snapshot: snapshot,
    currentUserId: currentUserId,
    member: member,
    warmth: choice,
  );
}

String warmthBannerMessage(NudgePing ping, String currentUserId) {
  if (ping.fromUserId != currentUserId) return ping.message;
  final target = ping.targetName ?? 'them';
  return 'You sent $target a ${ping.warmth.label.toLowerCase()} ${ping.warmth.emoji}';
}
