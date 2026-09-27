/// RewardHub corner-radius scale (logical pixels).
///
/// Cards use [lg] (list and info cards) or [xl] (hero and section cards).
abstract final class AppRadius {
  /// Checkbox.
  static const double xs = 4;

  /// Chips, small badges, logo frame.
  static const double sm = 8;

  /// Buttons, inputs, OTP boxes, md/sm icon badges.
  static const double md = 12;

  /// List cards, tiles, upload slots, lg icon badges, toasts.
  static const double lg = 16;

  /// Hero cards, main cards, auth card, dialogs.
  static const double xl = 24;

  /// Bottom sheet top corners.
  static const double sheet = 28;

  static const double pill = 999;
}
