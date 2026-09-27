import '../network/api_exception.dart';
import '../network/error_messages.dart';

/// Converts any exception into a user-friendly message.
///
/// - [NoInternetException]: always shows the "offline" message
///   (its internal message contains the reason code, not user-friendly)
/// - All other [ApiException] subclasses (including [NetworkException] for
///   timeouts, [ServerException], etc.): use the message set by [ErrorHandler],
///   or the generic message when it is blank
/// - Anything else: the generic message. Every app-thrown error is an
///   [ApiException], so raw exception text never reaches the user.
String resolveErrorMessage(Object e) {
  if (e is NoInternetException) return ErrorMessages.offline;
  if (e is ApiException) {
    return e.message.trim().isEmpty ? ErrorMessages.generic : e.message;
  }
  return ErrorMessages.generic;
}
