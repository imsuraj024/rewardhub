import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rewardhub/core/utils/logger.dart';

/// Keystore-backed store for the authentication token.
///
/// The JWT grants access to a user's rewards balance and KYC record, so it is
/// held in the iOS Keychain / Android Keystore rather than in
/// [SharedPreferences] — the latter is a plain-text file that any process with
/// filesystem access on a rooted or jailbroken device can read.
///
/// A single instance is shared app-wide (see the [SecureTokenStore] factory) so
/// the in-memory cache is shared too: every authenticated request needs the
/// token, and each cache miss costs a platform-channel round trip plus a
/// decryption.
class SecureTokenStore {
  SecureTokenStore._internal();

  factory SecureTokenStore() => _instance;

  static final SecureTokenStore _instance = SecureTokenStore._internal();

  static const _kTokenKey = 'auth_token';

  /// Written by builds that predate this store, and migrated away by
  /// [_migrateLegacyToken].
  static const _kLegacyIsLoggedInKey = 'is_logged_in';

  static const _storage = FlutterSecureStorage(
    // Builds on flutter_secure_storage v9 wrote the token with the legacy
    // ciphers; v10 re-encrypts it on first read. The backup lets an app kill
    // mid-migration recover instead of signing the user out.
    aOptions: AndroidOptions(migrateWithBackup: true),
    // Readable after the first unlock following a reboot, so a background
    // refresh does not fail on a locked device, and never restored onto a
    // different device from an encrypted backup.
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  String? _cached;
  bool _loaded = false;
  Future<String?>? _pendingLoad;

  /// The stored token, or `null` when there is no session.
  Future<String?> read() {
    if (_loaded) return Future.value(_cached);
    // Requests fired in parallel on a cold start must not each trigger their
    // own decrypt-and-migrate pass.
    return _pendingLoad ??= _load().whenComplete(() => _pendingLoad = null);
  }

  /// Persists [token], replacing any existing one.
  Future<void> write(String token) async {
    // Cached first: if the platform write fails the current session still
    // works until the app is restarted, instead of dying mid-flow.
    _cached = token;
    _loaded = true;
    try {
      await _storage.write(key: _kTokenKey, value: token);
    } catch (e, st) {
      log(
        'secure token write failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Removes the token from secure storage and from memory.
  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _deleteQuietly();
    await _clearLegacyKeys();
  }

  Future<String?> _load() async {
    String? token;
    try {
      token = await _storage.read(key: _kTokenKey);
    } catch (e, st) {
      // Android throws when the Keystore entry can no longer be decrypted —
      // typically a restored backup or a rotated key. The token is
      // unrecoverable, so drop it and let the user sign in again.
      log(
        'secure token read failed; discarding entry',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
      await _deleteQuietly();
    }

    token ??= await _migrateLegacyToken();

    _cached = token;
    _loaded = true;
    return token;
  }

  /// Moves a token left behind in [SharedPreferences] by an older build.
  ///
  /// Without this, upgrading users would be silently signed out. The plain-text
  /// copy is deleted only once the secure write has succeeded, so an
  /// interrupted migration retries on the next read instead of losing the
  /// session.
  Future<String?> _migrateLegacyToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_kTokenKey);
      if (legacy == null || legacy.isEmpty) return null;

      await _storage.write(key: _kTokenKey, value: legacy);
      await prefs.remove(_kTokenKey);
      await prefs.remove(_kLegacyIsLoggedInKey);
      log('migrated auth token to secure storage', name: 'rewardhub.auth');
      return legacy;
    } catch (e, st) {
      log(
        'auth token migration failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> _deleteQuietly() async {
    try {
      await _storage.delete(key: _kTokenKey);
    } catch (e, st) {
      log(
        'secure token delete failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Drops the pre-migration plain-text keys, so a logout that happens before
  /// the first [read] cannot leave a readable token on disk.
  Future<void> _clearLegacyKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTokenKey);
      await prefs.remove(_kLegacyIsLoggedInKey);
    } catch (e, st) {
      log(
        'clearing legacy auth keys failed',
        name: 'rewardhub.auth',
        error: e,
        stackTrace: st,
      );
    }
  }
}
