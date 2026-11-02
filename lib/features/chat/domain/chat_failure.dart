class ChatFailure implements Exception {
  const ChatFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
