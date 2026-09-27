# LLM Context & Developer Guide: Kitox Hardware (RewardHub)

> **Quick Reference for LLMs and AI coding assistants working in this workspace.**  
> For full detailed specifications, refer to [PROJECT_CONTEXT.md](file:///Users/suraj/Projects/rewardhub/PROJECT_CONTEXT.md).

---

## 1. Quick Overview

- **App**: **Kitox Hardware** (`rewardhub` codebase)
- **Goal**: Scans QR codes on Kitox Hardware receipts/products, awards loyalty points, allows instant cash-out via UPI or Bank Account.
- **Tech Stack**: Flutter 3.47 / Dart 3.13, GetX (State & Routing), Dio (HTTP), Firebase, Shorebird (Code Push), `flutter_secure_storage`.

---

## 2. File Organization & Architecture

```
lib/
├── core/                  # Shared utilities, networking, widgets, theme, routes
│   ├── network/           # ApiClient (Dio), ErrorHandler, ApiException
│   ├── routes/            # AppRoutes & AppPages (GetX Routing)
│   ├── storage/           # SecureTokenStore (KeyChain/KeyStore)
│   ├── theme/             # AppColors, AppTextStyles, AppTheme
│   └── widgets/           # AppButton, AppTopBar, AppBanner, Skeleton
└── features/              # Feature modules (Clean Architecture: data/domain/presentation)
    ├── auth/              # Login, Register, KYC, OTP
    ├── home/              # Dashboard, Banners, Points Card, Recent Activity
    ├── qr_scan/           # Camera QR Scanner & API submission
    ├── wallet/            # Points wallet & UPI / Bank payout redemptions
    ├── catalogue/         # Products & point rewards
    ├── profile/           # User account, KYC status, Referral Code
    └── shell/             # Main bottom navigation shell container
```

---

## 3. UI & UX Core Rules ("Digital Curator" Strategy)

1. **Color Tokens (`AppColors`)**:
   - **Surface (60%)**: `#F7F9FB`
   - **Primary Brand (30%)**: `#0040A1` (Kitox Blue) with 135° gradient to `#0056D2`
   - **Accent Value (10%)**: `#FFB77D` (Warm Gold for points)
   - **Text (On-Surface)**: `#191C1E` (**NEVER use pure black `#000000`**)
2. **Typography (`AppTextStyles`)**:
   - **Manrope**: Display, Headlines, and Titles ("The Voice")
   - **Inter**: Body text, Labels, and Inputs ("The Engine")
3. **Components**:
   - Use `AppButton` for actions, `AppTopBar` for headers, `Skeleton` for loading states.

---

## 4. Key Rules for LLMs

- **Clean Architecture**: Presentation -> Domain <- Data. Do NOT import data layer files directly into views.
- **State Management**: Use GetX (`GetxController`, `Obx()`, `Get.find()`, `Bindings`).
- **Styling**: Always use `AppColors` and `AppTextStyles`. Never hardcode hex values or `TextStyle(fontSize: ...)` directly.
- **Security**: Store authentication tokens in `SecureTokenStore`. Never log plain text passwords.
- **Strings**: Use `AppLocalizations` for user-facing copy.

---
