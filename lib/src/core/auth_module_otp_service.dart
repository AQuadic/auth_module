part of 'auth_module_service.dart';

class _AuthOtpService {
  _AuthOtpService(this._module);

  final AuthModule _module;

  Future<AuthResult<void>> requestPhoneOtpLogin({
    required String phoneCountry,
    required String phone,
    String? verifyType,
  }) async {
    final value = await _module._safePost(
      _module.config.loginEndpoint,
      body: {
        'phone_country': phoneCountry,
        'phone': phone,
        'verify_type': verifyType ?? _module.config.defaultPhoneOtpVerifyType,
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
    if (token != null && token.isNotEmpty) {
      _module._tempToken = token;
    }

    final userJson = data[_module.config.userResponseKey];
    if (userJson is Map<String, dynamic>) {
      _module._user = UserModel.fromJson(userJson);
    }

    final otpCallback = data[_module.config.otpCallbackResponseKey];
    if (otpCallback is Map<String, dynamic>) {
      _module._otpResponse = OtpResponse.fromJson(otpCallback);
    }

    return AuthResult.success(
      message: data[_module.config.messageResponseKey]?.toString(),
    );
  }

  Future<AuthResult<void>> resendOtp({
    String? phone,
    String? email,
    String? phoneCountry,
    bool isNew = false,
    String? verifyType,
  }) async {
    final currentToken = await _module._getToken();
    final isEmail = email != null && email.isNotEmpty;

    final value = await _module._safePost(
      _module.config.resendEndpoint,
      token: _module._tempToken ?? currentToken,
      body: {
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (phoneCountry != null && phoneCountry.isNotEmpty)
          'phone_country': phoneCountry,
        'verify_type':
            verifyType ??
            (isEmail
                ? _module.config.defaultResendEmailVerifyType
                : _module.config.defaultPhoneOtpVerifyType),
        if (isNew) 'type': 'new',
      },
    );

    if (value is! Response) {
      return AuthResult.failure(_module._resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    final otpCallback = data[_module.config.otpCallbackResponseKey];
    if (otpCallback is Map<String, dynamic>) {
      _module._otpResponse = OtpResponse.fromJson(otpCallback);
    }

    return AuthResult.success(
      message: data[_module.config.messageResponseKey]?.toString(),
    );
  }
}
