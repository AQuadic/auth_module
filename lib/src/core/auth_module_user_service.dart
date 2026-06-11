part of 'auth_module_service.dart';

class _AuthUserService {
  _AuthUserService(this._module);

  final AuthModule _module;

  Future<AuthResult<void>> forgotPassword({
    String? email,
    String? phoneCountry,
    String? phone,
    String? resetType,
  }) async {
    final hasEmail = _module._isNotBlank(email);
    final hasPhone =
        _module._isNotBlank(phone) && _module._isNotBlank(phoneCountry);

    if (!hasEmail && !hasPhone) {
      return AuthResult.failure(
        'Either email or phoneCountry and phone are required.',
      );
    }

    final effectiveResetType =
        resetType ??
        (hasEmail
            ? _module.config.defaultResendEmailVerifyType
            : _module.config.defaultPhoneOtpVerifyType);

    final value = await _module._safePost(
      _module.config.forgetPasswordEndpoint,
      body: {
        if (hasEmail) 'email': email,
        if (hasPhone) 'phone_country': phoneCountry,
        if (hasPhone) 'phone': phone,
        'reset_type': effectiveResetType,
      },
    );

    if (value is! Response) {
      return AuthResult.failure(_module._resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    final token = data[_module.config.authTokenResponseKey]?.toString();
    if (_module._isNotBlank(token)) {
      _module._tempToken = token;
    }

    final otpCallback = data[_module.config.otpCallbackResponseKey];
    if (otpCallback is Map<String, dynamic>) {
      _module._otpResponse = OtpResponse.fromJson(otpCallback);
    }

    return AuthResult.success(
      message: data[_module.config.messageResponseKey]?.toString(),
    );
  }

  Future<AuthResult<void>> resetPassword({
    String? email,
    String? phone,
    String? phoneCountry,
    required String password,
    required String passwordConfirmation,
    String? resetToken,
    String? resetType,
  }) async {
    final hasEmail = _module._isNotBlank(email);
    final hasPhone =
        _module._isNotBlank(phone) && _module._isNotBlank(phoneCountry);

    if (!hasEmail && !hasPhone) {
      return AuthResult.failure(
        'Either email or phone and phoneCountry are required.',
      );
    }
    if (!_module._isNotBlank(password) ||
        !_module._isNotBlank(passwordConfirmation)) {
      return AuthResult.failure(
        'password and passwordConfirmation are required.',
      );
    }

    final storedResetToken = await UserModel.getResetPassToken;
    final effectiveResetToken = _module._isNotBlank(resetToken)
        ? resetToken
        : storedResetToken;

    if (!_module._isNotBlank(effectiveResetToken)) {
      return AuthResult.failure(
        'resetToken is missing. Complete forgot/check-state flow first.',
      );
    }

    final effectiveResetType =
        resetType ??
        (hasEmail
            ? _module.config.defaultResendEmailVerifyType
            : _module.config.defaultPhoneOtpVerifyType);

    final value = await _module._safePost(
      _module.config.forgetPasswordEndpoint,
      body: {
        if (hasEmail) 'email': email,
        if (hasPhone) 'phone': phone,
        if (hasPhone) 'phone_country': phoneCountry,
        'reset_token': effectiveResetToken,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'reset_type': effectiveResetType,
      },
    );

    if (value is! Response) {
      return AuthResult.failure(_module._resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    return AuthResult.success(
      message: data[_module.config.messageResponseKey]?.toString(),
    );
  }

  Future<AuthResult<void>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!_module._isNotBlank(oldPassword) ||
        !_module._isNotBlank(newPassword) ||
        !_module._isNotBlank(confirmPassword)) {
      return AuthResult.failure(
        'oldPassword, newPassword and confirmPassword are required.',
      );
    }

    final currentToken = await _module._getToken();
    if (!_module._isNotBlank(currentToken)) {
      return AuthResult.failure('Not authenticated.');
    }

    final value = await _module._safePost(
      _module.config.changeCurrentPasswordEndpoint,
      token: currentToken,
      body: {
        'current_password': oldPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      },
    );

    if (value is! Response) {
      return AuthResult.failure(_module._resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    return AuthResult.success(
      message: data[_module.config.messageResponseKey]?.toString(),
    );
  }

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
    final value = await _module._safePost(
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

  Future<AuthResult<void>> logout({
    bool callApi = true,
    bool withFirebase = true,
  }) async {
    final currentToken = await _module._getToken();
    if (callApi && currentToken != null && currentToken.isNotEmpty) {
      await _module._safePost(
        _module.config.logoutEndpoint,
        token: currentToken,
      );
    }

    if (withFirebase) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }

    _module._token = null;
    _module._tempToken = null;
    _module._firebaseVerificationId = null;
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
