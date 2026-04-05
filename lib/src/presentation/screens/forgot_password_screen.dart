import 'package:auth_module/auth_module.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.forgetType,
    required this.langCode,
    required this.mainAppScreen,
    this.logo,
    this.title,
    this.subtitle,
    this.primaryColor,
    this.emailLabel,
    this.phoneLabel,
    this.emailHint,
    this.phoneHint,
    this.contentPadding = const EdgeInsets.all(20),
    this.module,
    this.onInterceptorDialogFlagChange,
    this.cloudwaLogo,
  });

  final ForgetType forgetType;
  final String langCode;
  final Widget mainAppScreen;
  final Widget? logo;
  final String? title;
  final String? subtitle;
  final Color? primaryColor;
  final String? emailLabel;
  final String? phoneLabel;
  final String? emailHint;
  final String? phoneHint;
  final EdgeInsetsGeometry contentPadding;
  final AuthModule? module;
  final ValueChanged<bool>? onInterceptorDialogFlagChange;
  final Widget? cloudwaLogo;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String tr(String key) => ModuleLocalizations.tr(widget.langCode, key);

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthUiCubit cubit) async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    if (widget.forgetType == ForgetType.email) {
      final success = await cubit.forgotPassword(
        email: _emailController.text.trim(),
        resetType: 'mail_otp',
      );
      if (!success || !mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: OtpScreen(
              email: _emailController.text.trim(),
              verifyType: 'mail_otp',
              langCode: widget.langCode,
              mainAppScreen: widget.mainAppScreen,

              primaryColor: widget.primaryColor,
            ),
          ),
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    final country = cubit.state.phoneCountryCode;
    final resetType = widget.forgetType == ForgetType.phoneWithVerificationOtp
        ? 'otp'
        : 'whatsapp_send';

    final success = await cubit.forgotPassword(
      phone: phone,
      phoneCountry: country,
      resetType: resetType,
    );

    if (!success || !mounted) {
      return;
    }

    if (widget.forgetType == ForgetType.phoneWithVerificationCloudwa) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: WaitingResponseScreen(
              phone: phone,
              country: country,
              langCode: widget.langCode,
              clearStackOnVerified: false,
              nextScreen: BlocProvider.value(
                value: cubit,
                child: ResetPasswordScreen(
                  phone: phone,
                  phoneCountry: country,
                  resetType: resetType,
                  langCode: widget.langCode,
                  mainAppScreen: widget.mainAppScreen,
                  primaryColor: widget.primaryColor,
                  module: widget.module,
                ),
              ),
              primaryColor: widget.primaryColor,
              onInterceptorDialogFlagChange:
                  widget.onInterceptorDialogFlagChange,
              cloudwaLogo: widget.cloudwaLogo,
            ),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: OtpScreen(
            phone: phone,
            phoneCountry: country,
            verifyType: resetType,
            langCode: widget.langCode,
            mainAppScreen: widget.mainAppScreen,
            primaryColor: widget.primaryColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? Theme.of(context).colorScheme.primary;

    return BlocProvider<AuthUiCubit>(
      create: (_) => AuthUiCubit(module: widget.module),
      child: BlocBuilder<AuthUiCubit, AuthUiState>(
        builder: (context, state) {
          final cubit = context.read<AuthUiCubit>();
          final isEmail = widget.forgetType == ForgetType.email;

          return Scaffold(
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: widget.contentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Center(
                        child:
                            widget.logo ??
                            Icon(
                              CupertinoIcons.lock_shield,
                              size: 76,
                              color: color,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title ?? tr('forgot_password'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((widget.subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle ?? tr('forgot_password_msg'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      if (isEmail)
                        ModuleTextField(
                          onSaved: (_) {},
                          fromAuth: true,
                          controller: _emailController,
                          title: widget.emailLabel ?? tr('email'),
                          hintText: widget.emailHint ?? 'name@email.com',
                          textInputType: TextInputType.emailAddress,
                          prefix: const Icon(CupertinoIcons.mail, size: 20),
                          validator: (value) {
                            final input = (value ?? '').trim();
                            if (input.isEmpty) {
                              return tr('email_is_required');
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(input)) {
                              return tr('invalid_email');
                            }
                            return null;
                          },
                        )
                      else
                        ModulePhoneField(
                          title: widget.phoneLabel ?? tr('phone_number'),
                          hintText: widget.phoneHint,
                          controller: _phoneController,
                          langCode: widget.langCode,
                          onCodeChanged: cubit.setPhoneCountryCode,
                          onChanged: (_) {},
                        ),
                      const SizedBox(height: 22),
                      ModuleButton(
                        onTap: state.isLoading ? null : () => _submit(cubit),
                        title: tr('continue'),
                        color: color,
                        isLoading: state.isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
