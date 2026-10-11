import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:rewardhub/core/utils/app_toast.dart';
import 'package:rewardhub/core/utils/logger.dart';

/// Opens a URI the way url_launcher's `launchUrl` does.
typedef UriOpener = Future<bool> Function(Uri uri, LaunchMode mode);

/// Opens phone, email and store links in other apps, with a copy fallback.
///
/// Never calls `canLaunchUrl`: the manifest has no `<queries>` entry and
/// Info.plist has no `LSApplicationQueriesSchemes`, so it returns false for
/// tel:/mailto:/https on Android 11+ and iOS even when a handler exists.
abstract final class ExternalLinks {
  /// Test hook, like [AppToast.presenter]. null → url_launcher's `launchUrl`.
  @visibleForTesting
  static UriOpener? opener;

  /// Returns true only when the platform reports that something opened.
  /// Never throws.
  static Future<bool> open(
    Uri uri, {
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    try {
      final o = opener ?? ((Uri u, LaunchMode m) => launchUrl(u, mode: m));
      return await o(uri, mode);
    } catch (e, st) {
      log(
        'Could not open $uri',
        name: 'rewardhub.links',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Copies [text] and shows [message] as a success toast.
  static Future<void> copy(String text, {required String message}) async {
    await Clipboard.setData(ClipboardData(text: text));
    AppToast.success(message);
  }

  /// Opens [uri]. If nothing opened, copies [fallbackText] and shows
  /// [fallbackMessage] as an info toast. Returns whether [uri] opened.
  static Future<bool> openOrCopy(
    Uri uri, {
    required String fallbackText,
    required String fallbackMessage,
  }) async {
    final opened = await open(uri);
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: fallbackText));
      AppToast.info(fallbackMessage);
    }
    return opened;
  }

  /// '+91 98765 43210' → tel:+919876543210
  static Uri phone(String number) =>
      Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'[^0-9+]'), ''));

  /// ' support@x.com ' → mailto:support@x.com
  static Uri email(String address) =>
      Uri(scheme: 'mailto', path: address.trim());
}
