# Project Context: Kitox Hardware (RewardHub)

> **Authoritative Context Document for LLMs & AI Coding Agents**  
> *This document provides full functional specs, architectural layout, state management patterns, and UI/UX design tokens for the Kitox Hardware rewards app.*

---

## 1. Executive Summary & Product Identity

- **Product Name**: **Kitox Hardware**
- **Internal / Package Name**: `rewardhub` (`com.loyalty.rewardhub`)
- **Primary Objective**: Hardware loyalty and rewards application. Customers scan QR codes on Kitox Hardware receipts or partner product packaging, accumulate reward points, and cash out points to UPI or direct bank accounts.
- **Target Platforms**: Mobile (iOS & Android)
- **Primary Tech Stack**: Flutter 3.38+, Dart 3.10+, GetX (State Management & DI), Dio (Networking), Shorebird (Code Push), Firebase (Core, Remote Config, FCM, Analytics, Crashlytics).

---

## 2. Architectural Blueprint & Directory Layout

The app adheres strictly to **Clean Architecture** (Feature-sliced MVVM with three distinct layers per feature) combined with a global `core` layer.

```
lib/
├── core/                         # Cross-cutting concerns & shared infrastructure
│   ├── analytics/                # AppAnalytics facade & FirebaseAnalytics service
│   ├── bindings/                 # Global dependencies (InitialBinding)
│   ├── constants/                # AppStrings, Asset paths, configuration constants
│   ├── models/                   # Global models (BannerModel, etc.)
│   ├── network/                  # ApiClient (Dio), Interceptors, Exception & ErrorHandler
│   ├── routes/                   # AppRoutes (named route constants) & AppPages (GetPage configuration)
│   ├── services/                 # ConnectivityService, RemoteConfigService, PushNotificationService, ShorebirdService
│   ├── storage/                  # SecureTokenStore (iOS Keychain / Android Keystore)
│   ├── theme/                    # AppColors, AppTextStyles, AppTheme
│   ├── usecase/                  # Base UseCase contract interface
│   ├── utils/                    # AppToast, ViewState, Formatters, Validators
│   └── widgets/                  # AppButton, AppTopBar, AppBanner, ConnectivityWidget, Skeleton
│
├── features/                     # Feature Slices (Clean Architecture)
│   ├── app_update/               # Forced application update & patch notification view
│   ├── auth/                     # Login, Registration (Personal, Account, KYC), OTP Verification
│   ├── catalogue/                # Reward items catalogue, details & search
│   ├── faq/                      # Frequently Asked Questions & Help Center
│   ├── home/                     # Dashboard view (Banners, Points Card, Quick Actions, Recent Activity)
│   ├── maintenance/              # App maintenance overlay driven by Remote Config
│   ├── profile/                  # User profile, KYC status, Referral Code display & sharing
│   ├── qr_scan/                  # QR Code Scanner with custom cutout, torch toggle, and API submission
│   ├── shell/                    # Main shell container holding persistent bottom navigation
│   ├── splash/                   # App launch screen & initialization check
│   └── wallet/                   # Points wallet, UPI/Bank account redemption & transaction history
│
├── l10n/                         # Localization ARB files (app_en.arb) & generated code
└── main.dart                     # App entry point & initialization sequence
```

### Layer Separation Rules
1. **Presentation Layer** (`features/<feature>/presentation/`): Contains Views (`GetView`), Controllers (`GetxController`), Bindings (`Bindings`), and Feature Widgets. Depends **only** on the Domain Layer.
2. **Domain Layer** (`features/<feature>/domain/`): Contains Entities, Use Cases (`UseCase<Type, Params>`), and Repository Interfaces. Pure Dart code with zero UI or framework dependencies.
3. **Data Layer** (`features/<feature>/data/`): Contains Data Sources (Remote/Local), DTO Models (`json_serializable`), and Repository Implementations.

---

## 3. Tech Stack & Infrastructure

| Layer / Concern | Technology / Library | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.38+ / Dart 3.10+ | Cross-platform mobile foundation |
| **State & DI** | `get: ^4.6.6` | Controllers, Reactive Obx state, Dependency Injection, Named Routes |
| **HTTP Client** | `dio: ^5.9.2` | REST API communication with logging & connectivity interceptors |
| **Secure Storage** | `flutter_secure_storage: ^10.3.1` | Encrypted JWT token persistence (`SecureTokenStore`) |
| **Local Storage** | `shared_preferences: ^2.5.5` | Non-sensitive preferences & cache flags |
| **Code Push** | `shorebird_code_push: ^2.0.7` | OTA Hot patches without App Store / Play Store releases |
| **Firebase Suite** | Core, Remote Config, Messaging, Analytics, Crashlytics | Cloud infrastructure, notifications, feature flags, diagnostics |
| **QR Scanner** | `mobile_scanner: ^6.0.10` | High-performance native camera QR scanning |
| **Typography** | `google_fonts: ^6.2.1` | Manrope & Inter fonts |
| **Serialization** | `json_annotation` + `build_runner` | Strongly-typed JSON model serialization |

---

## 4. State Management & Navigation Guidelines

### Navigation Model
- Routes are managed via GetX named routes (`Get.toNamed()`, `Get.offAllNamed()`).
- All named routes are centralized in [`AppRoutes`](file:///Users/suraj/Projects/rewardhub/lib/core/routes/app_routes.dart) and mapped in [`AppPages`](file:///Users/suraj/Projects/rewardhub/lib/core/routes/app_pages.dart).

```dart
// Navigation Examples
Get.toNamed(AppRoutes.otp, arguments: {'mobile': phone});
Get.offAllNamed(AppRoutes.shell);
```

### Bottom Navigation Shell Container
- `MainShell` (`/shell`) renders a persistent bottom navigation bar containing 4 primary tabs:
  1. **Home** (`HomeView`)
  2. **Catalogue** (`CatalogueView`)
  3. **Scan QR** (`QrScanView`)
  4. **Transactions / Wallet** (`WalletView` / Transaction History)
  5. **Profile** (`ProfileView`)
- `ShellController` maintains `currentIndex` without recreating view state on tab changes.

### Reactive View State
- Asynchronous operations utilize the `ViewState<T>` pattern (`ViewStateInitial`, `ViewStateLoading`, `ViewStateSuccess<T>`, `ViewStateError`):

```dart
Obx(() {
  final state = controller.state;
  if (state is ViewStateLoading) {
    return const Skeleton(height: 120);
  } else if (state is ViewStateSuccess<ProfileModel>) {
    return _BalanceCard(data: state.data);
  } else if (state is ViewStateError) {
    return ErrorCard(message: state.message);
  }
  return const SizedBox.shrink();
});
```

---

## 5. UI & UX Design System ("Digital Curator")

The design system follows the **Digital Curator** paradigm with a **60:30:10** surface/primary/accent balance.

### 5.1 Color Palette (`AppColors`)

```dart
abstract final class AppColors {
  // ── Dominant Surface (60%) ──────────────────────────────────────────────────
  static const Color surface                = Color(0xFFF7F9FB); // Main background
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Card background
  static const Color surfaceContainerLow    = Color(0xFFF2F4F6);
  static const Color surfaceContainer       = Color(0xFFE8EAED);
  static const Color surfaceContainerHigh   = Color(0xFFE4E6E9);
  static const Color surfaceContainerHighest= Color(0xFFE0E3E5);

  // ── Primary Brand (30%) — Brand Blue ─────────────────────────────────────────
  static const Color primary          = Color(0xFF0040A1); // Kitox Blue
  static const Color primaryContainer = Color(0xFF0056D2);
  static const Color primaryFixed     = Color(0xFFD8E2FF);
  static const Color onPrimary        = Color(0xFFFFFFFF);

  // ── Accent (10%) — Warm Gold / Value ────────────────────────────────────────
  static const Color tertiary         = Color(0xFFFFB77D); // Reward Points & Badges
  static const Color tertiaryFixed    = Color(0xFFFFDCC2);

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const Color error            = Color(0xFFBA1A1A);
  static const Color success          = Color(0xFF1E7B34);
  static const Color warning          = Color(0xFFB26A00);

  // ── Text / On-Surface ────────────────────────────────────────────────────────
  static const Color onSurface        = Color(0xFF191C1E); // Primary Text (NO pure black)
  static const Color onSurfaceVariant = Color(0xFF43474E); // Secondary / Subtitle Text

  // ── Gradient & Ghost Border ──────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );
  static const Color ghostBorder = Color(0x26C3C6D6); // ~15% subtle container outline
}
```

### 5.2 Typography Strategy (`AppTextStyles`)
The app implements a **Dual-Font Editorial System**:
- **Manrope** ("The Voice"): Used for Display, Headlines, and Titles (`displayLg` down to `titleSm`).
- **Inter** ("The Engine"): Used for Body text, Input fields, Labels, and Buttons (`bodyLg` down to `labelSm`).

```dart
// Display & Headlines (Manrope)
AppTextStyles.headlineLg  // 32px, bold, Manrope
AppTextStyles.titleLg     // 22px, semi-bold, Manrope

// Body & Labels (Inter)
AppTextStyles.bodyLg      // 16px, regular, Inter
AppTextStyles.labelLg     // 14px, medium, Inter
```

### 5.3 Common UI Components
- **`AppButton`**: Supports primary gradient fill, outlined ghost border style, and inline loading indicator (`isLoading: true`).
- **`AppTopBar`**: Custom branded app bar displaying Kitox logo or back navigation button.
- **`AppBanner`**: Promotional image carousel widget.
- **`Skeleton`**: Animated shimmer layout placeholders for loading states.
- **`ConnectivityWidget`**: Persistent top banner alerting user of lost internet connection.

---

## 6. Functional Specifications by Feature

### 6.1 Authentication & Onboarding
- **Login Screen**: Mobile number and password login with validation. Option to log in via SMS OTP.
- **Registration Flow (Multi-Step)**:
  1. **Personal Details**: Full name, mobile number, email.
  2. **Account Details**: Preferred language, trade type (Electrician, Plumber, Contractor, Retailer).
  3. **KYC Verification**: Aadhaar / PAN document upload and ID number entry.
  4. **OTP Verification**: 6-digit SMS OTP entry with countdown resend timer.
- **Session Handling**: JWT access tokens are saved in secure storage (`SecureTokenStore`). Logged-in users bypass authentication screens on app restart.

### 6.2 Home Dashboard (`HomeView`)
- **Header**: User welcome greeting and notifications icon.
- **Promotional Carousel**: Dynamic promotional banners fetched from API/Remote Config.
- **Points Balance Card**:
  - Highlights Total Available Points (with warm gold accent).
  - Displays weekly points earned metric.
  - "Redeem Points" call-to-action button.
- **Quick Action Grid**:
  - Scan Receipt / Product QR Code
  - Points Redemption
  - Product Catalogue
  - FAQs & Support
- **Recent Activity Section**: Timeline of recently earned or redeemed points.

### 6.3 QR Code Scanning (`QrScanView`)
- Native camera viewport leveraging `mobile_scanner`.
- Custom overlay mask (`ScannerOverlayShape`) framing the scanning target.
- Quick controls: Flashlight toggle, gallery image selector for uploaded codes.
- Immediate payload validation against backend (`SubmitQrScanUseCase`).
- Visual feedback on success (points added dialog with celebration feedback) or failure (invalid/already-scanned code error modal).

### 6.4 Product Catalogue (`CatalogueView`)
- Search bar & product categories filter.
- Product cards showing product image, point value requirement, and description.
- Detailed modal preview for product rewards.

### 6.5 Wallet & Points Cash Out (`WalletView`)
- Wallet points balance summary.
- Redemption modalities:
  - **UPI Transfer**: Instant transfer via user's VPA / UPI ID (`example@upi`).
  - **Bank Transfer**: Payout via Account Number + IFSC Code.
- Form validation for UPI ID & Bank Account details (`PaymentValidators`).
- Historical ledger listing earned points vs payout redemptions with status chips (*Success*, *Pending*, *Failed*).

### 6.6 Profile & Referral System (`ProfileView`)
- Profile details edit & KYC verification status badge (*Verified*, *Pending*, *Rejected*).
- **Referral Code Card**:
  - Displays user's unique referral code.
  - Copy to clipboard & native OS share integration.
  - Explanation of referral reward bonus structure.
- Support options: WhatsApp helpdesk link, toll-free contact, and FAQ viewer (`FaqView`).
- Account logout & secure cache clearing.

### 6.7 App Maintenance & Shorebird OTA Updates
- **Maintenance Mode**: Activated remotely via Firebase Remote Config flag. Displays a friendly maintenance screen (`MaintenanceView`) blocking user actions.
- **Shorebird Hot Push**: Checks for lightweight OTA updates in background. Prompt dialog (`ShorebirdUpdateDialog`) prompts app restart when a patch is downloaded.

---

## 7. Developer & LLM Rules of Engagement

When generating or modifying code in this codebase, adhere strictly to these rules:

1. **Do NOT Use Pure Black**: Always use `AppColors.onSurface` (`#191C1E`) for primary text. Pure `#000000` is forbidden.
2. **Do NOT Hardcode Hex Colors or Inline Text Styles**: Always reference `AppColors.*` and `AppTextStyles.*`.
3. **Respect Clean Architecture Boundaries**:
   - Presentation files MUST NOT import data sources or repository implementations directly.
   - Domain files MUST remain pure Dart (no Flutter UI imports).
4. **Use GetX Idioms Correctly**:
   - Use `Obx(() => ...)` for reactive UI rendering.
   - Use `Get.find<Controller>()` or `GetView<Controller>` for controller binding.
   - Register dependencies via `Bindings`.
5. **Localization Mandate**: Always use `AppLocalizations.of(context)!` or `app_en.arb` string keys. Do not hardcode raw text strings in UI components.
6. **Token Security**: Never log JWT tokens or write credentials to unencrypted `SharedPreferences`. Always use [`SecureTokenStore`](file:///Users/suraj/Projects/rewardhub/lib/core/storage/secure_token_store.dart).
7. **Error & Loading States**: Every async data feature must gracefully handle loading (`Skeleton`), error states, and empty states.

---
