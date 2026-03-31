import 'dart:async';

import 'package:auth_module/src/core/auth_module_enum.dart';
import 'package:dio/dio.dart';
import 'package:cross_file/cross_file.dart';
import 'package:firebase_auth/firebase_auth.dart';

export 'auth_module_enum.dart';

import '../models/auth_result.dart';
import '../models/otp_response.dart';
import '../models/user_model.dart';
import '../network/auth_network_client.dart';
import '../network/dio_helper_network_client.dart';
import '../storage/auth_token_storage.dart';
import '../storage/shared_prefs_auth_token_storage.dart';
import 'auth_module_config.dart';
import 'social_sign_in_client.dart';

part 'auth_module_auth_service.dart';
part 'auth_module_otp_service.dart';
part 'auth_module_user_service.dart';
part 'auth_module_network_service.dart';

class AuthModule {
  static AuthModule? _instance;

  static AuthModule get instance => _instance ??= AuthModule._();


  AuthModule._();

  AuthModule({
    required AuthNetworkClient networkClient,
    required this.config,
    required this.notificationModule,
    SocialSignInClient? socialSignInClient,
    AuthTokenStorage? tokenStorage,
  }) {
    _networkClient = networkClient;
    _socialSignInClient = socialSignInClient ?? PluginSocialSignInClient();
    _tokenStorage =
        tokenStorage ??
        SharedPrefsAuthTokenStorage(key: config.persistTokenStorageKey);
    _isConfigured = true;
  }

  factory AuthModule.init({
    required dynamic dioHelper,
    required dynamic notificationModule,
    AuthModuleConfig config = const AuthModuleConfig(),
  }) {
    final module = instance;
    module._configure(
      dioHelper: dioHelper,
      notificationModule: notificationModule,
      config: config,
    );
    _instance = module;
    return module;
  }

  late AuthNetworkClient _networkClient;
  late SocialSignInClient _socialSignInClient;
  late AuthTokenStorage _tokenStorage;

  late AuthModuleConfig config;
  late dynamic notificationModule;

  late final _AuthNetworkService _networkService = _AuthNetworkService(this);
  late final _AuthAuthService _authService = _AuthAuthService(this);
  late final _AuthOtpService _otpService = _AuthOtpService(this);
  late final _AuthUserService _userService = _AuthUserService(this);

  String? _token;
  String? _tempToken;
  String? _firebaseVerificationId;
  UserModel? _user;
  OtpResponse? _otpResponse;
  bool? _isNotificationEnabled;
  bool _isConfigured = false;

  UserModel? get user => _user;
  String? get token => _token;
  String? get tempToken => _tempToken;
  String? get firebaseVerificationId => _firebaseVerificationId;
  OtpResponse? get otpResponse => _otpResponse;
  bool get isLoggedIn => (_token?.isNotEmpty ?? false) && _user != null;
  bool? get isNotificationEnabled => _isNotificationEnabled;

  Future<void> init({
    dynamic dioHelper,
    dynamic notificationModule,
    AuthModuleConfig config = const AuthModuleConfig(),
  }) async {
    if (!_isConfigured) {
      if (dioHelper == null || notificationModule == null) {
        throw StateError(
          'AuthModule is not configured. Pass dioHelper and notificationModule to init(...) on first call.',
        );
      }

      _configure(
        dioHelper: dioHelper,
        notificationModule: notificationModule,
        config: config,
      );
    }

    _token = await _getToken();
  }

  void _configure({
    required dynamic dioHelper,
    required dynamic notificationModule,
    required AuthModuleConfig config,
    SocialSignInClient? socialSignInClient,
    AuthTokenStorage? tokenStorage,
  }) {
    _networkClient = DioHelperNetworkClient(dioHelper);
    this.config = config;
    this.notificationModule = notificationModule;
    _socialSignInClient = socialSignInClient ?? PluginSocialSignInClient();
    _tokenStorage =
        tokenStorage ??
        SharedPrefsAuthTokenStorage(key: config.persistTokenStorageKey);
    _isConfigured = true;
  }

  Future<AuthResult<UserModel>> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _authService.loginWithEmail(email: email, password: password);
  }

  Future<AuthResult<UserModel>> loginWithPhoneAndPassword({
    required String phoneCountry,
    required String phone,
    required String password,
  }) {
    return _authService.loginWithPhoneAndPassword(
      phoneCountry: phoneCountry,
      phone: phone,
      password: password,
    );
  }

  Future<AuthResult<UserModel>> loginWithSocial({
    required SocialProvider provider,
  }) {
    return _authService.loginWithSocial(provider: provider);
  }

  Future<AuthResult<UserModel>> loginWithFirebaseIdToken({
    required String idToken,
    String provider = 'FIREBASE',
  }) {
    return _authService.loginWithFirebaseIdToken(
      idToken: idToken,
      provider: provider,
    );
  }

  Future<AuthResult<UserModel>> loginWithFirebasePhoneOtp({
    required String verificationId,
    required String smsCode,
    String provider = 'FIREBASE',
  }) {
    return _authService.verifyFirebasePhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
      provider: provider,
    );
  }

  Future<AuthResult<void>> sendFirebasePhoneOtp({
    required String phoneNumber,
    Duration timeout = const Duration(seconds: 60),
    int? forceResendingToken,
  }) {
    return _authService.sendFirebasePhoneOtp(
      phoneNumber: phoneNumber,
      timeout: timeout,
      forceResendingToken: forceResendingToken,
    );
  }

  Future<AuthResult<UserModel>> verifyFirebasePhoneOtp({
    required String smsCode,
    String provider = 'FIREBASE',
    String? verificationId,
  }) {
    return _authService.verifyFirebasePhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
      provider: provider,
    );
  }

  Future<AuthResult<void>> requestPhoneOtpLogin({
    required String phoneCountry,
    required String phone,
    String? verifyType,
  }) {
    return _otpService.requestPhoneOtpLogin(
      phoneCountry: phoneCountry,
      phone: phone,
      verifyType: verifyType,
    );
  }

  Future<AuthResult<void>> resendOtp({
    String? phone,
    String? email,
    String? phoneCountry,
    bool isNew = false,
    String? verifyType,
  }) {
    return _otpService.resendOtp(
      phone: phone,
      email: email,
      phoneCountry: phoneCountry,
      isNew: isNew,
      verifyType: verifyType,
    );
  }

  Future<AuthResult<UserModel>> verifyOtp({
    required String code,
    String? email,
    String? phone,
    String? phoneCountry,
    String? type,
  }) {
    return _authService.verifyOtp(
      code: code,
      email: email,
      phone: phone,
      phoneCountry: phoneCountry,
      type: type,
    );
  }

  Future<AuthResult<UserModel>> checkPhoneOtpState({
    required String phone,
    required String phoneCountry,
    String? reference,
    CancelToken? cancelToken,
  }) {
    return _authService.checkPhoneOtpState(
      phone: phone,
      phoneCountry: phoneCountry,
      reference: reference,
      cancelToken: cancelToken,
    );
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
  }) {
    return _authService.signUp(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      phoneCountry: phoneCountry,
      phone: phone,
      countryId: countryId,
      image: image,
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
  }) {
    return _userService.updateUser(
      image: image,
      email: email,
      name: name,
      countryCode: countryCode,
      phone: phone,
      birthday: birthday,
      gender: gender,
    );
  }

  Future<AuthResult<UserModel>> fetchCurrentUser() {
    return _userService.fetchCurrentUser();
  }

  Future<AuthResult<void>> addDevice({bool? enabled}) {
    return _userService.addDevice(enabled: enabled);
  }

  Future<AuthResult<void>> deleteAccount() {
    return _userService.deleteAccount();
  }

  Future<AuthResult<void>> logout({
    bool callApi = true,
    bool withFirebase = true,
  }) {
    return _userService.logout(
      callApi: callApi,
      withFirebase: withFirebase,
    );
  }

  Future<dynamic> _safePost(
    String endpoint, {
    Map<String, dynamic>? body,
    FormData? multiPartBody,
    String? token,
    CancelToken? cancelToken,
  }) {
    return _networkService.safePost(
      endpoint,
      body: body,
      multiPartBody: multiPartBody,
      token: token,
      cancelToken: cancelToken,
    );
  }

  Future<dynamic> _safeDelete(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return _networkService.safeDelete(endpoint, body: body, token: token);
  }

  Future<dynamic> _safeGet(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return _networkService.safeGet(endpoint, body: body, token: token);
  }

  Future<String?> _getToken() {
    return _networkService.getToken();
  }

  String _resolveErrorMessage(dynamic value) {
    return _networkService.resolveErrorMessage(value);
  }

  bool _isNotBlank(String? value) {
    return _networkService.isNotBlank(value);
  }
}
