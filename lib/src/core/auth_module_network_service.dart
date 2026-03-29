part of 'auth_module_service.dart';

class _AuthNetworkService {
  _AuthNetworkService(this._module);

  final AuthModule _module;

  Future<dynamic> safePost(
    String endpoint, {
    Map<String, dynamic>? body,
    FormData? multiPartBody,
    String? token,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _module._networkClient.post(
        endpoint,
        body: body,
        multiPartBody: multiPartBody,
        token: token,
        cancelToken: cancelToken,
      );
    } catch (e) {
      return e.toString();
    }
  }

  Future<dynamic> safeDelete(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      return await _module._networkClient.delete(
        endpoint,
        body: body,
        token: token,
      );
    } catch (e) {
      return e.toString();
    }
  }

  Future<dynamic> safeGet(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      return await _module._networkClient.get(endpoint, body: body, token: token);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> getToken() async {
    try {
      final userToken = await UserModel.getToken;
      if (userToken != null && userToken.isNotEmpty) {
        _module._token = userToken;
        await _module._tokenStorage.saveToken(userToken);
        return userToken;
      }
    } catch (_) {}

    final storedToken = await _module._tokenStorage.getToken();
    if (storedToken != null && storedToken.isNotEmpty) {
      _module._token = storedToken;
      try {
        await UserModel.saveToken(storedToken);
      } catch (_) {}
      return storedToken;
    }

    return _module._token;
  }

  String resolveErrorMessage(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }

    if (value is Response) {
      final data = value.data;
      if (data is Map<String, dynamic>) {
        final message = data[_module.config.messageResponseKey];
        if (message != null) {
          return message.toString();
        }
        final error = data['error'];
        if (error != null) {
          return error.toString();
        }
      }
      return 'Request failed';
    }

    if (value is Map<String, dynamic>) {
      final message = value[_module.config.messageResponseKey];
      if (message != null) {
        return message.toString();
      }
      final error = value['error'];
      if (error != null) {
        return error.toString();
      }
    }

    return 'Unknown auth error';
  }

  bool isNotBlank(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
