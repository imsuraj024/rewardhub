/// App-wide brand strings.
///
/// The product name lives here as a single constant rather than as an ARB
/// entry: a brand name is never translated, and keeping it in two places (a
/// literal per screen *plus* an l10n key) is exactly what let the launcher
/// label drift away from the in-app copy.
///
/// Anything the user can read should reference these constants. The Dart
/// package (`rewardhub`), the bundle identifiers (`com.loyalty.rewardhub`) and
/// the Firebase project (`kitox-hardware`) deliberately keep their own names —
/// they are tied to live infrastructure and are never shown to the user. See
/// README.md.
///
/// The native launcher/display names cannot read Dart, so they are duplicated
/// in `android/app/src/main/AndroidManifest.xml` (`android:label`),
/// `ios/Runner/Info.plist` (`CFBundleDisplayName` / `CFBundleName`) and
/// `web/manifest.json`. Update those alongside this file.
abstract final class AppStrings {
  /// The user-facing product name.
  static const String productName = 'Kitox Hardware';

  /// [productName] for all-caps treatments (splash footer, version footer).
  static const String productNameUpper = 'KITOX HARDWARE';
}
