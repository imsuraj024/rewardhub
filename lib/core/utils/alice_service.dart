import 'package:flutter/foundation.dart';
import 'package:flutter_alice/alice.dart';

/// Whether the Alice HTTP inspector is available in this build.
///
/// This is a compile-time constant: release and profile builds are always
/// `false`, so the shake-to-open inspector, its notification and the Dio
/// interceptor can never ship to users — passing `--dart-define=alice` to a
/// release build has no effect.
///
/// Enable it while developing with:
///   flutter run --dart-define=alice
const bool aliceEnabled = kDebugMode && bool.hasEnvironment('alice');

/// The inspector instance, or `null` when [aliceEnabled] is false.
///
/// Never dereference this without a null check — everything Alice-related
/// (navigator key, interceptor, shake handler) must stay behind it.
final Alice? aliceRef = aliceEnabled
    ? Alice(
        showNotification: true,
        showInspectorOnShake: true,
        darkTheme: true,
      )
    : null;
