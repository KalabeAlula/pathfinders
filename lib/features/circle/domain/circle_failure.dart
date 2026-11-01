/// A failed circle action, already translated into copy for the UI.
class CircleFailure implements Exception {
  const CircleFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
