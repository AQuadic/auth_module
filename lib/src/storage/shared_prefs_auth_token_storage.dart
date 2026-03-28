import 'package:shared_preferences/shared_preferences.dart';

import 'auth_token_storage.dart';

class SharedPrefsAuthTokenStorage implements AuthTokenStorage {
  SharedPrefsAuthTokenStorage({required this.key});

  final String key;

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, token);
  }
}
