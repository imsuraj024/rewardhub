# Kitox Hardware

The Kitox Hardware rewards app. Customers scan the QR code on a Kitox Hardware
receipt or a partner storefront, earn points, and redeem them to UPI or a bank
account.

> The Dart package (`rewardhub`), the bundle identifiers
> (`com.loyalty.rewardhub`) and the Firebase project (`kitox-hardware`) keep
> their existing names — they are tied to live infrastructure and store listings
> and are never shown to the user. "Kitox Hardware" is the product name
> everywhere the user *can* see it.

## Stack

- Flutter 3.38 / Dart 3.10, GetX for routing, DI and state
- Clean-architecture feature slices under `lib/features/<feature>/{data,domain,presentation}`
- Dio for HTTP (`lib/core/network`), Firebase Core, Shorebird for code push
- Auth token in the iOS Keychain / Android Keystore via `flutter_secure_storage`
  (`lib/core/storage/secure_token_store.dart`)

## Getting started

```sh
fvm flutter pub get
fvm flutter gen-l10n          # regenerate lib/l10n from lib/l10n/app_en.arb
fvm flutter run
```

To run with the in-app network inspector (debug builds only):

```sh
fvm flutter run --dart-define=alice=true
```

## Code generation

JSON models use `json_serializable`. After editing a `*_model.dart`:

```sh
fvm dart run build_runner build --delete-conflicting-outputs
```

## Release builds

Release signing requires `android/key.properties` and the upload keystore; both
are untracked, and the Gradle config fails the build rather than falling back to
debug keys. See the error message in `android/app/build.gradle.kts` for the
expected contents.

```sh
fvm flutter build appbundle --release
fvm flutter build ipa --release
```
