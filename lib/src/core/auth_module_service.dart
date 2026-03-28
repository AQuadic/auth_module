import 'package:dio/dio.dart';
import 'package:cross_file/cross_file.dart';

import '../models/auth_result.dart';
import '../models/otp_response.dart';
import '../models/user_model.dart';
import '../network/auth_network_client.dart';
import '../network/dio_helper_network_client.dart';
import '../storage/auth_token_storage.dart';
import '../storage/shared_prefs_auth_token_storage.dart';
import 'auth_module_config.dart';

class AuthModule {
  AuthModule({
    required AuthNetworkClient networkClient,
    required this.config,
    required this.notificationModule,
    AuthTokenStorage? tokenStorage,
  }) : _networkClient = networkClient,
       _tokenStorage =
           tokenStorage ??
           SharedPrefsAuthTokenStorage(key: config.persistTokenStorageKey);

  factory AuthModule.init({
    required dynamic dioHelper,
    required dynamic notificationModule,
    AuthModuleConfig config = const AuthModuleConfig(),
    AuthTokenStorage? tokenStorage,
  }) {
    return AuthModule(
      networkClient: DioHelperNetworkClient(dioHelper),
      config: config,
      notificationModule: notificationModule,
      tokenStorage: tokenStorage,
    );
  }

  final AuthNetworkClient _networkClient;
  final AuthTokenStorage _tokenStorage;

  final AuthModuleConfig config;
  final dynamic notificationModule;

  String? _token;
  String? _tempToken;
  UserModel? _user;
  OtpResponse? _otpResponse;
  bool? _isNotificationEnabled;

  UserModel? get user => _user;
  String? get token => _token;
  String? get tempToken => _tempToken;
  OtpResponse? get otpResponse => _otpResponse;
  bool get isLoggedIn => (_token?.isNotEmpty ?? false) && _user != null;
  bool? get isNotificationEnabled => _isNotificationEnabled;

  Future<void> init() async {
    _token = await _getToken();
  }

  Future<AuthResult<UserModel>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final value = await _safePost(
      config.loginEndpoint,
      body: {'email': email, 'password': password},
    );

    return _handleAuthResponse(value);
  }

  Future<AuthResult<UserModel>> loginWithPhoneAndPassword({
    required String phoneCountry,
    required String phone,
    required String password,
  }) async {
    final value = await _safePost(
      config.loginEndpoint,
      body: {
        'phone_country': phoneCountry,
        'phone': phone,
        'password': password,
      },
    );

    return _handleAuthResponse(value);
  }

  Future<AuthResult<void>> requestPhoneOtpLogin({
    required String phoneCountry,
    required String phone,
    String? verifyType,
  }) async {
    final value = await _safePost(
      config.loginEndpoint,
      body: {
        'phone_country': phoneCountry,
        'phone': phone,
        'verify_type': verifyType ?? config.defaultPhoneOtpVerifyType,
      },
    );

    if (value is! Response) {
      return AuthResult.failure(_resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    final token = data[config.authTokenResponseKey]?.toString();
    if (token != null && token.isNotEmpty) {
      _tempToken = token;
    }

    final userJson = data[config.userResponseKey];
    if (userJson is Map<String, dynamic>) {
      _user = UserModel.fromJson(userJson);
    }

    final otpCallback = data[config.otpCallbackResponseKey];
    if (otpCallback is Map<String, dynamic>) {
      _otpResponse = OtpResponse.fromJson(otpCallback);
    }

    return AuthResult.success(
      message: data[config.messageResponseKey]?.toString(),
    );
  }

  Future<AuthResult<void>> resendOtp({
    String? phone,
    String? email,
    String? phoneCountry,
    bool isNew = false,
    String? verifyType,
  }) async {
    final currentToken = await _getToken();
    final isEmail = email != null && email.isNotEmpty;

    final value = await _safePost(
      config.resendEndpoint,
      token: _tempToken ?? currentToken,
      body: {
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (phoneCountry != null && phoneCountry.isNotEmpty)
          'phone_country': phoneCountry,
        'verify_type':
            verifyType ??
            (isEmail
                ? config.defaultResendEmailVerifyType
                : config.defaultPhoneOtpVerifyType),
        if (isNew) 'type': 'new',
      },
    );

    if (value is! Response) {
      return AuthResult.failure(_resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    final otpCallback = data[config.otpCallbackResponseKey];
    if (otpCallback is Map<String, dynamic>) {
      _otpResponse = OtpResponse.fromJson(otpCallback);
    }

    return AuthResult.success(
      message: data[config.messageResponseKey]?.toString(),
    );
  }

  Future<AuthResult<UserModel>> verifyOtp({
    required String code,
    String? email,
    String? phone,
    String? phoneCountry,
    String? type,
  }) async {
    final currentToken = await _getToken();
    final value = await _safePost(
      config.verifyEndpoint,
      token: _tempToken ?? currentToken,
      body: {
        'code': code,
        'type': type ?? config.defaultVerifyType,
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
    final currentToken = await _getToken();
    final value = await _safePost(
      config.checkStateOfAccountEndpoint,
      token: _tempToken ?? currentToken,
      cancelToken: cancelToken,
      body: {
        'phone_country': phoneCountry,
        'phone': phone,
        'reference': reference ?? _otpResponse?.reference,
      },
    );

    return _handleAuthResponse(value);
  }

  Future<AuthResult<UserModel>> signUp({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phoneCountry,
    String? phone,
    int? countryId,
    MultipartFile? image,
  }) async {
    final value = await _safePost(
      config.signupEndpoint,
      multiPartBody: FormData.fromMap({
        'name': name,
        'email': email,
        'password': password,
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
      await addDevice();
    }
    return result;
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
    final currentToken = await _getToken();
    if (currentToken == null || currentToken.isEmpty) {
      return AuthResult.failure('Not authenticated.');
    }

    final value = await _safePost(
      config.updateUserDataEndpoint,
      token: currentToken,
      multiPartBody: FormData.fromMap({
        if (_isNotBlank(name)) 'name': name,
        if (_isNotBlank(email)) 'email': email,
        if (_isNotBlank(countryCode) && _isNotBlank(phone))
          'phone_country': countryCode,
        if (_isNotBlank(phone)) 'phone': phone,
        if (birthday != null)
          'birthday': birthday.toIso8601String().split('T')[0],
        if (_isNotBlank(gender)) 'gender': gender,
        if (image != null) 'image': await MultipartFile.fromFile(image.path),
      }),
    );

    if (value is! Response) {
      return AuthResult.failure(_resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    final userJson = data[config.userResponseKey];
    if (userJson is Map<String, dynamic>) {
      _user = UserModel.fromJson(userJson);
      return AuthResult.success(
        data: _user,
        message: data[config.messageResponseKey]?.toString(),
      );
    }

    _user = UserModel.fromJson(data);
    return AuthResult.success(
      data: _user,
      message: data[config.messageResponseKey]?.toString(),
    );
  }

  Future<AuthResult<UserModel>> fetchCurrentUser() async {
    final currentToken = await _getToken();
    final value = await _safePost(config.userEndpoint, token: currentToken);

    if (value is! Response) {
      return AuthResult.failure(_resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    final userJson = data[config.userResponseKey];
    if (userJson is Map<String, dynamic>) {
      _user = UserModel.fromJson(userJson);
      return AuthResult.success(
        data: _user,
        message: data[config.messageResponseKey]?.toString(),
      );
    }

    _user = UserModel.fromJson(data);
    return AuthResult.success(
      data: _user,
      message: data[config.messageResponseKey]?.toString(),
    );
  }

  Future<AuthResult<void>> addDevice({bool? enabled}) async {
    final currentToken = await _getToken();
    if (currentToken == null || currentToken.isEmpty) {
      return AuthResult.failure('Not authenticated.');
    }

    try {
      await notificationModule.setToken(currentToken);
      await notificationModule.addDevice(enabled: enabled);
      if (enabled != null) {
        _isNotificationEnabled = enabled;
      }
      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  Future<AuthResult<void>> deleteAccount() async {
    final currentToken = await _getToken();
    if (currentToken == null || currentToken.isEmpty) {
      return AuthResult.failure('Not authenticated.');
    }

    final value = await _safeDelete(
      config.deleteAccountEndpoint,
      token: currentToken,
    );

    if (value is! Response) {
      return AuthResult.failure(_resolveErrorMessage(value));
    }

    String? message;
    final data = value.data;
    if (data is Map<String, dynamic>) {
      message = data[config.messageResponseKey]?.toString();
    }

    await logout(callApi: false);
    return AuthResult.success(message: message);
  }

  Future<AuthResult<void>> logout({bool callApi = true}) async {
    final currentToken = await _getToken();
    if (callApi && currentToken != null && currentToken.isNotEmpty) {
      await _safePost(config.logoutEndpoint, token: currentToken);
    }

    _token = null;
    _tempToken = null;
    _user = null;
    _otpResponse = null;

    await _tokenStorage.clearToken();
    try {
      await UserModel.saveToken(null);
    } catch (_) {}

    try {
      await notificationModule.setToken(null);
      await notificationModule.deleteFCMToken();
    } catch (_) {}

    return AuthResult.success();
  }

  Future<AuthResult<UserModel>> _handleAuthResponse(dynamic value) async {
    if (value is! Response) {
      return AuthResult.failure(_resolveErrorMessage(value));
    }

    final data = value.data;
    if (data is! Map<String, dynamic>) {
      return AuthResult.failure('Invalid response data.');
    }

    final token = data[config.authTokenResponseKey]?.toString();
    if (token == null || token.isEmpty) {
      return AuthResult.failure('Token was not found in auth response.');
    }

    final userJson = data[config.userResponseKey];
    if (userJson is! Map<String, dynamic>) {
      return AuthResult.failure('User was not found in auth response.');
    }

    _user = UserModel.fromJson(userJson);
    _token = token;
    _tempToken = token;

    await _tokenStorage.saveToken(token);
    try {
      await UserModel.saveToken(token);
    } catch (_) {}

    try {
      await notificationModule.setToken(token);
    } catch (_) {}

    return AuthResult.success(
      data: _user,
      message: data[config.messageResponseKey]?.toString(),
    );
  }

  Future<dynamic> _safePost(
    String endpoint, {
    Map<String, dynamic>? body,
    FormData? multiPartBody,
    String? token,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _networkClient.post(
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

  Future<dynamic> _safeDelete(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      return await _networkClient.delete(endpoint, body: body, token: token);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _getToken() async {
    try {
      final userToken = await UserModel.getToken;
      if (userToken != null && userToken.isNotEmpty) {
        _token = userToken;
        await _tokenStorage.saveToken(userToken);
        return userToken;
      }
    } catch (_) {}

    final storedToken = await _tokenStorage.getToken();
    if (storedToken != null && storedToken.isNotEmpty) {
      _token = storedToken;
      try {
        await UserModel.saveToken(storedToken);
      } catch (_) {}
      return storedToken;
    }

    return _token;
  }

  String _resolveErrorMessage(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }

    if (value is Response) {
      final data = value.data;
      if (data is Map<String, dynamic>) {
        final message = data[config.messageResponseKey];
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
      final message = value[config.messageResponseKey];
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

  bool _isNotBlank(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
