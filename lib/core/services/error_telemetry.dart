import 'package:sentry_flutter/sentry_flutter.dart';

class ErrorTelemetry {
  const ErrorTelemetry._();

  static Future<void> captureException(
    Object exception,
    StackTrace stackTrace, {
    String? operation,
    Map<String, Object?> extras = const {},
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (operation != null && operation.isNotEmpty) {
          scope.transaction = operation;
        }
        if (extras.isNotEmpty) {
          scope.setContexts('auth', extras);
        }
      },
    );
  }
}
