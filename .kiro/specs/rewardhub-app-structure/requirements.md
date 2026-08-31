# Requirements: RewardHub App Structure

## Introduction

This feature establishes the complete folder structure and architectural skeleton for the RewardHub Flutter loyalty rewards app. It creates all necessary empty files and directories following Clean Code Architecture (MVVM + feature-based organization) as defined in RULES.md, and wires up the foundational plumbing (router, theme, entry point) so that subsequent feature development can proceed without structural rework.

---

## Requirements

### 1. Feature-Based Folder Structure

**User Story**: As a developer, I want a feature-based folder structure so that each module is self-contained and navigable.

#### Acceptance Criteria

1.1 The `lib/features/` directory SHALL exist and contain one subdirectory per feature: `auth`, `home`, `catalogue`, `qr_scan`, `transaction_history`, `profile`.

1.2 Each feature directory SHALL contain exactly three subdirectories: `presentation/`, `domain/`, and `data/`.

1.3 The `data/` layer of each feature SHALL contain a `repositories/` subdirectory with at least one repository file (abstract interface).

1.4 Features that own data models SHALL have a `data/models/` subdirectory: `auth` (UserModel), `catalogue` (RewardItem), `transaction_history` (Transaction).

1.5 The `lib/core/` directory SHALL be extended with `router/` and `utils/` subdirectories alongside the existing `theme/` and `widgets/`.

---

### 2. Routing (go_router)

**User Story**: As a developer, I want a centralized router with auth-guard so that unauthenticated users cannot access protected screens.

#### Acceptance Criteria

2.1 A `lib/core/router/app_router.dart` file SHALL exist containing an `AppRouter` class with a static `build(AuthViewModel)` method that returns a configured `GoRouter`.

2.2 The router SHALL define named route constants for all 7 routes: `/auth/login`, `/auth/register`, `/home`, `/catalogue`, `/qr-scan`, `/transactions`, `/profile`.

2.3 The router SHALL implement a `redirect` callback that redirects unauthenticated users from any non-`/auth` route to `/auth/login`.

2.4 The router SHALL implement a `redirect` callback that redirects authenticated users away from `/auth/*` routes to `/home`.

2.5 The five main tab routes (`/home`, `/catalogue`, `/qr-scan`, `/transactions`, `/profile`) SHALL be nested under a `ShellRoute` that renders `MainShell`.

---

### 3. Authentication Feature

**User Story**: As a developer, I want auth feature scaffolding so that login and register screens can be built without structural decisions.

#### Acceptance Criteria

3.1 `lib/features/auth/domain/auth_view_model.dart` SHALL exist and define `AuthViewModel extends ChangeNotifier` with `isAuthenticated`, `isLoading`, `errorMessage` getters and `login()`, `register()`, `logout()` async methods.

3.2 `lib/features/auth/data/repositories/auth_repository.dart` SHALL exist and define an `abstract interface class AuthRepository` with `signIn`, `register`, `signOut`, and `getCurrentUser` method signatures.

3.3 `lib/features/auth/data/repositories/auth_repository_impl.dart` SHALL exist as a concrete stub implementing `AuthRepository`.

3.4 `lib/features/auth/data/models/user_model.dart` SHALL exist defining `UserModel` with fields: `id`, `name`, `email`, `pointsBalance`, `tierLevel`, annotated with `@JsonSerializable`.

3.5 `lib/features/auth/presentation/login_screen.dart` SHALL exist with a `LoginScreen` stateless widget stub.

3.6 `lib/features/auth/presentation/register_screen.dart` SHALL exist with a `RegisterScreen` stateless widget stub.

---

### 4. Main Shell & Bottom Navigation

**User Story**: As a developer, I want a persistent bottom navigation shell so that tab switching is handled in one place.

#### Acceptance Criteria

4.1 A `MainShell` widget SHALL exist (location: `lib/features/home/presentation/main_shell.dart` or `lib/core/widgets/main_shell.dart`) accepting a `StatefulNavigationShell` parameter.

4.2 `MainShell` SHALL render a `BottomNavigationBar` with 5 items: Home, Catalogue, QR Scan, Transactions, Profile.

4.3 Tab selection SHALL call `navigationShell.goBranch(index)`.

4.4 The active tab SHALL be visually indicated using `AppColors.primary` per the theme.

---

### 5. Feature Screen Stubs

**User Story**: As a developer, I want stub screens for all 5 main features so that routing is immediately testable end-to-end.

#### Acceptance Criteria

5.1 Each of the following files SHALL exist with a minimal `StatelessWidget` stub that renders a `Scaffold` with the feature name as body text:
- `lib/features/home/presentation/home_screen.dart`
- `lib/features/catalogue/presentation/catalogue_screen.dart`
- `lib/features/qr_scan/presentation/qr_scan_screen.dart`
- `lib/features/transaction_history/presentation/transaction_history_screen.dart`
- `lib/features/profile/presentation/profile_screen.dart`

5.2 Each feature SHALL have a corresponding ViewModel stub in its `domain/` folder extending `ChangeNotifier` with `isLoading` and `errorMessage` getters.

5.3 Each feature SHALL have a corresponding Repository abstract interface in its `data/repositories/` folder.

---

### 6. Data Models

**User Story**: As a developer, I want json_serializable-annotated model stubs so that API integration can begin without model rework.

#### Acceptance Criteria

6.1 `UserModel` SHALL have fields: `id` (String), `name` (String), `email` (String), `pointsBalance` (int), `tierLevel` (String), with `@JsonSerializable(fieldRename: FieldRename.snake)` annotation.

6.2 `RewardItem` SHALL have fields: `id`, `title`, `description`, `pointsCost` (int), `imageUrl`, `isAvailable` (bool), with `@JsonSerializable(fieldRename: FieldRename.snake)` annotation.

6.3 `Transaction` SHALL have fields: `id`, `type`, `points` (int), `description`, `createdAt` (DateTime), with `@JsonSerializable(fieldRename: FieldRename.snake)` annotation.

6.4 All models SHALL include `fromJson` factory constructor and `toJson` method stubs (with `part` directive for generated code).

---

### 7. Logging Utility

**User Story**: As a developer, I want a centralized logger so that all features use `dart:developer` consistently.

#### Acceptance Criteria

7.1 `lib/core/utils/logger.dart` SHALL exist and expose a `log` function wrapping `dart:developer.log` with a `name` parameter defaulting to `'rewardhub'`.

7.2 The logger SHALL support an optional `error` and `stackTrace` parameter for error-level logging.

---

### 8. App Entry Point

**User Story**: As a developer, I want `main.dart` updated to use `MaterialApp.router` with the new router and theme so that the app boots into the correct initial route.

#### Acceptance Criteria

8.1 `lib/main.dart` SHALL be updated to use `MaterialApp.router` with `routerConfig: AppRouter.build(authViewModel)`.

8.2 `main.dart` SHALL provide `AuthViewModel` via `ChangeNotifierProvider` at the root.

8.3 The app SHALL boot and redirect to `/auth/login` when no session exists.

8.4 `AppTheme.light` SHALL remain the active theme.

---

### 9. Dependency Management

**User Story**: As a developer, I want all required packages declared in pubspec.yaml so that the project compiles after scaffolding.

#### Acceptance Criteria

9.1 `pubspec.yaml` SHALL include `go_router` as a dependency.

9.2 `pubspec.yaml` SHALL include `provider` as a dependency.

9.3 `pubspec.yaml` SHALL include `json_annotation` as a dependency.

9.4 `pubspec.yaml` SHALL include `json_serializable` and `build_runner` as dev dependencies.
