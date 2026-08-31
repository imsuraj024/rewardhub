# Design Document: Internet Connection Checker

## Overview

This feature adds a reactive internet connectivity monitoring layer to the RewardHub Flutter app. It introduces a `ConnectivityService` singleton that combines platform-level network change events (via `connectivity_plus`) with an active speed probe (a Dio HEAD request) to classify the connection as `connected`, `slow`, or `disconnected`. The status is exposed as a broadcast stream so any part of the app can react to changes. A `ConnectivityInterceptor` guards every Dio request automatically, and a `ConnectivityWidget` renders a `MaterialBanner` overlay when connectivity is degraded.

The design integrates cleanly with the existing `ApiClient` singleton, the `ApiException` hierarchy, and the `logger` utility — no changes to existing files are required beyond adding the interceptor to `ApiClient`.

---

## Architecture

The feature follows the existing layered architecture of `lib/core/`:

```
connectivity_plus (platform events)
        │
        ▼
ConnectivityService  ◄──── WidgetsBindingObserver (app resume)
  - StreamController.broadcast
  - periodic Timer (speed probe)
  - Dio HEAD request to probe URL
        │
        ├──► Stream<ConnectionStatus>  ──► ConnectivityWidget (UI banner)
        │
        └──► currentStatus getter  ──► ConnectivityInterceptor
                                              │
                                              ▼
                                         ApiClient (Dio)
```

**Key design decisions:**

- **No RxDart / BehaviorSubject**: A plain `StreamController.broadcast` with a cached `_currentStatus` field replaces `BehaviorSubject`. New subscribers receive the current value immediately via the `currentStatus` getter; the stream itself only emits on changes. This avoids adding a new dependency.
- **Singleton via factory constructor**: Matches the existing `ApiClient` pattern.
- **Dio for speed probe**: Reuses the existing Dio dependency rather than `dart:io` `HttpClient`, keeping the dependency surface small. A separate `Dio` instance (not `ApiClient`) is used for the probe to avoid interceptor recursion.
- **`connectivity_plus` for platform events**: Provides reliable cross-platform (Android, iOS, macOS, Web) network change callbacks without polling the OS.
- **`WidgetsBindingObserver`**: Triggers an immediate probe on app resume so stale status is refreshed after the device wakes.

---

## Components and Interfaces

### `ConnectionStatus` enum

```dart
// lib/core/network/connection_status.dart
enum ConnectionStatus { connected, slow, disconnected }
```

### `IConnectivityService` abstract interface

```dart
// lib/core/services/i_connectivity_service.dart
abstract interface class IConnectivityService {
  Stream<ConnectionStatus> get statusStream;
  ConnectionStatus get currentStatus;
  Future<void> dispose();
}
```

### `ConnectivityService`

```dart
// lib/core/services/connectivity_service.dart
class ConnectivityService implements IConnectivityService, WidgetsBindingObserver {
  // Factory singleton constructor
  factory ConnectivityService({
    String speedProbeUrl = 'https://www.google.com',
    int slowThresholdMs = 2000,
    Duration pollingInterval = const Duration(seconds: 10),
  });

  @override Stream<ConnectionStatus> get statusStream;
  @override ConnectionStatus get currentStatus;
  @override Future<void> dispose();
}
```

**Internals:**
- `StreamController<ConnectionStatus>.broadcast()` — emits on every status change.
- `ConnectionStatus _currentStatus` — cached value; initialised to `disconnected`.
- `StreamSubscription _connectivitySubscription` — listens to `Connectivity().onConnectivityChanged`.
- `Timer? _pollingTimer` — fires every `pollingInterval` to re-run the speed probe.
- `Dio _probeDio` — a dedicated `Dio` instance with a `connectTimeout` of `slowThresholdMs` ms used only for the HEAD probe.
- On each connectivity change or timer tick: run `_probe()`, measure elapsed time, compare to `slowThresholdMs`, emit the new status only if it differs from `_currentStatus`.
- `WidgetsBinding.instance.addObserver(this)` in the constructor; `didChangeAppLifecycleState` triggers `_probe()` on `AppLifecycleState.resumed`.

### `NoInternetException`

```dart
// lib/core/network/api_exception.dart  (extend existing file)
class NoInternetException extends NetworkException {
  final String reason; // 'disconnected' | 'slow' (reserved for future use)
  NoInternetException({this.reason = 'disconnected'})
      : super('No internet connection ($reason)');
}
```

### `ConnectivityInterceptor`

```dart
// lib/core/network/interceptors/connectivity_interceptor.dart
class ConnectivityInterceptor extends Interceptor {
  final IConnectivityService _service;

  ConnectivityInterceptor(this._service);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    switch (_service.currentStatus) {
      case ConnectionStatus.disconnected:
        handler.reject(/* NoInternetException wrapped in DioException */);
      case ConnectionStatus.slow:
        options.headers['X-Connection-Quality'] = 'slow';
        handler.next(options);
      case ConnectionStatus.connected:
        handler.next(options);
    }
  }
}
```

The interceptor reads `currentStatus` synchronously — no async needed — keeping the hot path fast.

### `ConnectivityWidget`

```dart
// lib/core/widgets/connectivity_widget.dart
class ConnectivityWidget extends StatefulWidget {
  const ConnectivityWidget({
    super.key,
    required this.child,
    this.service, // optional override for testing
  });

  final Widget child;
  final IConnectivityService? service;
}
```

**State behaviour:**
- Subscribes to `service.statusStream` (falls back to `ConnectivityService()` singleton).
- Maintains `ConnectionStatus _status` in state.
- Renders a `MaterialBanner` above `child` when status is `disconnected` or `slow`.
  - `disconnected`: non-dismissible, red background, "No internet connection" label.
  - `slow`: dismissible (has a "Dismiss" action), amber background, "Slow connection detected" label.
  - `connected`: no banner.
- The banner is wrapped in a `Semantics` widget with `label` set to the banner text for screen-reader accessibility.

### Integration with `ApiClient`

`ConnectivityInterceptor` is added to `ApiClient._internal()` **before** `AuthInterceptor` so connectivity is checked first:

```dart
// In ApiClient._internal():
_dio.interceptors.addAll([
  ConnectivityInterceptor(ConnectivityService()),  // ← new, first
  _authInterceptor,
  if (kDebugMode) LoggingInterceptor(),
]);
```

---

## Data Models

### `ConnectionStatus` (enum)

| Value | Meaning |
|---|---|
| `connected` | Network available; speed probe latency ≤ `slowThresholdMs` |
| `slow` | Network available; speed probe latency > `slowThresholdMs` or probe timed out |
| `disconnected` | No network interface available, or speed probe threw an unhandled exception |

### Configuration parameters (`ConnectivityService`)

| Parameter | Type | Default | Description |
|---|---|---|---|
| `speedProbeUrl` | `String` | `'https://www.google.com'` | URL for the HEAD speed probe |
| `slowThresholdMs` | `int` | `2000` | Latency threshold in ms above which status is `slow` |
| `pollingInterval` | `Duration` | `Duration(seconds: 10)` | How often to re-run the speed probe |

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Stream reflects current status

*For any* sequence of speed probe results, after each result is processed, `currentStatus` SHALL equal the most recently emitted value on `statusStream`.

**Validates: Requirements 1.4**

---

### Property 2: Latency above threshold yields slow

*For any* measured round-trip latency strictly greater than `slowThresholdMs`, the `ConnectivityService` SHALL emit `ConnectionStatus.slow`.

**Validates: Requirements 2.2**

---

### Property 3: Latency at or below threshold yields connected

*For any* measured round-trip latency at or below `slowThresholdMs`, the `ConnectivityService` SHALL emit `ConnectionStatus.connected`.

**Validates: Requirements 2.3**

---

### Property 4: Custom threshold governs classification

*For any* `slowThresholdMs` value provided at construction time and any measured latency, the classification SHALL use the provided threshold (not the default 2000 ms).

**Validates: Requirements 6.4**

> **Reflection note:** Properties 2, 3, and 4 together cover the full threshold classification contract. Property 4 subsumes the default-threshold cases when the threshold is varied, so no additional property is needed for the default value (Requirement 2.5 is covered by an example test).

---

### Property 5: Disconnected request is rejected with NoInternetException

*For any* `RequestOptions`, when `IConnectivityService.currentStatus` returns `ConnectionStatus.disconnected`, the `ConnectivityInterceptor` SHALL reject the request by throwing a `NoInternetException`.

**Validates: Requirements 3.2**

---

### Property 6: Slow request receives quality header

*For any* `RequestOptions`, when `IConnectivityService.currentStatus` returns `ConnectionStatus.slow`, the `ConnectivityInterceptor` SHALL attach the header `X-Connection-Quality: slow` and allow the request to proceed.

**Validates: Requirements 3.3**

---

### Property 7: Connected request passes through unmodified

*For any* `RequestOptions`, when `IConnectivityService.currentStatus` returns `ConnectionStatus.connected`, the `ConnectivityInterceptor` SHALL forward the request without adding or modifying any headers.

**Validates: Requirements 3.4**

> **Reflection note:** Properties 5, 6, and 7 cover all three branches of the interceptor switch exhaustively. They are not redundant — each tests a distinct code path with distinct postconditions.

---

### Property 8: Speed probe exception yields disconnected

*For any* exception type thrown by the speed probe, the `ConnectivityService` SHALL catch it, log it via the `logger` utility, and emit `ConnectionStatus.disconnected`.

**Validates: Requirements 5.1**

---

### Property 9: New subscriber receives current status immediately

*For any* `ConnectionStatus` that is the current status at the time of subscription, a new subscriber to `statusStream` SHALL receive that status as the first emitted event.

**Validates: Requirements 5.2**

---

### Property 10: ConnectivityWidget shows banner for any degraded status

*For any* child widget, when `statusStream` emits `ConnectionStatus.disconnected` or `ConnectionStatus.slow`, the `ConnectivityWidget` SHALL render a `MaterialBanner` above the child. When the stream subsequently emits `ConnectionStatus.connected`, the banner SHALL be removed.

**Validates: Requirements 4.2, 4.3, 4.4**

> **Reflection note:** Properties for 4.2, 4.3, and 4.4 are consolidated here because the "show banner → hide banner" round-trip is a single coherent property. The dismissibility difference between disconnected and slow banners is covered by an example test.

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| Speed probe HTTP error (4xx/5xx) | Treat as a successful response (server reachable); classify by latency |
| Speed probe connection timeout | Emit `slow` (Requirement 2.7) |
| Speed probe throws any exception | Catch, log via `logger`, emit `disconnected` (Requirement 5.1) |
| `dispose()` called while probe in flight | Cancel the in-flight request via `CancelToken`; swallow `DioException.cancel` |
| `dispose()` called multiple times | Guard with `_disposed` flag; second call is a no-op |
| `ConnectivityInterceptor` rejects a request | Wraps `NoInternetException` in a `DioException` with type `DioExceptionType.unknown` so existing `ErrorHandler.handle()` in `ApiClient` picks it up correctly |

---

## Testing Strategy

### Unit tests (example-based)

- `ConnectivityService` defaults: verify `slowThresholdMs == 2000` and `pollingInterval == 10s` when not configured.
- `ConnectivityService` singleton: two factory calls return identical instances.
- `ConnectivityService` implements `IConnectivityService`: type check.
- `ConnectivityService.dispose()`: no exception thrown; subsequent stream is closed.
- `ConnectivityService` app resume: simulate `didChangeAppLifecycleState(resumed)`, verify probe is triggered.
- `ConnectivityService` speed probe URL: construct with custom URL, verify probe hits that URL.
- `NoInternetException` type hierarchy: `is NetworkException`, `is ApiException`.
- `ConnectivityInterceptor` DI: inject mock `IConnectivityService`, verify interceptor uses mock's `currentStatus`.
- `ConnectivityWidget` child rendered: verify child appears in widget tree.
- `ConnectivityWidget` accessibility: disconnected state has `Semantics` label on banner.
- `ConnectivityWidget` slow banner is dismissible: verify dismiss action exists.
- `ApiClient` interceptor registration: `ConnectivityInterceptor` is present in `_dio.interceptors`.

### Property-based tests

Uses the [`fast_check`](https://pub.dev/packages/fast_check) package (Dart port of fast-check). Each test runs a minimum of **100 iterations**.

Tag format: `// Feature: internet-connection-checker, Property N: <property text>`

| Property | Generator inputs | Assertion |
|---|---|---|
| P1: Stream reflects current status | Arbitrary list of latency values | After each probe, `currentStatus == stream.last` |
| P2: Latency above threshold → slow | `int` in range `(slowThresholdMs, 60000]` | Emitted status is `slow` |
| P3: Latency at/below threshold → connected | `int` in range `[0, slowThresholdMs]` | Emitted status is `connected` |
| P4: Custom threshold governs classification | Arbitrary `slowThresholdMs` + arbitrary latency | Classification matches `latency > threshold ? slow : connected` |
| P5: Disconnected → NoInternetException | Arbitrary `RequestOptions` (method, path, headers) | `ConnectivityInterceptor` throws `NoInternetException` |
| P6: Slow → X-Connection-Quality header | Arbitrary `RequestOptions` | Header `X-Connection-Quality: slow` present after interceptor |
| P7: Connected → request unmodified | Arbitrary `RequestOptions` | Headers unchanged after interceptor |
| P8: Probe exception → disconnected | Arbitrary `Exception` subtype | `disconnected` emitted; logger called |
| P9: New subscriber gets current status | Arbitrary `ConnectionStatus` as seed | First event on new subscription equals seed status |
| P10: Banner lifecycle | Arbitrary child widget + status sequence | Banner present iff status ≠ connected |

### Integration tests

- End-to-end: `ApiClient` with real `ConnectivityService` (device/emulator with network) — verify a GET request succeeds when connected.
- `ConnectivityWidget` in a full widget test with a `StreamController` driving status changes — verify banner appears and disappears correctly.

### File locations

```
test/
  core/
    network/
      interceptors/
        connectivity_interceptor_test.dart
    services/
      connectivity_service_test.dart
    widgets/
      connectivity_widget_test.dart
```

---

## File Structure

```
lib/
  core/
    network/
      api_exception.dart              ← extend: add NoInternetException
      connection_status.dart          ← new: ConnectionStatus enum
      interceptors/
        connectivity_interceptor.dart ← new: ConnectivityInterceptor
      api_client.dart                 ← modify: add ConnectivityInterceptor
    services/
      i_connectivity_service.dart     ← new: IConnectivityService interface
      connectivity_service.dart       ← new: ConnectivityService implementation
    widgets/
      connectivity_widget.dart        ← new: ConnectivityWidget

pubspec.yaml                          ← add: connectivity_plus: ^6.1.4
```
