import '../../location/domain/geo_point.dart';
import 'chat_poll.dart';

enum ChatMessageKind { text, locationShare, destinationUpdate, gif, poll }

/// The message a reply quotes.
///
/// Only the pieces the quote card shows are kept; the body of a location share
/// is empty, so [mediaPreview] carries its place label instead.
class ChatMessageReply {
  const ChatMessageReply({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.text,
    this.mediaPreview,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String? text;
  final String? mediaPreview;

  String get preview => text ?? mediaPreview ?? 'Original message';
}

/// One message in a circle's thread.
///
/// [senderAvatarUrl] is part of the contract but profiles currently carry no
/// photo, so [senderAvatarColor] drives the generated initials avatar.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.kind,
    required this.createdAt,
    this.senderAvatarUrl,
    this.senderAvatarColor = 0xFF6F9E62,
    this.text,
    this.placeLabel,
    this.latitude,
    this.longitude,
    this.gifUrl,
    this.poll,
    this.replyTo,
    this.mentionedUserIds = const [],
    this.editedAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final int senderAvatarColor;
  final ChatMessageKind kind;
  final String? text;
  final String? placeLabel;
  final double? latitude;
  final double? longitude;

  /// Giphy media URL for [ChatMessageKind.gif]; null for a URL the app will
  /// not render.
  final String? gifUrl;

  /// Options and votes for [ChatMessageKind.poll]; [text] carries the
  /// question.
  final ChatPoll? poll;
  final DateTime createdAt;
  final ChatMessageReply? replyTo;

  /// Members tagged with `@` when the message was written.
  final List<String> mentionedUserIds;

  /// Set by the database whenever the body or its mentions change.
  final DateTime? editedAt;

  bool get hasLocation => latitude != null && longitude != null;

  GeoPoint? get point =>
      hasLocation ? GeoPoint(latitude: latitude!, longitude: longitude!) : null;

  bool get isDestinationUpdate => kind == ChatMessageKind.destinationUpdate;

  bool get isGif => kind == ChatMessageKind.gif;

  bool get isPoll => kind == ChatMessageKind.poll;

  bool get isEdited => editedAt != null;

  bool mentions(String userId) => mentionedUserIds.contains(userId);

  /// One-line summary used when this message is quoted in a reply.
  String get quotePreview {
    if (isGif) return 'GIF';
    final body = text;
    if (body != null) return body;
    final place = placeLabel;
    return switch (kind) {
      ChatMessageKind.locationShare =>
        place == null ? 'Shared a location' : 'Shared $place',
      ChatMessageKind.destinationUpdate =>
        place == null
            ? 'Updated the destination'
            : 'Updated the destination to $place',
      ChatMessageKind.poll => 'Vote',
      ChatMessageKind.text || ChatMessageKind.gif => 'Message',
    };
  }

  /// The same message with its poll votes adjusted (an unconfirmed vote).
  ChatMessage withPoll(ChatPoll poll) => ChatMessage(
    id: id,
    senderId: senderId,
    senderName: senderName,
    senderAvatarUrl: senderAvatarUrl,
    senderAvatarColor: senderAvatarColor,
    kind: kind,
    text: text,
    placeLabel: placeLabel,
    latitude: latitude,
    longitude: longitude,
    gifUrl: gifUrl,
    poll: poll,
    replyTo: replyTo,
    mentionedUserIds: mentionedUserIds,
    createdAt: createdAt,
    editedAt: editedAt,
  );

  String get senderFirstName => senderName.split(' ').first;

  /// The quote card a reply to this message shows.
  ChatMessageReply toReply() => ChatMessageReply(
    id: id,
    senderId: senderId,
    senderName: senderName,
    text: quotePreview,
  );
}
