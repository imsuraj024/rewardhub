import '../network/api_exception.dart';

/// Converts any exception into a user-friendly message.
///
/// - [NoInternetException]: always shows the "no internet" message
///   (its internal message contains the reason code, not user-friendly)
/// - All other [ApiException] subclasses (including [NetworkException] for
///   timeouts, [ServerException], etc.): use the message set by [ErrorHandler]
/// - Generic exceptions: strip the "Exception: " prefix
String resolveErrorMessage(Object e) {
  if (e is NoInternetException) {
    return 'No internet connection. Please check your connection and try again.';
  }
  if (e is ApiException) return e.message;
  final msg = e.toString();
  if (msg.startsWith('Exception: ')) return msg.substring(11);
  return msg;
}
