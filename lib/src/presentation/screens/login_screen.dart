import 'package:auth_module/auth_module.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.loginType,
    required this.langCode,
    required this.mainAppScreen,
    this.forgetType,
    this.logo,
    this.title,
    this.subtitle,
    this.primaryColor,
    this.socialProviders,
    this.emailLabel,
    this.phoneLabel,
    this.passwordLabel,
    this.emailHint,
    this.phoneHint,
    this.passwordHint,
    this.contentPadding = const EdgeInsets.all(20),
    this.module,
    this.onInterceptorDialogFlagChange,
    this.cloudwaLogo,
    this.forgetLogo,
    this.forgetTitle,
    this.forgetSubtitle,
    this.signupLogo,
    this.signupTitle,
    this.signupSubtitle,
    this.signupHasEmail = true,
    this.signupHasPhoneNumber = true,
    this.signupHasPassword = true,
    this.hasCompleteProfile = false,
  });

  final LoginType loginType;
  final String langCode;
  final Widget mainAppScreen;
  final ForgetType? forgetType;
  final Widget? logo;
  final String? title;
  final String? subtitle;
  final Color? primaryColor;
  final List<SocialProvider>? socialProviders;
  final String? emailLabel;
  final String? phoneLabel;
  final String? passwordLabel;
  final String? emailHint;
  final String? phoneHint;
  final String? passwordHint;
  final EdgeInsetsGeometry contentPadding;
  final AuthModule? module;
  final ValueChanged<bool>? onInterceptorDialogFlagChange;
  final Widget? cloudwaLogo;
  final Widget? forgetLogo;
  final String? forgetTitle;
  final String? forgetSubtitle;
  final Widget? signupLogo;
  final String? signupTitle;
  final String? signupSubtitle;
  final bool signupHasEmail;
  final bool signupHasPhoneNumber;
  final bool signupHasPassword;
  final bool hasCompleteProfile;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isHandlingPostLoginRoute = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthUiCubit cubit) async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    if (widget.loginType == LoginType.emailAndPassword) {
      await cubit.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else if (widget.loginType == LoginType.phoneAndPassword) {
      await cubit.loginWithPhoneAndPassword(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
    } else if (widget.loginType == LoginType.phoneWithVerificationCloudwa) {
      final loginSuccess = await cubit.requestPhoneOtpLogin(
        phone: _phoneController.text.trim(),
        phoneCountry: cubit.state.phoneCountryCode,
      );
      if (loginSuccess && mounted) {
        // Call resend to get the OTP response with scheme
        final resendSuccess = await cubit.resendOtp(
          phone: _phoneController.text.trim(),
          phoneCountry: cubit.state.phoneCountryCode,
          isNew: true,
        );
        if (resendSuccess && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: WaitingResponseScreen(
                  phone: _phoneController.text.trim(),
                  country: cubit.state.phoneCountryCode,
                  langCode: widget.langCode,
                  nextScreen: widget.mainAppScreen,
                  hasCompleteProfile: widget.hasCompleteProfile,
                  primaryColor: widget.primaryColor,
                  onInterceptorDialogFlagChange:
                      widget.onInterceptorDialogFlagChange,
                  cloudwaLogo: widget.cloudwaLogo,
                ),
              ),
            ),
          );
        }
      }
    } else if (widget.loginType == LoginType.phoneWithVerificationOtp) {
      final loginSuccess = await cubit.requestPhoneOtpLogin(
        phone: _phoneController.text.trim(),
        phoneCountry: cubit.state.phoneCountryCode,
      );
      if (loginSuccess && mounted) {
        // Call resend to get the OTP response with scheme
        final resendSuccess = await cubit.resendOtp(
          phone: _phoneController.text.trim(),
          phoneCountry: cubit.state.phoneCountryCode,
          isNew: true,
        );
        if (resendSuccess && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: OtpScreen(
                  phone: _phoneController.text.trim(),
                  phoneCountry: cubit.state.phoneCountryCode,
                  langCode: widget.langCode,
                  mainAppScreen: widget.mainAppScreen,
                  hasCompleteProfile: widget.hasCompleteProfile,
                  primaryColor: widget.primaryColor,
                ),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _handlePostLoginRoute(AuthUiCubit cubit) async {
    if (_isHandlingPostLoginRoute || !mounted) {
      return;
    }
    _isHandlingPostLoginRoute = true;

    final fetchedUser = await cubit.fetchCurrentUser();
    if (!mounted) {
      _isHandlingPostLoginRoute = false;
      return;
    }

    final user = fetchedUser ?? cubit.state.user;
    final shouldCompleteProfile =
        widget.hasCompleteProfile && (user?.isDefaultName ?? false);

    if (shouldCompleteProfile) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            langCode: widget.langCode,
            mainAppScreen: widget.mainAppScreen,
            primaryColor: widget.primaryColor,
          ),
        ),
        (route) => false,
      );
      _isHandlingPostLoginRoute = false;
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.mainAppScreen),
      (route) => false,
    );
    _isHandlingPostLoginRoute = false;
  }

  String translate(String key, String langCode) =>
      ModuleLocalizations.tr(langCode, key);

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? Theme.of(context).colorScheme.primary;

    return BlocProvider<AuthUiCubit>(
      create: (context) => AuthUiCubit(module: widget.module),
      child: BlocConsumer<AuthUiCubit, AuthUiState>(
        listener: (context, state) {
          if (state.user != null) {
            _handlePostLoginRoute(context.read<AuthUiCubit>());
          }
        },
        builder: (context, state) {
          final cubit = context.read<AuthUiCubit>();
          final socialProviders = widget.socialProviders;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                              CupertinoIcons.person_crop_circle,
                              size: 76,
                              color: color,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title ?? translate('sign_in', widget.langCode),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((widget.subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle ??
                              translate('login_msg', widget.langCode),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      if (widget.loginType == LoginType.emailAndPassword)
                        ModuleTextField(
                          onSaved: (_) {},
                          fromAuth: true,
                          controller: _emailController,
                          title:
                              widget.emailLabel ??
                              translate('email', widget.langCode),
                          hintText: widget.emailHint ?? 'name@email.com',
                          textInputType: TextInputType.emailAddress,
                          prefix: const Icon(CupertinoIcons.mail, size: 20),
                          validator: (value) {
                            final input = (value ?? '').trim();
                            if (input.isEmpty) {
                              return translate(
                                'email_is_required',
                                widget.langCode,
                              );
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(input)) {
                              return translate(
                                'invalid_email',
                                widget.langCode,
                              );
                            }
                            return null;
                          },
                        )
                      else
                        ModulePhoneField(
                          title:
                              widget.phoneLabel ??
                              translate('phone_number', widget.langCode),
                          hintText: widget.phoneHint,
                          controller: _phoneController,
                          langCode: widget.langCode,
                          onCodeChanged: cubit.setPhoneCountryCode,
                          onChanged: (_) {},
                        ),
                      const SizedBox(height: 16),
                      if (widget.loginType !=
                              LoginType.phoneWithVerificationCloudwa &&
                          widget.loginType !=
                              LoginType.phoneWithVerificationOtp)
                        ModulePasswordTextField(
                          title:
                              widget.passwordLabel ??
                              translate('password', widget.langCode),
                          hintText:
                              widget.passwordHint ??
                              translate('password_hint', widget.langCode),
                          controller: _passwordController,
                          color: color,
                          validatorTextField: (value) {
                            final input = (value ?? '').trim();
                            if (input.isEmpty) {
                              return translate(
                                'password_is_required',
                                widget.langCode,
                              );
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 22),
                      ModuleButton(
                        onTap: state.isLoading ? null : () => _submit(cubit),
                        title: translate('sign_in', widget.langCode),
                        color: color,
                        isLoading: state.isLoading,
                      ),
                      if (widget.forgetType != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(
                                    forgetType: widget.forgetType!,
                                    langCode: widget.langCode,
                                    mainAppScreen: LoginScreen(
                                      loginType: widget.loginType,
                                      langCode: widget.langCode,
                                      mainAppScreen: widget.mainAppScreen,
                                      forgetType: widget.forgetType,
                                      logo: widget.logo,
                                      title: widget.title,
                                      subtitle: widget.subtitle,
                                      primaryColor: widget.primaryColor,
                                      socialProviders: widget.socialProviders,
                                      module: widget.module,
                                      onInterceptorDialogFlagChange:
                                          widget.onInterceptorDialogFlagChange,
                                      cloudwaLogo: widget.cloudwaLogo,
                                      signupLogo: widget.signupLogo,
                                      signupTitle: widget.signupTitle,
                                      signupSubtitle: widget.signupSubtitle,
                                      signupHasEmail: widget.signupHasEmail,
                                      signupHasPhoneNumber:
                                          widget.signupHasPhoneNumber,
                                      signupHasPassword:
                                          widget.signupHasPassword,
                                      hasCompleteProfile:
                                          widget.hasCompleteProfile,
                                    ),
                                    logo: widget.forgetLogo,
                                    title: widget.forgetTitle,
                                    subtitle: widget.forgetSubtitle,
                                    primaryColor: widget.primaryColor,
                                    module: widget.module,
                                    onInterceptorDialogFlagChange:
                                        widget.onInterceptorDialogFlagChange,
                                    cloudwaLogo: widget.cloudwaLogo,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              translate('forgot_password', widget.langCode),
                              style: TextStyle(color: color),
                            ),
                          ),
                        ),
                      ],
                      if (socialProviders != null &&
                          socialProviders.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                translate('or', widget.langCode),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: socialProviders
                              .map(
                                (provider) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: _SocialIconButton(
                                    provider: provider,
                                    color: color,
                                    onTap: state.isLoading
                                        ? null
                                        : () => cubit.loginWithSocial(provider),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (!widget.hasCompleteProfile) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              translate('dont_have_account', widget.langCode),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SignUpScreen(
                                      langCode: widget.langCode,
                                      mainAppScreen: widget.mainAppScreen,
                                      logo: widget.signupLogo,
                                      title: widget.signupTitle,
                                      subtitle: widget.signupSubtitle,
                                      primaryColor: widget.primaryColor,
                                      emailLabel: widget.emailLabel,
                                      phoneLabel: widget.phoneLabel,
                                      passwordLabel: widget.passwordLabel,
                                      emailHint: widget.emailHint,
                                      phoneHint: widget.phoneHint,
                                      passwordHint: widget.passwordHint,
                                      onInterceptorDialogFlagChange:
                                          widget.onInterceptorDialogFlagChange,
                                      cloudwaLogo: widget.cloudwaLogo,
                                      hasEmail: widget.signupHasEmail,
                                      hasPhoneNumber:
                                          widget.signupHasPhoneNumber,
                                      hasPassword: widget.signupHasPassword,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                translate('sign_up', widget.langCode),
                                style: TextStyle(color: color),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => widget.mainAppScreen,
                              ),
                              (route) => false,
                            );
                          },
                          child: Text(
                            translate('continue_as_guest', widget.langCode),
                            style: TextStyle(color: color),
                          ),
                        ),
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

class LoginWithEmailAndPassword extends StatelessWidget {
  const LoginWithEmailAndPassword({
    super.key,
    required this.langCode,
    required this.mainAppScreen,
    this.forgetType,
    this.logo,
    this.forgetLogo,
    this.title,
    this.forgetTitle,
    this.subtitle,
    this.forgetSubtitle,
    this.primaryColor,
    this.socialProviders,
    this.module,
    this.onInterceptorDialogFlagChange,
    this.signupLogo,
    this.signupTitle,
    this.signupSubtitle,
    this.signupHasEmail = true,
    this.signupHasPhoneNumber = true,
    this.signupHasPassword = true,
    this.hasCompleteProfile = false,
  });

  final String langCode;
  final Widget mainAppScreen;
  final ForgetType? forgetType;
  final Widget? logo;
  final Widget? forgetLogo;
  final String? title;
  final String? forgetTitle;
  final String? subtitle;
  final String? forgetSubtitle;
  final Color? primaryColor;
  final List<SocialProvider>? socialProviders;
  final AuthModule? module;
  final ValueChanged<bool>? onInterceptorDialogFlagChange;
  final Widget? signupLogo;
  final String? signupTitle;
  final String? signupSubtitle;
  final bool signupHasEmail;
  final bool signupHasPhoneNumber;
  final bool signupHasPassword;
  final bool hasCompleteProfile;

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      loginType: LoginType.emailAndPassword,
      langCode: langCode,
      mainAppScreen: mainAppScreen,
      forgetType: forgetType,
      logo: logo,
      forgetLogo: forgetLogo,
      title: title,
      forgetTitle: forgetTitle,
      subtitle: subtitle,
      forgetSubtitle: forgetSubtitle,
      primaryColor: primaryColor,
      socialProviders: socialProviders,
      module: module,
      onInterceptorDialogFlagChange: onInterceptorDialogFlagChange,
      signupLogo: signupLogo,
      signupTitle: signupTitle,
      signupSubtitle: signupSubtitle,
      signupHasEmail: signupHasEmail,
      signupHasPhoneNumber: signupHasPhoneNumber,
      signupHasPassword: signupHasPassword,
      hasCompleteProfile: hasCompleteProfile,
    );
  }
}

class LoginWithPhoneAndPassword extends StatelessWidget {
  const LoginWithPhoneAndPassword({
    super.key,
    required this.langCode,
    required this.mainAppScreen,
    this.forgetType,
    this.logo,
    this.forgetLogo,
    this.title,
    this.forgetTitle,
    this.subtitle,
    this.forgetSubtitle,
    this.primaryColor,
    this.socialProviders,
    this.module,
    this.onInterceptorDialogFlagChange,
    this.signupLogo,
    this.signupTitle,
    this.signupSubtitle,
    this.signupHasEmail = true,
    this.signupHasPhoneNumber = true,
    this.signupHasPassword = true,
    this.hasCompleteProfile = false,
  });

  final String langCode;
  final Widget mainAppScreen;
  final ForgetType? forgetType;
  final Widget? logo;
  final Widget? forgetLogo;
  final String? title;
  final String? forgetTitle;
  final String? subtitle;
  final String? forgetSubtitle;
  final Color? primaryColor;
  final List<SocialProvider>? socialProviders;
  final AuthModule? module;
  final ValueChanged<bool>? onInterceptorDialogFlagChange;
  final Widget? signupLogo;
  final String? signupTitle;
  final String? signupSubtitle;
  final bool signupHasEmail;
  final bool signupHasPhoneNumber;
  final bool signupHasPassword;
  final bool hasCompleteProfile;

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      loginType: LoginType.phoneAndPassword,
      langCode: langCode,
      mainAppScreen: mainAppScreen,
      forgetType: forgetType,
      logo: logo,
      forgetLogo: forgetLogo,
      title: title,
      forgetTitle: forgetTitle,
      subtitle: subtitle,
      forgetSubtitle: forgetSubtitle,
      primaryColor: primaryColor,
      socialProviders: socialProviders,
      module: module,
      onInterceptorDialogFlagChange: onInterceptorDialogFlagChange,
      signupLogo: signupLogo,
      signupTitle: signupTitle,
      signupSubtitle: signupSubtitle,
      signupHasEmail: signupHasEmail,
      signupHasPhoneNumber: signupHasPhoneNumber,
      signupHasPassword: signupHasPassword,
      hasCompleteProfile: hasCompleteProfile,
    );
  }
}

class LoginWithPhoneAndVerificationCode extends StatelessWidget {
  const LoginWithPhoneAndVerificationCode({
    super.key,
    required this.langCode,
    required this.mainAppScreen,
    this.forgetType,
    this.logo,
    this.forgetLogo,
    this.title,
    this.forgetTitle,
    this.subtitle,
    this.forgetSubtitle,
    this.primaryColor,
    this.socialProviders,
    this.module,
    this.onInterceptorDialogFlagChange,
    this.signupLogo,
    this.signupTitle,
    this.signupSubtitle,
    this.signupHasEmail = true,
    this.signupHasPhoneNumber = true,
    this.signupHasPassword = true,
    this.hasCompleteProfile = false,
  });

  final String langCode;
  final Widget mainAppScreen;
  final ForgetType? forgetType;
  final Widget? logo;
  final Widget? forgetLogo;
  final String? title;
  final String? forgetTitle;
  final String? subtitle;
  final String? forgetSubtitle;
  final Color? primaryColor;
  final List<SocialProvider>? socialProviders;
  final AuthModule? module;
  final ValueChanged<bool>? onInterceptorDialogFlagChange;
  final Widget? signupLogo;
  final String? signupTitle;
  final String? signupSubtitle;
  final bool signupHasEmail;
  final bool signupHasPhoneNumber;
  final bool signupHasPassword;
  final bool hasCompleteProfile;

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      loginType: LoginType.phoneWithVerificationCloudwa,
      langCode: langCode,
      mainAppScreen: mainAppScreen,
      forgetType: forgetType,
      logo: logo,
      forgetLogo: forgetLogo,
      title: title,
      forgetTitle: forgetTitle,
      subtitle: subtitle,
      forgetSubtitle: forgetSubtitle,
      primaryColor: primaryColor,
      socialProviders: socialProviders,
      module: module,
      onInterceptorDialogFlagChange: onInterceptorDialogFlagChange,
      signupLogo: signupLogo,
      signupTitle: signupTitle,
      signupSubtitle: signupSubtitle,
      signupHasEmail: signupHasEmail,
      signupHasPhoneNumber: signupHasPhoneNumber,
      signupHasPassword: signupHasPassword,
      hasCompleteProfile: hasCompleteProfile,
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.provider,
    required this.color,
    required this.onTap,
  });

  final SocialProvider provider;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(provider);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Image.asset(icon, package: 'auth_module', width: 42, height: 42),
    );
  }

  String _iconFor(SocialProvider provider) {
    switch (provider) {
      case SocialProvider.apple:
        return 'assets/images/apple.png';
      case SocialProvider.google:
        return 'assets/images/google.png';
    }
  }
}
