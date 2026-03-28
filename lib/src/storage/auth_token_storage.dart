abstract class AuthTokenStorage {
  Future<String?> getToken();

  Future<void> saveToken(String? token);

  Future<void> clearToken();
}
