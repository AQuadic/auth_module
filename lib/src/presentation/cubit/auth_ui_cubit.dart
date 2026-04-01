import 'dart:async';

import 'package:auth_module/src/core/auth_module_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_ui_state.dart';

class AuthUiCubit extends Cubit<AuthUiState> {
  AuthUiCubit({AuthModule? module})
    : _module = module ?? AuthModule.instance,
      super(const AuthUiState());

  final AuthModule _module;
  Timer? _waitingTimer;
  Timer? _countdownTimer;

  void setPhoneCountryCode(String code) {
    if (code.isEmpty) {
      return;
    }
    emit(state.copyWith(phoneCountryCode: code));
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));

    final result = await _module.loginWithEmail(
      email: email,
      password: password,
    );
    if (!result.isSuccess) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: result.error ?? result.message,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        isLoading: false,
        successMessage: result.message,
        user: result.data,
      ),
    );
    return true;
  }

  Future<bool> loginWithPhoneAndPassword({
    required String phone,
    required String password,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));

    final result = await _module.loginWithPhoneAndPassword(
      phoneCountry: state.phoneCountryCode,
      phone: phone,
      password: password,
    );

    if (!result.isSuccess) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: result.error ?? result.message,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        isLoading: false,
        successMessage: result.message,
        user: result.data,
      ),
    );
    return true;
  }

  Future<bool> loginWithSocial(SocialProvider provider) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));

    final result = await _module.loginWithSocial(provider: provider);
    if (!result.isSuccess) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: result.error ?? result.message,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        isLoading: false,
        successMessage: result.message,
        user: result.data,
      ),
    );
    return true;
  }

  Future<bool> verifyOtp({
    required String code,
    String? email,
    String? phone,
    String? phoneCountry,
    String? type,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));

    final result = await _module.verifyOtp(
      code: code,
      email: email,
      phone: phone,
      phoneCountry: phoneCountry,
      type: type,
    );

    if (!result.isSuccess) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: result.error ?? result.message,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        isLoading: false,
        successMessage: result.message,
        user: result.data,
      ),
    );
    return true;
  }

  Future<bool> resendOtp({
    String? phone,
    String? email,
    String? phoneCountry,
    bool isNew = false,
    String? verifyType,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));

    final result = await _module.resendOtp(
      phone: phone,
      email: email,
      phoneCountry: phoneCountry,
      isNew: isNew,
      verifyType: verifyType,
    );

    if (!result.isSuccess) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: result.error ?? result.message,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        isLoading: false,
        successMessage: result.message,
        verificationMessage: _module.otpResponse?.message,
      ),
    );
    return true;
  }

  void startOtpCountdown({int seconds = 60}) {
    _countdownTimer?.cancel();
    emit(state.copyWith(waitingSeconds: seconds));
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final value = state.waitingSeconds;
      if (value <= 1) {
        timer.cancel();
        emit(state.copyWith(waitingSeconds: 0));
      } else {
        emit(state.copyWith(waitingSeconds: value - 1));
      }
    });
  }

  Future<void> startWaitingForPhoneVerification({
    required String phone,
    required String phoneCountry,
    required VoidCallback onVerified,
    Duration interval = const Duration(seconds: 2),
  }) async {
    _waitingTimer?.cancel();

    _waitingTimer = Timer.periodic(interval, (timer) async {
      final result = await _module.checkPhoneOtpState(
        phone: phone,
        phoneCountry: phoneCountry,
      );

      if (!result.isSuccess) {
        emit(state.copyWith(errorMessage: result.error ?? result.message));
        return;
      }

      final user = result.data;
      if (user != null && user.isVerified) {
        timer.cancel();
        emit(state.copyWith(user: user, successMessage: result.message));
        onVerified();
      }
    });
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }

  @override
  Future<void> close() {
    _waitingTimer?.cancel();
    _countdownTimer?.cancel();
    return super.close();
  }
}
