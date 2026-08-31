import 'dart:developer' as developer;

/// Centralized logging utility wrapping [dart:developer.log].
///
/// All features should use this instead of calling [developer.log] directly,
/// so log output is consistently tagged with the app name.
void log(
  String message, {
  String name = 'rewardhub',
  Object? error,
  StackTrace? stackTrace,
}) {
  developer.log(
    message,
    name: name,
    error: error,
    stackTrace: stackTrace,
  );
}