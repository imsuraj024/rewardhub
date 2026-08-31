import 'package:rewardhub/core/storage/secure_token_store.dart';

/// Local data source for persisting the authentication session.
///
/// The token is held by [SecureTokenStore] (Keychain / Keystore), and the
/// presence of a token *is* the session — there is no separate logged-in flag
/// that could drift out of sync with it.
abstract interface class AuthLocalDataSource {
  Future<String?> readToken();
  Future<bool> readIsLoggedIn();
  Future<void> saveSession(String token);
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({SecureTokenStore? tokenStore})
    : _tokens = tokenStore ?? SecureTokenStore();

  final SecureTokenStore _tokens;

  @override
  Future<String?> readToken() => _tokens.read();

  @override
  Future<bool> readIsLoggedIn() async {
    final token = await _tokens.read();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> saveSession(String token) => _tokens.write(token);

  @override
  Future<void> clearSession() => _tokens.clear();
}
