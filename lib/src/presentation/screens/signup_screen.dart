import 'dart:io';

import 'package:auth_module/auth_module.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.langCode,
    required this.mainAppScreen,
    this.logo,
    this.title,
    this.subtitle,
    this.primaryColor,
    this.nameLabel,
    this.nameHint,
    this.emailLabel,
    this.phoneLabel,
    this.passwordLabel,
    this.emailHint,
    this.phoneHint,
    this.passwordHint,
    this.contentPadding = const EdgeInsets.all(20),
    this.onInterceptorDialogFlagChange,
    this.cloudwaLogo,
    this.hasEmail = true,
    this.hasPhoneNumber = true,
    this.hasPassword = true,
    this.showProfilePicture = true,
    this.socialProviders,
    this.module,
    this.hasCompleteProfile = false,
  });

  final String langCode;
  final Widget mainAppScreen;
  final Widget? logo;
  final String? title;
  final String? subtitle;
  final Color? primaryColor;
  final String? nameLabel;
  final String? nameHint;
  final String? emailLabel;
  final String? phoneLabel;
  final String? passwordLabel;
  final String? emailHint;
  final String? phoneHint;
  final String? passwordHint;
  final EdgeInsetsGeometry contentPadding;
  final ValueChanged<bool>? onInterceptorDialogFlagChange;
  final Widget? cloudwaLogo;
  final bool hasEmail;
  final bool hasPhoneNumber;
  final bool hasPassword;
  final bool showProfilePicture;
  final List<SocialProvider>? socialProviders;
  final AuthModule? module;
  final bool hasCompleteProfile;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isHandlingPostLoginRoute = false;

  String tr(String key) => ModuleLocalizations.tr(widget.langCode, key);

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted || image == null) {
      return;
    }

    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _submit(AuthUiCubit cubit) async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final name = _nameController.text.trim();
    final email = widget.hasEmail ? _emailController.text.trim() : null;
    final phone = widget.hasPhoneNumber ? _phoneController.text.trim() : null;
    final password = widget.hasPassword ? _passwordController.text : null;
    final confirmPassword = widget.hasPassword
        ? _confirmPasswordController.text
        : null;

    final success = await cubit.signUp(
      name: name,
      email: email,
      phone: phone,
      phoneCountry: cubit.state.phoneCountryCode,
      password: password,
      passwordConfirmation: confirmPassword,
      image: _selectedImage,
    );

    if (!success || !mounted) {
      return;
    }

    if (widget.hasPhoneNumber && phone != null && phone.isNotEmpty) {
      final resendSuccess = await cubit.resendOtp(
        phone: phone,
        phoneCountry: cubit.state.phoneCountryCode,
        isNew: true,
      );

      if (!resendSuccess || !mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: WaitingResponseScreen(
              phone: phone,
              country: cubit.state.phoneCountryCode,
              langCode: widget.langCode,
              nextScreen: widget.mainAppScreen,
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

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.mainAppScreen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? Theme.of(context).colorScheme.primary;

    return BlocProvider<AuthUiCubit>(
      create: (_) => AuthUiCubit(module: widget.module),
      child: BlocConsumer<AuthUiCubit, AuthUiState>(
        listener: (context, state) {
          if (state.user != null) {
            _handlePostLoginRoute(context.read<AuthUiCubit>());
          }
        },
        builder: (context, state) {
          final cubit = context.read<AuthUiCubit>();

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
                      if (widget.showProfilePicture)
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Column(
                              children: [
                                widget.logo ??
                                    CircleAvatar(
                                      radius: 44,
                                      backgroundColor: color.withOpacity(0.12),
                                      backgroundImage: _selectedImage != null
                                          ? FileImage(File(_selectedImage!.path))
                                          : null,
                                      child: _selectedImage == null
                                          ? Icon(
                                              CupertinoIcons.camera,
                                              size: 34,
                                              color: color,
                                            )
                                          : null,
                                    ),
                                const SizedBox(height: 8),
                                Text(
                                  tr('add_photo'),
                                  style: TextStyle(color: color),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (widget.logo != null)
                        Center(child: widget.logo),
                      const SizedBox(height: 20),
                      Text(
                        widget.title ?? tr('sign_up'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((widget.subtitle ?? tr('signup_msg')).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle ?? tr('signup_msg'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      if (widget.socialProviders != null &&
                          widget.socialProviders!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.socialProviders!
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
                      ] else ...[
                        const SizedBox(height: 28),
                      ],
                      ModuleTextField(
                        onSaved: (_) {},
                        fromAuth: true,
                        controller: _nameController,
                        title: widget.nameLabel ?? tr('name'),
                        hintText: widget.nameHint ?? tr('name'),
                        textInputType: TextInputType.name,
                        prefix: const Icon(CupertinoIcons.person, size: 20),
                        validator: (value) {
                          final input = (value ?? '').trim();
                          if (input.isEmpty) {
                            return tr('name_is_required');
                          }
                          return null;
                        },
                      ),
                      if (widget.hasEmail) ...[
                        const SizedBox(height: 16),
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
                        ),
                      ],
                      if (widget.hasPhoneNumber) ...[
                        const SizedBox(height: 16),
                        ModulePhoneField(
                          title: widget.phoneLabel ?? tr('phone_number'),
                          hintText: widget.phoneHint,
                          controller: _phoneController,
                          langCode: widget.langCode,
                          onCodeChanged: cubit.setPhoneCountryCode,
                          onChanged: (_) {},
                        ),
                      ],
                      if (widget.hasPassword) ...[
                        const SizedBox(height: 16),
                        ModulePasswordTextField(
                          title: widget.passwordLabel ?? tr('password'),
                          hintText: widget.passwordHint ?? tr('password_hint'),
                          controller: _passwordController,
                          color: color,
                          validatorTextField: (value) {
                            final input = (value ?? '').trim();
                            if (input.isEmpty) {
                              return tr('password_is_required');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ModulePasswordTextField(
                          title: tr('confirm_new_password'),
                          hintText: widget.passwordHint ?? tr('password_hint'),
                          controller: _confirmPasswordController,
                          color: color,
                          validatorTextField: (value) {
                            final input = (value ?? '').trim();
                            if (input.isEmpty) {
                              return tr('confirm_new_password_is_required');
                            }
                            if (input != _passwordController.text) {
                              return tr('passwords_not_match');
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 22),
                      ModuleButton(
                        onTap: state.isLoading ? null : () => _submit(cubit),
                        title: tr('sign_up'),
                        color: color,
                        isLoading: state.isLoading,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(tr('already_have_account')),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              tr('sign_in'),
                              style: TextStyle(color: color),
                            ),
                          ),
                        ],
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
