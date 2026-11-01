/// A failed memory action, already translated into copy for the UI.
class MemoriesFailure implements Exception {
  const MemoriesFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
