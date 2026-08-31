# Implementation Plan: Internet Connection Checker

## Overview

Implement a reactive internet connectivity monitoring layer for the RewardHub Flutter app. The work proceeds in five incremental steps: (1) add the dependency and core types, (2) build the `ConnectivityService` singleton, (3) wire the `ConnectivityInterceptor` into `ApiClient`, (4) build the `ConnectivityWidget` UI, and (5) integrate everything end-to-end and verify.

## Tasks

- [x] 1. Add dependency and define core types
  - Add `connectivity_plus: ^6.1.4` to the `dependencies` section of `pubspec.yaml`
  - Add `fast_check: ^0.2.0` to the `dev_dependencies` section of `pubspec.yaml` (for property-based tests)
  - Create `lib/core/network/connection_status.dart` with the `ConnectionStatus` enum (`connected`, `slow`, `disconnected`)
  - Create `lib/core/services/i_connectivity_service.dart` with the `IConnectivityService` abstract interface (`statusStream`, `currentStatus`, `dispose()`)
  - Extend `lib/core/network/api_exception.dart` with `NoInternetException extends NetworkException` carrying a `reason` field (default `'disconnected'`)
  - _Requirements: 1.1, 1.4, 2.2, 2.3, 3.2, 3.5, 6.1_

- [x] 2. Implement `ConnectivityService`
  - [x] 2.1 Create `lib/core/services/connectivity_service.dart` implementing `IConnectivityService` and `WidgetsBindingObserver`
    - Factory singleton constructor with optional `speedProbeUrl`, `slowThresholdMs`, and `pollingInterval` parameters
    - `StreamController<ConnectionStatus>.broadcast()` with a cached `_currentStatus` field initialised to `disconnected`
    - Subscribe to `Connectivity().onConnectivityChanged` to trigger `_probe()` on every platform network event
    - Periodic `Timer` that fires every `pollingInterval` to re-run `_probe()`
    - Dedicated `Dio _probeDio` instance (not `ApiClient`) with `connectTimeout` set to `slowThresholdMs` ms
    - `_probe()`: send HEAD to `speedProbeUrl`, measure elapsed time, classify as `connected`/`slow`/`disconnected`, emit only on change
    - `didChangeAppLifecycleState`: call `_probe()` on `AppLifecycleState.resumed`
    - `dispose()`: cancel timer, cancel connectivity subscription, close stream controller; guard with `_disposed` flag
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 5.1, 5.2, 5.3, 5.4, 6.3, 6.4_

  - [ ]* 2.2 Write property test: stream reflects current status (Property 1)
    - **Property 1: Stream reflects current status**
    - **Validates: Requirements 1.4**
    - File: `test/core/services/connectivity_service_test.dart`
    - Use `fast_check` to generate arbitrary lists of latency values; after each simulated probe assert `currentStatus == stream.last`

  - [ ]* 2.3 Write property test: latency above threshold yields slow (Property 2)
    - **Property 2: Latency above threshold yields slow**
    - **Validates: Requirements 2.2**
    - File: `test/core/services/connectivity_service_test.dart`
    - Generate `int` in range `(slowThresholdMs, 60000]`; assert emitted status is `ConnectionStatus.slow`

  - [ ]* 2.4 Write property test: latency at or below threshold yields connected (Property 3)
    - **Property 3: Latency at or below threshold yields connected**
    - **Validates: Requirements 2.3**
    - File: `test/core/services/connectivity_service_test.dart`
    - Generate `int` in range `[0, slowThresholdMs]`; assert emitted status is `ConnectionStatus.connected`

  - [ ]* 2.5 Write property test: custom threshold governs classification (Property 4)
    - **Property 4: Custom threshold governs classification**
    - **Validates: Requirements 6.4**
    - File: `test/core/services/connectivity_service_test.dart`
    - Generate arbitrary `slowThresholdMs` and arbitrary latency; assert classification matches `latency > threshold ? slow : connected`

  - [ ]* 2.6 Write property test: probe exception yields disconnected (Property 8)
    - **Property 8: Speed probe exception yields disconnected**
    - **Validates: Requirements 5.1**
    - File: `test/core/services/connectivity_service_test.dart`
    - Generate arbitrary exception types thrown by the probe; assert `disconnected` is emitted and `logger` is called

  - [ ]* 2.7 Write property test: new subscriber receives current status immediately (Property 9)
    - **Property 9: New subscriber receives current status immediately**
    - **Validates: Requirements 5.2**
    - File: `test/core/services/connectivity_service_test.dart`
    - Seed service with arbitrary `ConnectionStatus`; subscribe and assert first emitted event equals the seed status

  - [ ]* 2.8 Write unit tests for `ConnectivityService`
    - Verify default `slowThresholdMs == 2000` and `pollingInterval == 10s`
    - Verify two factory calls return the identical instance (singleton)
    - Verify `ConnectivityService` is assignable to `IConnectivityService`
    - Verify `dispose()` does not throw; verify stream is closed afterwards
    - Verify `didChangeAppLifecycleState(resumed)` triggers a probe
    - Verify custom `speedProbeUrl` is used by the probe
    - _Requirements: 1.5, 2.5, 2.6, 5.3, 5.4, 6.1, 6.3_

- [x] 3. Checkpoint — ensure all `ConnectivityService` tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implement `ConnectivityInterceptor` and integrate with `ApiClient`
  - [x] 4.1 Create `lib/core/network/interceptors/connectivity_interceptor.dart`
    - Constructor accepts `IConnectivityService` (dependency injection)
    - `onRequest`: switch on `_service.currentStatus`; reject with `NoInternetException` wrapped in `DioException` when `disconnected`; attach `X-Connection-Quality: slow` header and call `handler.next` when `slow`; call `handler.next` unmodified when `connected`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 6.2_

  - [x] 4.2 Modify `lib/core/network/api_client.dart` to register `ConnectivityInterceptor` first
    - Import `connectivity_interceptor.dart` and `connectivity_service.dart`
    - Add `ConnectivityInterceptor(ConnectivityService())` as the first entry in `_dio.interceptors.addAll([...])`
    - _Requirements: 3.1_

  - [ ]* 4.3 Write property test: disconnected request is rejected with `NoInternetException` (Property 5)
    - **Property 5: Disconnected request is rejected with NoInternetException**
    - **Validates: Requirements 3.2**
    - File: `test/core/network/interceptors/connectivity_interceptor_test.dart`
    - Generate arbitrary `RequestOptions` (method, path, headers); inject mock service returning `disconnected`; assert `NoInternetException` is thrown

  - [ ]* 4.4 Write property test: slow request receives quality header (Property 6)
    - **Property 6: Slow request receives quality header**
    - **Validates: Requirements 3.3**
    - File: `test/core/network/interceptors/connectivity_interceptor_test.dart`
    - Generate arbitrary `RequestOptions`; inject mock service returning `slow`; assert `X-Connection-Quality: slow` header is present

  - [ ]* 4.5 Write property test: connected request passes through unmodified (Property 7)
    - **Property 7: Connected request passes through unmodified**
    - **Validates: Requirements 3.4**
    - File: `test/core/network/interceptors/connectivity_interceptor_test.dart`
    - Generate arbitrary `RequestOptions`; inject mock service returning `connected`; assert headers are unchanged

  - [ ]* 4.6 Write unit tests for `ConnectivityInterceptor` and `NoInternetException`
    - Verify injected mock `IConnectivityService` is used (not the singleton)
    - Verify `NoInternetException` is `is NetworkException` and `is ApiException`
    - Verify `ApiClient` interceptor list contains a `ConnectivityInterceptor` instance
    - _Requirements: 3.5, 6.2_

- [x] 5. Checkpoint — ensure all interceptor tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implement `ConnectivityWidget`
  - [x] 6.1 Create `lib/core/widgets/connectivity_widget.dart`
    - `ConnectivityWidget` is a `StatefulWidget` accepting `child` (required) and `service` (optional, for DI)
    - State subscribes to `service?.statusStream ?? ConnectivityService().statusStream` and maintains `ConnectionStatus _status`
    - When `disconnected`: render a non-dismissible `MaterialBanner` with red background and "No internet connection" label above `child`
    - When `slow`: render a dismissible `MaterialBanner` with amber background, "Slow connection detected" label, and a "Dismiss" action above `child`
    - When `connected`: render `child` with no banner
    - Wrap each banner in a `Semantics` widget with `label` set to the banner text
    - Cancel stream subscription in `dispose()`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [ ]* 6.2 Write property test: banner lifecycle for any degraded status (Property 10)
    - **Property 10: ConnectivityWidget shows banner for any degraded status**
    - **Validates: Requirements 4.2, 4.3, 4.4**
    - File: `test/core/widgets/connectivity_widget_test.dart`
    - Generate arbitrary child widget and arbitrary status sequences; assert `MaterialBanner` is present in tree iff status ≠ `connected`; assert banner is removed when status transitions to `connected`

  - [ ]* 6.3 Write unit/widget tests for `ConnectivityWidget`
    - Verify child widget appears in the widget tree regardless of status
    - Verify disconnected banner has a `Semantics` label readable by screen readers
    - Verify slow banner has a "Dismiss" action; disconnected banner does not
    - _Requirements: 4.1, 4.2, 4.3, 4.5_

- [x] 7. Final checkpoint — ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at each layer boundary
- Property tests use the `fast_check` package (minimum 100 iterations each); tag each test with `// Feature: internet-connection-checker, Property N: <property text>`
- Unit tests complement property tests by covering specific examples and edge cases
- The `ConnectivityInterceptor` reads `currentStatus` synchronously — no async on the hot path
- Use a separate `Dio` instance for the speed probe (not `ApiClient`) to avoid interceptor recursion
