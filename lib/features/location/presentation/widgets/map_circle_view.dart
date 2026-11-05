import 'package:flutter/material.dart';

import '../../../circle/domain/circle_member.dart';
import '../../../navigation/application/navigation_state.dart';
import '../../../profile/domain/animal_avatar.dart';
import 'mapbox_live_annotations.dart';

const _peerRouteColors = <Color>[
  Color(0xFF3F6FA8),
  Color(0xFF6F9E62),
  Color(0xFF8C5BA8),
  Color(0xFFC7974C),
  Color(0xFF4A9A9A),
];

/// The accent each member's route and pin uses.
///
/// The local user always takes [ColorScheme.primary]; peers cycle through a
/// fixed palette in a stable order so colors do not shuffle between rebuilds.
Map<String, Color> routeAccentColors({
  required List<CircleMember> members,
  required String currentUserId,
  required ColorScheme scheme,
}) {
  final peerIds = [
    for (final member in members)
      if (member.profile.id != currentUserId) member.profile.id,
  ]..sort();

  return {
    for (final member in members)
      member.profile.id: member.profile.id == currentUserId
          ? scheme.primary
          : _peerRouteColors[peerIds.indexOf(member.profile.id) %
                _peerRouteColors.length],
  };
}

/// Maps the circle snapshot and navigation state onto everything the map
/// draws, so the dashboard preview and the full picker stay identical.
class MapCircleView {
  const MapCircleView({
    required this.pins,
    required this.lines,
    required this.routes,
    required this.colors,
    required this.locatedCount,
    required this.pausedCount,
  });

  final List<MapMemberPin> pins;
  final List<MapRouteLine> lines;
  final List<({CircleMember member, MemberRoute route})> routes;
  final Map<String, Color> colors;
  final int locatedCount;
  final int pausedCount;

  factory MapCircleView.from({
    required List<CircleMember> members,
    required String currentUserId,
    required NavigationState navigation,
    required ColorScheme scheme,
  }) {
    final located = members
        .where((member) => member.status?.location != null)
        .toList(growable: false);

    final colors = routeAccentColors(
      members: members,
      currentUserId: currentUserId,
      scheme: scheme,
    );

    final routes =
        [
          for (final member in members)
            if (navigation.routeFor(member.profile.id) case final route?)
              (member: member, route: route),
        ]..sort(
          (a, b) => a.member.profile.id == currentUserId
              ? 1
              : b.member.profile.id == currentUserId
              ? -1
              : 0,
        );

    return MapCircleView(
      pins: [
        for (final member in located)
          MapMemberPin(
            id: member.profile.id,
            initials: member.profile.initials,
            avatarId: AnimalAvatar.byId(member.profile.avatarId).id,
            latitude: member.status!.location!.latitude,
            longitude: member.status!.location!.longitude,
            accent: colors[member.profile.id]!,
            background: scheme.surfaceContainerLowest,
            approximate: member.status!.isApproximate,
            isCurrentUser: member.profile.id == currentUserId,
          ),
      ],
      lines: [
        for (final entry in routes)
          MapRouteLine(
            memberId: entry.member.profile.id,
            points: entry.route.plan.geometry,
            color: colors[entry.member.profile.id]!,
            width: entry.member.profile.id == currentUserId ? 6 : 4,
            borderWidth: entry.member.profile.id == currentUserId ? 1.2 : 1,
          ),
      ],
      routes: routes,
      colors: colors,
      locatedCount: located.length,
      pausedCount: members
          .where((member) => member.status?.isPaused ?? false)
          .length,
    );
  }
}
