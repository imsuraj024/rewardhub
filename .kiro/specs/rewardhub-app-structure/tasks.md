# Tasks: RewardHub App Structure

## Task List

- [x] 1. Add required dependencies to pubspec.yaml
  - [x] 1.1 Add `go_router`, `provider`, `json_annotation` as dependencies
  - [x] 1.2 Add `json_serializable`, `build_runner` as dev dependencies

- [x] 2. Create core infrastructure files
  - [x] 2.1 Create `lib/core/router/app_router.dart` with `AppRouter` class and `GoRouter` config (all 7 routes, auth redirect, ShellRoute for main tabs)
  - [x] 2.2 Create `lib/core/utils/logger.dart` wrapping `dart:developer.log`

- [x] 3. Create auth feature scaffold
  - [x] 3.1 Create `lib/features/auth/data/models/user_model.dart` with `UserModel` and `@JsonSerializable` annotation
  - [x] 3.2 Create `lib/features/auth/data/repositories/auth_repository.dart` as abstract interface
  - [x] 3.3 Create `lib/features/auth/data/repositories/auth_repository_impl.dart` as stub implementation
  - [x] 3.4 Create `lib/features/auth/domain/auth_view_model.dart` extending `ChangeNotifier`
  - [x] 3.5 Create `lib/features/auth/presentation/login_screen.dart` stub
  - [x] 3.6 Create `lib/features/auth/presentation/register_screen.dart` stub

- [x] 4. Create main shell
  - [x] 4.1 Create `lib/core/widgets/main_shell.dart` with `MainShell` widget and 5-tab `BottomNavigationBar`

- [x] 5. Create home feature scaffold
  - [x] 5.1 Create `lib/features/home/data/repositories/home_repository.dart` abstract interface
  - [x] 5.2 Create `lib/features/home/domain/home_view_model.dart` stub
  - [x] 5.3 Create `lib/features/home/presentation/home_screen.dart` stub

- [x] 6. Create catalogue feature scaffold
  - [x] 6.1 Create `lib/features/catalogue/data/models/reward_item.dart` with `RewardItem` and `@JsonSerializable`
  - [x] 6.2 Create `lib/features/catalogue/data/repositories/catalogue_repository.dart` abstract interface
  - [x] 6.3 Create `lib/features/catalogue/domain/catalogue_view_model.dart` stub
  - [x] 6.4 Create `lib/features/catalogue/presentation/catalogue_screen.dart` stub

- [x] 7. Create QR scan feature scaffold
  - [x] 7.1 Create `lib/features/qr_scan/data/repositories/qr_repository.dart` abstract interface
  - [x] 7.2 Create `lib/features/qr_scan/domain/qr_scan_view_model.dart` stub
  - [x] 7.3 Create `lib/features/qr_scan/presentation/qr_scan_screen.dart` stub

- [x] 8. Create transaction history feature scaffold
  - [x] 8.1 Create `lib/features/transaction_history/data/models/transaction.dart` with `Transaction` and `@JsonSerializable`
  - [x] 8.2 Create `lib/features/transaction_history/data/repositories/transaction_repository.dart` abstract interface
  - [x] 8.3 Create `lib/features/transaction_history/domain/transaction_history_view_model.dart` stub
  - [x] 8.4 Create `lib/features/transaction_history/presentation/transaction_history_screen.dart` stub

- [x] 9. Create profile feature scaffold
  - [x] 9.1 Create `lib/features/profile/data/repositories/profile_repository.dart` abstract interface
  - [x] 9.2 Create `lib/features/profile/domain/profile_view_model.dart` stub
  - [x] 9.3 Create `lib/features/profile/presentation/profile_screen.dart` stub

- [x] 10. Update app entry point
  - [x] 10.1 Update `lib/main.dart` to use `MaterialApp.router` with `AppRouter.build()` and root `ChangeNotifierProvider` for `AuthViewModel`
