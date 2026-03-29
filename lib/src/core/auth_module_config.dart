class AuthModuleConfig {
  const AuthModuleConfig({
    this.isAdmin = false,
    this.socialLoginProvider,
    this.googleClientId,
    this.googleAuthScopes = const ['email'],
    this.appleClientId,
    this.appleRedirectUri,
  });

  final bool isAdmin;
  final String? socialLoginProvider;
  final String? googleClientId;
  final List<String> googleAuthScopes;
  final String? appleClientId;
  final String? appleRedirectUri;

  static const String _userUserEndPoint = 'user/user';
  static const String _userLoginEndPoint = 'user/login';
  static const String _userSocialLoginEndPoint = 'user/social';
  static const String _userSignupEndPoint = 'user/signup';
  static const String _userLogoutEndPoint = 'user/logout';
  static const String _userResendEndPoint = 'user/resend';
  static const String _userVerifyEndPoint = 'user/verify';
  static const String _userUpdateUserData = 'user/update';
  static const String _userVerifyInfo = 'user/verifyInfo';
  static const String _userCheckStateOfAccountEndPoint = 'user/otp/check';
  static const String _userDeleteAccountEndPoint = 'user/destroy';

  static const String _adminUserEndPoint = 'admin/getCurrentAdmin';
  static const String _adminLoginEndPoint = 'admin/login';
  static const String _adminSocialLoginEndPoint = 'admin/social';
  static const String _adminSignupEndPoint = 'admin/signup';
  static const String _adminLogoutEndPoint = 'admin/logout';
  static const String _adminResendEndPoint = 'admin/resend';
  static const String _adminVerifyEndPoint = 'admin/verify';
  static const String _adminForgetPasswordEndPoint = 'admin/forgot';
  static const String _adminChangeCurrentPasswordEndPoint =
      'admin/change_password';
  static const String _adminUpdateUserData = 'admin/update';
  static const String _adminVerifyInfo = 'admin/verifyInfo';
  static const String _adminCheckStateOfAccountEndPoint = 'admin/otp/check';
  static const String _adminDeleteAccountEndPoint = 'admin/destroy';
  static const String _defaultPhoneOtpVerifyType = 'whatsapp';
  static const String _defaultResendEmailVerifyType = 'mail_otp';
  static const String _defaultVerifyType = 'new';
  static const String _persistTokenStorageKey = 'token';
  static const String _authTokenResponseKey = 'token';
  static const String _userResponseKey = 'user';
  static const String _messageResponseKey = 'message';
  static const String _otpCallbackResponseKey = 'otp_callback';
  static const String _otpReferenceKey = 'reference';

  String get userEndpoint => isAdmin ? _adminUserEndPoint : _userUserEndPoint;
  String get loginEndpoint =>
      isAdmin ? _adminLoginEndPoint : _userLoginEndPoint;
  String get socialLoginEndpoint =>
      isAdmin ? _adminSocialLoginEndPoint : _userSocialLoginEndPoint;
  String get signupEndpoint =>
      isAdmin ? _adminSignupEndPoint : _userSignupEndPoint;
  String get logoutEndpoint =>
      isAdmin ? _adminLogoutEndPoint : _userLogoutEndPoint;
  String get resendEndpoint =>
      isAdmin ? _adminResendEndPoint : _userResendEndPoint;
  String get verifyEndpoint =>
      isAdmin ? _adminVerifyEndPoint : _userVerifyEndPoint;
  String get updateUserDataEndpoint =>
      isAdmin ? _adminUpdateUserData : _userUpdateUserData;
  String get verifyInfoEndpoint => isAdmin ? _adminVerifyInfo : _userVerifyInfo;
  String get checkStateOfAccountEndpoint => isAdmin
      ? _adminCheckStateOfAccountEndPoint
      : _userCheckStateOfAccountEndPoint;
  String get deleteAccountEndpoint =>
      isAdmin ? _adminDeleteAccountEndPoint : _userDeleteAccountEndPoint;
  String get forgetPasswordEndpoint => _adminForgetPasswordEndPoint;
  String get changeCurrentPasswordEndpoint =>
      _adminChangeCurrentPasswordEndPoint;

  String get defaultPhoneOtpVerifyType => _defaultPhoneOtpVerifyType;
  String get defaultResendEmailVerifyType => _defaultResendEmailVerifyType;
  String get defaultVerifyType => _defaultVerifyType;
  String get persistTokenStorageKey => _persistTokenStorageKey;
  String get authTokenResponseKey => _authTokenResponseKey;
  String get userResponseKey => _userResponseKey;
  String get messageResponseKey => _messageResponseKey;
  String get otpCallbackResponseKey => _otpCallbackResponseKey;
  String get otpReferenceKey => _otpReferenceKey;
}
