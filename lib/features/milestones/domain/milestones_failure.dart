/// A failed milestone action, already translated into copy for the UI.
class MilestonesFailure implements Exception {
  const MilestonesFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
