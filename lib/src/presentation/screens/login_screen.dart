import 'package:auth_module/src/presentation/cubit/auth_ui_cubit.dart';
import 'package:auth_module/src/presentation/cubit/auth_ui_state.dart';
import 'package:auth_module/src/presentation/localization/module_localizations.dart';
import 'package:auth_module/src/presentation/screens/login_type.dart';
import 'package:auth_module/src/presentation/widgets/module_button.dart';
import 'package:auth_module/src/presentation/widgets/password_text_field.dart';
import 'package:auth_module/src/presentation/widgets/phone_field.dart';
import 'package:auth_module/src/presentation/widgets/text_field_widget.dart';
import 'package:auth_module/src/core/auth_module_enum.dart';
import 'package:auth_module/src/core/auth_module_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.loginType,
    required this.langCode,
    required this.mainAppScreen,
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
  });

  final LoginType loginType;
  final String langCode;
  final Widget mainAppScreen;
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

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String tr(String key) => ModuleLocalizations.tr(widget.langCode, key);

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

    bool success = false;
    if (widget.loginType == LoginType.emailAndPassword) {
      success = await cubit.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await cubit.loginWithPhoneAndPassword(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted || !success) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.mainAppScreen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? Theme.of(context).colorScheme.primary;

    return BlocProvider<AuthUiCubit>(
      create: (context) => AuthUiCubit(module: widget.module),
      child: BlocConsumer<AuthUiCubit, AuthUiState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            messenger.showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
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
                        widget.title ?? tr('sign_in'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((widget.subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle ?? tr('login_msg'),
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
                          onCodeChanged: cubit.setPhoneCountryCode,
                          onChanged: (_) {},
                        ),
                      const SizedBox(height: 16),
                      ModulePasswordTextField(
                        title: widget.passwordLabel ?? tr('password'),
                        hintText: widget.passwordHint ?? tr('password_hint'),
                        controller: _passwordController,
                        validatorTextField: (value) {
                          final input = (value ?? '').trim();
                          if (input.isEmpty) {
                            return tr('password_is_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      ModuleButton(
                        onTap: state.isLoading ? null : () => _submit(cubit),
                        title: tr('sign_in'),
                        color: color,
                        radius: 12,
                        suffex: state.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
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
                                tr('or'),
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
    this.logo,
    this.title,
    this.subtitle,
    this.primaryColor,
    this.socialProviders,
    this.module,
  });

  final String langCode;
  final Widget mainAppScreen;
  final Widget? logo;
  final String? title;
  final String? subtitle;
  final Color? primaryColor;
  final List<SocialProvider>? socialProviders;
  final AuthModule? module;

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      loginType: LoginType.emailAndPassword,
      langCode: langCode,
      mainAppScreen: mainAppScreen,
      logo: logo,
      title: title,
      subtitle: subtitle,
      primaryColor: primaryColor,
      socialProviders: socialProviders,
      module: module,
    );
  }
}

class LoginWithPhoneAndPassword extends StatelessWidget {
  const LoginWithPhoneAndPassword({
    super.key,
    required this.langCode,
    required this.mainAppScreen,
    this.logo,
    this.title,
    this.subtitle,
    this.primaryColor,
    this.socialProviders,
    this.module,
  });

  final String langCode;
  final Widget mainAppScreen;
  final Widget? logo;
  final String? title;
  final String? subtitle;
  final Color? primaryColor;
  final List<SocialProvider>? socialProviders;
  final AuthModule? module;

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      loginType: LoginType.phoneAndPassword,
      langCode: langCode,
      mainAppScreen: mainAppScreen,
      logo: logo,
      title: title,
      subtitle: subtitle,
      primaryColor: primaryColor,
      socialProviders: socialProviders,
      module: module,
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
      child: Image.asset(icon, package: 'auth_module',width: 42,height: 42,),
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
