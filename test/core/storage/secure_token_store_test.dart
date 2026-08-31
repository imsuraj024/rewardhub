import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewardhub/core/storage/secure_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [SecureTokenStore] is an app-wide singleton, so its in-memory cache and
/// `_loaded` flag persist for the lifetime of this test isolate. The very first
/// store call in this file therefore runs against a cold cache (`_loaded ==
/// false`) and is the only chance to exercise the load/migration path — it is
/// deliberately declared first. Subsequent tests establish known state through
/// `write`/`clear`, which set the cache directly and never touch the load path.
void main() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const tokenKey = 'auth_token';

  late TestWidgetsFlutterBinding binding;
  late Map<String, String> secureBacking;
  bool failWrites = false;

  binding = TestWidgetsFlutterBinding.ensureInitialized();

  void installSecureHandler() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (MethodCall call) async {
      final args =
          (call.arguments as Map?)?.cast<String, dynamic>() ?? const {};
      switch (call.method) {
        case 'read':
          return secureBacking[args['key'] as String];
        case 'write':
          if (failWrites) {
            throw PlatformException(code: 'write_failed');
          }
          secureBacking[args['key'] as String] = args['value'] as String;
          return null;
        case 'delete':
          secureBacking.remove(args['key']);
          return null;
        case 'deleteAll':
          secureBacking.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(secureBacking);
        case 'containsKey':
          return secureBacking.containsKey(args['key']);
        default:
          return null;
      }
    });
  }

  setUp(() {
    secureBacking = {};
    failWrites = false;
    installSecureHandler();
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  // MUST run first: exercises the cold-start load + legacy migration path.
  group('cold start (runs first)', () {
    test('positive: migrates a legacy SharedPreferences token', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'legacy-jwt',
        'is_logged_in': true,
      });

      final store = SecureTokenStore();
      final token = await store.read();

      // Legacy token returned to the caller...
      expect(token, 'legacy-jwt');
      // ...promoted into secure storage...
      expect(secureBacking[tokenKey], 'legacy-jwt');
      // ...and removed from the plain-text prefs.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('is_logged_in'), isNull);
    });
  });

  group('write / read', () {
    test('positive: written token is readable and persisted', () async {
      final store = SecureTokenStore();

      await store.write('jwt-123');

      expect(await store.read(), 'jwt-123');
      expect(secureBacking[tokenKey], 'jwt-123');
    });

    test('edge: overwriting replaces the previous token', () async {
      final store = SecureTokenStore();

      await store.write('first');
      await store.write('second');

      expect(await store.read(), 'second');
      expect(secureBacking[tokenKey], 'second');
    });

    test('edge: in-memory cache serves reads without hitting storage',
        () async {
      final store = SecureTokenStore();
      await store.write('cached');

      // Mutate the backing store behind the cache's back.
      secureBacking[tokenKey] = 'changed-underneath';

      // The cached value still wins.
      expect(await store.read(), 'cached');
    });

    test('edge: write failure is swallowed; session survives in cache',
        () async {
      final store = SecureTokenStore();
      failWrites = true;

      // Should not throw even though the platform write fails.
      await store.write('resilient');

      expect(await store.read(), 'resilient');
      // Nothing landed in the (failing) backing store.
      expect(secureBacking.containsKey(tokenKey), isFalse);
    });
  });

  group('clear', () {
    test('positive: clear removes the token from cache and storage', () async {
      final store = SecureTokenStore();
      await store.write('to-be-cleared');

      await store.clear();

      expect(await store.read(), isNull);
      expect(secureBacking.containsKey(tokenKey), isFalse);
    });

    test('edge: clear on an empty store leaves it null', () async {
      final store = SecureTokenStore();

      await store.clear();

      expect(await store.read(), isNull);
    });
  });
}
