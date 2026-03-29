part of 'auth_module_service.dart';

class _AuthUserService {
  _AuthUserService(this._module);

  final AuthModule _module;

  Future<AuthResult<UserModel>> updateUser({
    XFile? image,
    String? email,
    String? name,
    String? countryCode,
    String? phone,
    DateTime? birthday,
    String? gender,
  }) async {
    final currentToken = await _module._getToken();
    if (currentToken == null || currentToken.isEmpty) {
      return AuthResult.failure('Not authenticated.');
    }

    final value = await _module._safePost(
      _module.config.updateUserDataEndpoint,
      token: currentToken,
      multiPartBody: FormData.fromMap({
        if (_module._isNotBlank(name)) 'name': name,
        if (_module._isNotBlank(email)) 'email': email,
        if (_module._isNotBlank(countryCode) && _module._isNotBlank(phone))
          'phone_country': countryCode,
        if (_module._isNotBlank(phone)) 'phone': phone,
        if (birthday != null)
          'birthday': birthday.toIso8601String().split('T')[0],
        if (_module._isNotBlank(gender)) 'gender': gender,
        if (image != null) 'image': await MultipartFile.fromFile(image.path),
      }),
    );

    if (value is! Response) {
      return AuthResult.failure(_module._resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    final userJson = data[_module.config.userResponseKey];
    if (userJson is Map<String, dynamic>) {
      _module._user = UserModel.fromJson(userJson);
      return AuthResult.success(
        data: _module._user,
        message: data[_module.config.messageResponseKey]?.toString(),
      );
    }

    _module._user = UserModel.fromJson(data);
    return AuthResult.success(
      data: _module._user,
      message: data[_module.config.messageResponseKey]?.toString(),
    );
  }

  Future<AuthResult<UserModel>> fetchCurrentUser() async {
    final currentToken = await _module._getToken();
    final value = await _module._safeGet(
      _module.config.userEndpoint,
      token: currentToken,
    );

    if (value is! Response) {
      return AuthResult.failure(_module._resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    final userJson = data[_module.config.userResponseKey];
    if (userJson is Map<String, dynamic>) {
      _module._user = UserModel.fromJson(userJson);
      return AuthResult.success(
        data: _module._user,
        message: data[_module.config.messageResponseKey]?.toString(),
      );
    }

    _module._user = UserModel.fromJson(data);
    return AuthResult.success(
      data: _module._user,
      message: data[_module.config.messageResponseKey]?.toString(),
    );
  }

  Future<AuthResult<void>> addDevice({bool? enabled}) async {
    final currentToken = await _module._getToken();
    if (currentToken == null || currentToken.isEmpty) {
      return AuthResult.failure('Not authenticated.');
    }

    try {
      await _module.notificationModule.setToken(currentToken);
      await _module.notificationModule.addDevice(enabled: enabled);
      if (enabled != null) {
        _module._isNotificationEnabled = enabled;
      }
      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  Future<AuthResult<void>> deleteAccount() async {
    final currentToken = await _module._getToken();
    if (currentToken == null || currentToken.isEmpty) {
      return AuthResult.failure('Not authenticated.');
    }

    final value = await _module._safeDelete(
      _module.config.deleteAccountEndpoint,
      token: currentToken,
    );

    if (value is! Response) {
      return AuthResult.failure(_module._resolveErrorMessage(value));
    }

    String? message;
    final data = value.data;
    if (data is Map<String, dynamic>) {
      message = data[_module.config.messageResponseKey]?.toString();
    }

    await logout(callApi: false);
    return AuthResult.success(message: message);
  }

  Future<AuthResult<void>> logout({bool callApi = true}) async {
    final currentToken = await _module._getToken();
    if (callApi && currentToken != null && currentToken.isNotEmpty) {
      await _module._safePost(_module.config.logoutEndpoint, token: currentToken);
    }

    _module._token = null;
    _module._tempToken = null;
    _module._user = null;
    _module._otpResponse = null;

    await _module._tokenStorage.clearToken();
    try {
      await UserModel.saveToken(null);
    } catch (_) {}

    try {
      await _module.notificationModule.setToken(null);
      await _module.notificationModule.deleteFCMToken();
    } catch (_) {}

    return AuthResult.success();
  }
}
