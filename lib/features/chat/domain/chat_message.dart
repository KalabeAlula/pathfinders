import '../../location/domain/geo_point.dart';

enum ChatMessageKind { text, locationShare, destinationUpdate }

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

  bool get hasLocation => latitude != null && longitude != null;

  GeoPoint? get point =>
      hasLocation ? GeoPoint(latitude: latitude!, longitude: longitude!) : null;

  bool get isDestinationUpdate => kind == ChatMessageKind.destinationUpdate;

  String get senderFirstName => senderName.split(' ').first;
}
