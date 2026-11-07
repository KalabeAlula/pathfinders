import '../../location/domain/geo_point.dart';

enum ChatMessageKind { text, locationShare, destinationUpdate }

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

  bool get isEdited => editedAt != null;

  bool mentions(String userId) => mentionedUserIds.contains(userId);

  String get senderFirstName => senderName.split(' ').first;
}
