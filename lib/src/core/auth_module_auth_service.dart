part of 'auth_module_service.dart';

class _AuthAuthService {
  _AuthAuthService(this._module);

  final AuthModule _module;

  Future<AuthResult<UserModel>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final value = await _module._safePost(
      _module.config.loginEndpoint,
      body: {'email': email, 'password': password},
    );

    return _handleAuthResponse(value);
  }

  Future<AuthResult<UserModel>> loginWithPhoneAndPassword({
    required String phoneCountry,
    required String phone,
    required String password,
  }) async {
    final value = await _module._safePost(
      _module.config.loginEndpoint,
      body: {
        'phone_country': phoneCountry,
        'phone': phone,
        'password': password,
      },
    );

    return _handleAuthResponse(value);
  }

  Future<AuthResult<UserModel>> _sendTokenToServer({
    required String provider,
    required String accessToken,
    String? idToken,
  }) async {
    if (!_module._isNotBlank(provider)) {
      return AuthResult.failure('Provider is required.');
    }
    if (!_module._isNotBlank(accessToken)) {
      return AuthResult.failure('Access token is required.');
    }

    final body = <String, dynamic>{
      'provider': provider,
      'access_token': accessToken,
      if (_module._isNotBlank(idToken)) 'id_token': idToken,
    };

    final value = await _module._safePost(
      _module.config.socialLoginEndpoint,
      body: body,
    );

    final result = await _handleAuthResponse(value);
    if (result.isSuccess) {
      await _module.addDevice();
    }
    return result;
  }

  Future<AuthResult<UserModel>> _sendFirebaseTokenToServer({
    required String accessToken,
    String provider = 'FIREBASE',
    String? idToken,
  }) async {
    if (!_module._isNotBlank(accessToken)) {
      return AuthResult.failure('Access token is required.');
    }

    final body = <String, dynamic>{
      'provider': provider,
      'access_token': accessToken,
      if (_module._isNotBlank(idToken)) 'id_token': idToken,
    };

    final value = await _module._safePost(
      _module.config.firebaseLoginEndpoint,
      body: body,
    );

    final result = await _handleAuthResponse(value);
    if (result.isSuccess) {
      await _module.addDevice();
    }
    return result;
  }

  Future<AuthResult<UserModel>> loginWithSocial({
    required SocialProvider provider,
  }) async {
    final signInResult = await _module._socialSignInClient.signIn(
      provider: provider.name,
      config: _module.config,
    );

    if (!signInResult.isSuccess || signInResult.credentials == null) {
      return AuthResult.failure(
        signInResult.message ?? 'Social sign-in failed.',
      );
    }

    final credentials = signInResult.credentials!;
    return _sendTokenToServer(
      provider: credentials.provider,
      accessToken: credentials.accessToken,
      idToken: credentials.idToken,
    );
  }

  Future<AuthResult<UserModel>> loginWithFirebaseIdToken({
    required String idToken,
    String provider = 'FIREBASE',
  }) async {
    if (!_module._isNotBlank(idToken)) {
      return AuthResult.failure('Firebase ID token is required.');
    }

    return _sendFirebaseTokenToServer(
      accessToken: idToken,
      idToken: idToken,
      provider: provider,
    );
  }

  Future<AuthResult<UserModel>> loginWithFirebasePhoneOtp({
    required String verificationId,
    required String smsCode,
    String provider = 'FIREBASE',
  }) async {
    return verifyFirebasePhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
      provider: provider,
    );
  }

  Future<AuthResult<void>> sendFirebasePhoneOtp({
    required String phoneNumber,
    Duration timeout = const Duration(seconds: 60),
    int? forceResendingToken,
  }) async {
    if (!_module._isNotBlank(phoneNumber)) {
      return AuthResult.failure('phoneNumber is required.');
    }

    final completer = Completer<AuthResult<void>>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (!completer.isCompleted) {
          completer.complete(
            AuthResult.success(
              message:
                  'Phone auto-verification completed. You can continue login flow.',
            ),
          );
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.complete(
            AuthResult.failure(
              e.message ?? 'Firebase phone verification failed: ${e.code}',
            ),
          );
        }
      },
      codeSent: (String verificationId, int? _) {
        _module._firebaseVerificationId = verificationId;
        if (!completer.isCompleted) {
          completer.complete(
            AuthResult.success(message: 'OTP has been sent successfully.'),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _module._firebaseVerificationId = verificationId;
      },
    );

    return completer.future;
  }

  Future<AuthResult<UserModel>> verifyFirebasePhoneOtp({
    required String smsCode,
    String provider = 'FIREBASE',
    String? verificationId,
  }) async {
    final activeVerificationId =
        verificationId ?? _module._firebaseVerificationId;
    if (!_module._isNotBlank(activeVerificationId)) {
      return AuthResult.failure(
        'verificationId is missing. Call sendFirebasePhoneOtp first.',
      );
    }
    if (!_module._isNotBlank(smsCode)) {
      return AuthResult.failure('smsCode is required.');
    }
    final safeVerificationId = activeVerificationId!;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: safeVerificationId,
        smsCode: smsCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final idToken = await userCredential.user?.getIdToken();
      if (!_module._isNotBlank(idToken)) {
        return AuthResult.failure(
          'Firebase ID token is missing after phone sign-in.',
        );
      }
      final safeIdToken = idToken!;

      return _sendFirebaseTokenToServer(
        accessToken: safeIdToken,
        provider: provider,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        e.message ?? 'Firebase phone authentication failed: ${e.code}',
      );
    } catch (e) {
      return AuthResult.failure('Firebase phone authentication failed: $e');
    }
  }

  Future<AuthResult<UserModel>> verifyOtp({
    required String code,
    String? email,
    String? phone,
    String? phoneCountry,
    String? type,
  }) async {
    final currentToken = await _module._getToken();
    final value = await _module._safePost(
      _module.config.verifyEndpoint,
      token: _module._tempToken ?? currentToken,
      body: {
        'code': code,
        'type': type ?? _module.config.defaultVerifyType,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (phoneCountry != null && phoneCountry.isNotEmpty)
          'phone_country': phoneCountry,
      },
    );

    return _handleAuthResponse(value);
  }

  Future<AuthResult<UserModel>> checkPhoneOtpState({
    required String phone,
    required String phoneCountry,
    String? reference,
    CancelToken? cancelToken,
  }) async {
    final currentToken = await _module._getToken();
    final value = await _module._safePost(
      _module.config.checkStateOfAccountEndpoint,
      token: _module._tempToken ?? currentToken,
      cancelToken: cancelToken,
      body: {
        'phone_country': phoneCountry,
        'phone': phone,
        'reference': reference ?? _module._otpResponse?.reference,
      },
    );

    return _handleAuthResponse(value);
  }

  Future<AuthResult<UserModel>> signUp({
    required String name,
    String? email,
    String? password,
    String? passwordConfirmation,
    String? phoneCountry,
    String? phone,
    int? countryId,
    MultipartFile? image,
  }) async {
    final value = await _module._safePost(
      _module.config.signupEndpoint,
      multiPartBody: FormData.fromMap({
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
        if (passwordConfirmation != null && passwordConfirmation.isNotEmpty)
          'password_confirmation': passwordConfirmation,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (phoneCountry != null && phoneCountry.isNotEmpty)
          'phone_country': phoneCountry,
        if (countryId != null) 'country_id': countryId.toString(),
        if (image != null) 'image': image,
      }),
    );

    final result = await _handleAuthResponse(value);
    if (result.isSuccess) {
      await _module.addDevice();
    }
    return result;
  }

  Future<AuthResult<UserModel>> _handleAuthResponse(dynamic value) async {
    if (value is! Response) {
      return AuthResult.failure(_module._resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    final token = data[_module.config.authTokenResponseKey]?.toString();
    if (token == null || token.isEmpty) {
      return AuthResult.failure('Token was not found in auth response.');
    }

    final userJson = data[_module.config.userResponseKey];
    if (userJson is! Map<String, dynamic>) {
      return AuthResult.failure('User was not found in auth response.');
    }

    _module._user = UserModel.fromJson(userJson);
    _module._token = token;
    _module._tempToken = token;

    final resetToken = data['reset_token']?.toString();
    if (_module._isNotBlank(resetToken)) {
      await UserModel.saveResetPassToken(resetToken!);
    }

    await _module._tokenStorage.saveToken(token);
    try {
      await UserModel.saveToken(token);
    } catch (_) {}

    try {
      await _module.notificationModule.setToken(token);
    } catch (_) {}

    return AuthResult.success(
      data: _module._user,
      message: data[_module.config.messageResponseKey]?.toString(),
    );
  }
}
