# Requirements Document

## Introduction

This feature adds a reusable internet connectivity checking service to the RewardHub Flutter app. The service detects whether the device has an active internet connection and classifies the connection quality (normal vs. slow) before API calls or any internet-dependent activity are performed. It exposes a reactive stream so the UI can respond to connectivity changes in real time, and it integrates with the existing `ApiClient` (Dio) layer so that all HTTP calls are guarded automatically.

## Glossary

- **Connectivity_Service**: The core singleton service responsible for monitoring network reachability and measuring connection quality.
- **Connection_Status**: An enumeration of possible connectivity states: `connected`, `slow`, or `disconnected`.
- **Speed_Probe**: A lightweight HTTP HEAD/GET request sent to a known reliable endpoint used to measure round-trip latency and classify connection speed.
- **Slow_Threshold**: The configurable latency value (in milliseconds) above which a connection is classified as `slow` rather than `connected`.
- **Connectivity_Interceptor**: A Dio interceptor that checks connectivity status before each outgoing HTTP request.
- **No_Internet_Exception**: A typed exception thrown when a request is blocked due to `disconnected` or `slow` status.
- **Connectivity_Widget**: A reusable Flutter widget that listens to the `Connectivity_Service` stream and overlays a banner or blocks interaction when connectivity is degraded.
- **ApiClient**: The existing singleton Dio wrapper at `lib/core/network/api_client.dart`.

---

## Requirements

### Requirement 1: Connectivity Detection

**User Story:** As a mobile user, I want the app to know whether my device has an active internet connection, so that I receive a clear message instead of a confusing network error when I am offline.

#### Acceptance Criteria

1. THE `Connectivity_Service` SHALL expose a `Stream<Connection_Status>` that emits a new value whenever the device's network state changes.
2. WHEN the device transitions from any state to no network interface, THE `Connectivity_Service` SHALL emit `Connection_Status.disconnected` within 3 seconds.
3. WHEN the device transitions from no network interface to an available network interface, THE `Connectivity_Service` SHALL emit either `Connection_Status.connected` or `Connection_Status.slow` within 5 seconds.
4. THE `Connectivity_Service` SHALL provide a synchronous `Connection_Status get currentStatus` getter that returns the most recently emitted status.
5. THE `Connectivity_Service` SHALL be initialised as a singleton and remain active for the lifetime of the application.

---

### Requirement 2: Slow Connection Detection

**User Story:** As a mobile user, I want the app to warn me when my internet is too slow to reliably complete requests, so that I understand why operations are taking longer than expected.

#### Acceptance Criteria

1. WHEN a network interface is available, THE `Connectivity_Service` SHALL perform a `Speed_Probe` to classify the connection quality.
2. WHEN the `Speed_Probe` round-trip latency exceeds the `Slow_Threshold`, THE `Connectivity_Service` SHALL emit `Connection_Status.slow`.
3. WHEN the `Speed_Probe` round-trip latency is at or below the `Slow_Threshold`, THE `Connectivity_Service` SHALL emit `Connection_Status.connected`.
4. THE `Connectivity_Service` SHALL repeat the `Speed_Probe` at a configurable polling interval while a network interface is available.
5. WHERE the `Slow_Threshold` is not explicitly configured, THE `Connectivity_Service` SHALL use a default `Slow_Threshold` of 2000 milliseconds.
6. WHERE the polling interval is not explicitly configured, THE `Connectivity_Service` SHALL use a default polling interval of 10 seconds.
7. IF the `Speed_Probe` request itself times out, THEN THE `Connectivity_Service` SHALL emit `Connection_Status.slow`.

---

### Requirement 3: Pre-Request Connectivity Guard

**User Story:** As a developer, I want all API calls to be automatically guarded by a connectivity check, so that I do not need to add boilerplate connectivity checks in every view model or repository.

#### Acceptance Criteria

1. THE `Connectivity_Interceptor` SHALL be registered in the `ApiClient` Dio instance and execute before every outgoing HTTP request.
2. WHEN `currentStatus` is `Connection_Status.disconnected` at the time of a request, THE `Connectivity_Interceptor` SHALL reject the request and throw a `No_Internet_Exception` with the reason `disconnected`.
3. WHEN `currentStatus` is `Connection_Status.slow` at the time of a request, THE `Connectivity_Interceptor` SHALL allow the request to proceed and attach a custom header `X-Connection-Quality: slow` to the outgoing request.
4. WHEN `currentStatus` is `Connection_Status.connected` at the time of a request, THE `Connectivity_Interceptor` SHALL allow the request to proceed without modification.
5. THE `No_Internet_Exception` SHALL conform to the existing `ApiException` interface so that existing error-handling code in view models requires no changes.

---

### Requirement 4: UI Feedback for Connectivity State

**User Story:** As a mobile user, I want to see a visible indicator when I am offline or on a slow connection, so that I understand why the app is not responding normally.

#### Acceptance Criteria

1. THE `Connectivity_Widget` SHALL accept a `child` widget and wrap it with a reactive listener on the `Connectivity_Service` stream.
2. WHEN `Connection_Status` is `disconnected`, THE `Connectivity_Widget` SHALL display a non-dismissible banner above the content indicating the device is offline.
3. WHEN `Connection_Status` is `slow`, THE `Connectivity_Widget` SHALL display a dismissible banner above the content indicating the connection is slow.
4. WHEN `Connection_Status` transitions to `connected`, THE `Connectivity_Widget` SHALL hide any active connectivity banner.
5. THE `Connectivity_Widget` SHALL remain accessible: the offline banner SHALL have a semantic label readable by screen readers.

---

### Requirement 5: Error Handling and Resilience

**User Story:** As a developer, I want the connectivity service to handle internal failures gracefully, so that a bug in the connectivity layer does not crash the app.

#### Acceptance Criteria

1. IF the `Speed_Probe` throws an unhandled exception, THEN THE `Connectivity_Service` SHALL catch the exception, log it using the existing `logger` utility, and emit `Connection_Status.disconnected`.
2. IF the `Connectivity_Service` stream subscription is cancelled and then re-subscribed, THEN THE `Connectivity_Service` SHALL immediately emit the current `Connection_Status` to the new subscriber.
3. THE `Connectivity_Service` SHALL expose a `dispose` method that cancels all timers and stream controllers without throwing.
4. WHEN the app is resumed from background, THE `Connectivity_Service` SHALL perform an immediate `Speed_Probe` to refresh the `Connection_Status`.

---

### Requirement 6: Testability and Configuration

**User Story:** As a developer, I want to inject a mock connectivity service in tests, so that I can write unit and widget tests without requiring a real network.

#### Acceptance Criteria

1. THE `Connectivity_Service` SHALL implement an abstract `IConnectivity_Service` interface that exposes `Stream<Connection_Status> statusStream`, `Connection_Status currentStatus`, and `Future<void> dispose()`.
2. WHERE a `IConnectivity_Service` implementation is provided via dependency injection, THE `Connectivity_Interceptor` SHALL use the injected implementation instead of the default singleton.
3. THE `Connectivity_Service` SHALL accept a `speedProbeUrl` parameter at construction time so that tests can point the `Speed_Probe` at a local server.
4. THE `Connectivity_Service` SHALL accept a `slowThresholdMs` parameter at construction time to override the default `Slow_Threshold`.
