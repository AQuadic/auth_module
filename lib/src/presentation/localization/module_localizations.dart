
class ModuleLocalizations {
  const ModuleLocalizations._();

  static String tr(String langCode, String key) {
    final normalizedLang = _normalizeLangCode(langCode);
    final localized = _translations[normalizedLang]?[key];
    return localized ?? _translations['en']?[key] ?? key;
  }

  static String _normalizeLangCode(String langCode) {
    final normalized = langCode.trim().toLowerCase();
    if (normalized.startsWith('ar')) {
      return 'ar';
    }
    return 'en';
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'sign_in': 'Sign In',
      'login_msg': 'Login to continue your journey',
      'email': 'Email',
      'password': 'Password',
      'password_hint': 'Enter your password',
      'phone_number': 'Phone Number',
      'phone_number_is_required': 'Phone number is required',
      'continue': 'Continue',
      'or': 'OR',
      'change_number': 'Change Number',
      'fast_verification': 'Fast Verification',
      'whatsapp_verification_msg':
          'You will be transferred to WhatsApp to send us the code to verify your number.',
      'sure_send_message': 'Make sure to send us the message from number',
      'otp_ready': 'OTP Ready',
      'generate_new_code': 'Generate New Code',
      'confirm': 'Confirm',
      'dont_receive_code': "Didn't receive the code?",
      'send_again': 'Send Again',
      'verify': 'Verify',
      'email_is_required': 'Email is required',
      'password_is_required': 'Password is required',
      'phone_is_required': 'Phone number is required',
      'otp_code': 'OTP Code',
      'otp_code_is_required': 'OTP code is required',
      'otp_screen_title': 'Verify OTP',
      'social_login': 'Social Login',
      'invalid_email': 'Please enter a valid email',
      'invalid_otp': 'Please enter a valid OTP code',
      'unknown_error': 'Something went wrong, please try again.',
      'verification_message': 'Verification message',
      "country_hint": "'Country' or 'Code' or 'Dial code'",
      "select_country_or_region": "Select country or region",
      "powered_by": "Powered by",
    },
    'ar': {
      'sign_in': 'تسجيل الدخول',
      'login_msg': 'سجل دخولك لمواصلة رحلتك',
      'email': 'البريد الالكتروني',
      'password': 'كلمة المرور',
      'password_hint': 'ادخل كلمة المرور',
      'phone_number': 'رقم الهاتف',
      'phone_number_is_required': 'رقم الهاتف مطلوب',
      'continue': 'استمرار',
      'or': 'او',
      'change_number': 'تغيير الرقم',
      'fast_verification': 'التحقق السريع',
      'whatsapp_verification_msg':
          'سيتم تحويلك الى واتساب لارسال الكود للتحقق من رقمك.',
      'sure_send_message': 'تأكد من ارسال الرسالة من رقمك',
      'otp_ready': 'كود التحقق جاهز',
      'generate_new_code': 'انشاء كود جديد',
      'confirm': 'تأكيد',
      'dont_receive_code': 'لم تستلم الكود؟',
      'send_again': 'ارسال مرة اخرى',
      'verify': 'تحقق',
      'email_is_required': 'البريد الالكتروني مطلوب',
      'password_is_required': 'كلمة المرور مطلوبة',
      'phone_is_required': 'رقم الهاتف مطلوب',
      'otp_code': 'كود التحقق',
      'otp_code_is_required': 'كود التحقق مطلوب',
      'otp_screen_title': 'تحقق من الكود',
      'social_login': 'تسجيل الدخول الاجتماعي',
      'invalid_email': 'يرجى ادخال بريد الكتروني صالح',
      'invalid_otp': 'يرجى ادخال كود تحقق صالح',
      'unknown_error': 'حدث خطأ، حاول مرة اخرى.',
      'verification_message': 'رسالة التحقق',
      "country_hint": "'الدولة' أو 'الرمز' أو 'رمز الاتصال'",
      "select_country_or_region": "اختر الدولة او المنطقة",
      "powered_by": "مدعوم من",
    },
  };
}
