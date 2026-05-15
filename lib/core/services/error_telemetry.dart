import 'package:flutter/foundation.dart';

/// Lightweight error reporting stub.
///
/// Sentry is temporarily disabled because its transitive dependency
/// `objective_c` fails to compile on Windows paths that contain spaces.
/// Re-enable once the upstream Flutter toolchain resolves path quoting.
class ErrorTelemetry {
  const ErrorTelemetry._();

  static Future<void> captureException(
    Object exception,
    StackTrace stackTrace, {
    String? operation,
    Map<String, Object?> extras = const {},
  }) async {
    // Light stub to print exceptions to debug console instead of Sentry
    debugPrint('[ErrorTelemetry] Exception captured');
    if (operation != null) {
      debugPrint('Operation: $operation');
    }
    debugPrint('Exception: $exception');
    if (extras.isNotEmpty) {
      debugPrint('Context Extras: $extras');
    }
  }
}
