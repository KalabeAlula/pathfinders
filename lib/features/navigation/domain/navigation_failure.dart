/// A failed navigation action, already translated into copy for the UI.
class NavigationFailure implements Exception {
  const NavigationFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
