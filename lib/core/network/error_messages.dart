/// User-facing error copy shared by the network layer and every feature.
///
/// Server messages still reach the user unchanged; these are the fallbacks
/// for transport failures and for errors the server didn't explain.
abstract final class ErrorMessages {
  static const String timeout =
      'This is taking too long. Check your internet and try again.';
  static const String offline =
      "You're offline. Check your internet and try again.";
  static const String cannotConnect =
      "Couldn't connect. Check your internet and try again.";
  static const String insecureConnection =
      "Couldn't connect safely. Check your internet and try again.";
  static const String cancelled = "That didn't finish. Please try again.";
  static const String generic =
      "Something's wrong on our side. Please try again in a few minutes.";
  static const String invalidInput = 'Please check your details and try again.';
  static const String sessionExpired =
      "You've been logged out. Please log in again.";
}
