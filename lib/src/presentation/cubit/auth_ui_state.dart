import 'package:auth_module/src/models/user_model.dart';

class AuthUiState {
  const AuthUiState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.phoneCountryCode = 'EG',
    this.waitingSeconds = 0,
    this.verificationMessage,
    this.user,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final String phoneCountryCode;
  final int waitingSeconds;
  final String? verificationMessage;
  final UserModel? user;

  AuthUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    String? phoneCountryCode,
    int? waitingSeconds,
    String? verificationMessage,
    bool clearVerificationMessage = false,
    UserModel? user,
    bool clearUser = false,
  }) {
    return AuthUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      waitingSeconds: waitingSeconds ?? this.waitingSeconds,
      verificationMessage: clearVerificationMessage
          ? null
          : (verificationMessage ?? this.verificationMessage),
      user: clearUser ? null : (user ?? this.user),
    );
  }
}
