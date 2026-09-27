/// RewardHub spacing scale (logical pixels).
///
/// Use these for padding and gaps instead of number literals.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Horizontal page padding on tab screens (Home, Wallet, Profile, FAQ).
  static const double pageGutter = 16;

  /// Horizontal page padding on full-screen flows (auth, maintenance, update).
  static const double authGutter = 24;

  /// Inner padding of standard cards and list tiles.
  static const double cardPadding = 16;

  /// Inner horizontal padding of bottom sheets and dialogs.
  static const double sheetPadding = 24;
}
