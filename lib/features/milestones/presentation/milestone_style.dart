import 'package:flutter/material.dart';

import '../domain/shared_milestone.dart';

extension MilestoneKindStyle on MilestoneKind {
  String get label => switch (this) {
    MilestoneKind.birthday => 'Birthday',
    MilestoneKind.anniversary => 'Milestone',
    MilestoneKind.trip => 'Trip',
    MilestoneKind.goal => 'Goal',
  };

  IconData get icon => switch (this) {
    MilestoneKind.birthday => Icons.cake_rounded,
    MilestoneKind.anniversary => Icons.favorite_rounded,
    MilestoneKind.trip => Icons.luggage_rounded,
    MilestoneKind.goal => Icons.flag_rounded,
  };

  List<Color> get colors => switch (this) {
    MilestoneKind.birthday => const [Color(0xFFB86B4F), Color(0xFF8F4B36)],
    MilestoneKind.anniversary => const [Color(0xFF8D6F88), Color(0xFF5E4659)],
    MilestoneKind.trip => const [Color(0xFF7C8C6B), Color(0xFF56654A)],
    MilestoneKind.goal => const [Color(0xFFC7974C), Color(0xFF8E6A2F)],
  };
}
