import '../../location/domain/geo_point.dart';

/// One choice on a poll. [voterIds] holds every member who picked it.
class ChatPollOption {
  const ChatPollOption({
    required this.id,
    required this.position,
    required this.label,
    this.latitude,
    this.longitude,
    this.placeLabel,
    this.voterIds = const [],
  });

  final String id;
  final int position;
  final String label;
  final double? latitude;
  final double? longitude;
  final String? placeLabel;
  final List<String> voterIds;

  bool get hasPlace => latitude != null && longitude != null;

  GeoPoint? get point =>
      hasPlace ? GeoPoint(latitude: latitude!, longitude: longitude!) : null;

  ChatPollOption withVoters(List<String> voterIds) => ChatPollOption(
    id: id,
    position: position,
    label: label,
    latitude: latitude,
    longitude: longitude,
    placeLabel: placeLabel,
    voterIds: voterIds,
  );
}

/// A vote posted in the thread, e.g. where the crew should head next.
class ChatPoll {
  const ChatPoll({required this.options});

  final List<ChatPollOption> options;

  int get totalVotes =>
      options.fold(0, (sum, option) => sum + option.voterIds.length);

  /// The most-voted option, or null when nobody voted or the lead is shared.
  ChatPollOption? get leader {
    ChatPollOption? best;
    var tied = false;
    for (final option in options) {
      final votes = option.voterIds.length;
      if (votes == 0) continue;
      if (best == null || votes > best.voterIds.length) {
        best = option;
        tied = false;
      } else if (votes == best.voterIds.length) {
        tied = true;
      }
    }
    return tied ? null : best;
  }

  String? votedOptionId(String userId) {
    for (final option in options) {
      if (option.voterIds.contains(userId)) return option.id;
    }
    return null;
  }

  /// The poll as it looks when [userId] has chosen [optionId]; null clears.
  ChatPoll withVote({required String userId, required String? optionId}) =>
      ChatPoll(
        options: [
          for (final option in options)
            option.withVoters([
              for (final voter in option.voterIds)
                if (voter != userId) voter,
              if (option.id == optionId) userId,
            ]),
        ],
      );
}

/// An option being composed before the poll is posted.
class ChatPollDraftOption {
  const ChatPollDraftOption({
    required this.label,
    this.latitude,
    this.longitude,
    this.placeLabel,
  });

  final String label;
  final double? latitude;
  final double? longitude;
  final String? placeLabel;
}
