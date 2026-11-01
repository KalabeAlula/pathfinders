class TelemetryFailure implements Exception {
  const TelemetryFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
