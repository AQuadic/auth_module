import 'package:auth_module/auth_module.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.langCode,
    required this.mainAppScreen,
    this.email,
    this.phone,
    this.phoneCountry,
    this.resetType,
    this.resetToken,
    this.logo,
    this.title,
    this.subtitle,
    this.primaryColor,
    this.contentPadding = const EdgeInsets.all(16),
    this.module,
  });

  final String langCode;
  final Widget mainAppScreen;
  final String? email;
  final String? phone;
  final String? phoneCountry;
  final String? resetType;
  final String? resetToken;
  final Widget? logo;
  final String? title;
  final String? subtitle;
  final Color? primaryColor;
  final EdgeInsetsGeometry contentPadding;
  final AuthModule? module;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  String tr(String key) => ModuleLocalizations.tr(widget.langCode, key);

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthUiCubit cubit) async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmNewPasswordController.text.trim();

    final success = await cubit.resetPassword(
      email: widget.email,
      phone: widget.phone,
      phoneCountry: widget.phoneCountry,
      password: newPassword,
      passwordConfirmation: confirmPassword,
      resetToken: widget.resetToken,
      resetType: widget.resetType,
    );

    if (!success || !mounted) {
      return;
    }

    final primaryColor =
        widget.primaryColor ?? Theme.of(context).colorScheme.primary;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: primaryColor,
          content: Text(
            tr('reset_password_success_msg'),
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

    // await Future<void>.delayed(const Duration(seconds: 3));

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? Theme.of(context).colorScheme.primary;
    final cubit = context.read<AuthUiCubit>();

    return BlocBuilder<AuthUiCubit, AuthUiState>(
      builder: (context, state) {
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
                            CupertinoIcons.lock_rotation,
                            size: 76,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.title ?? tr('reset_password'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((widget.subtitle ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle ?? tr('reset_password_msg'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    ModulePasswordTextField(
                      title: tr('new_password'),
                      hintText: tr('password_hint'),
                      controller: _newPasswordController,
                      color: color,
                      validatorTextField: (value) {
                        final input = (value ?? '').trim();
                        if (input.isEmpty) {
                          return tr('new_password_is_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ModulePasswordTextField(
                      title: tr('confirm_new_password'),
                      hintText: tr('password_hint'),
                      controller: _confirmNewPasswordController,
                      color: color,
                      validatorTextField: (value) {
                        final input = (value ?? '').trim();
                        if (input.isEmpty) {
                          return tr('confirm_new_password_is_required');
                        }
                        if (input != _newPasswordController.text.trim()) {
                          return tr('passwords_not_match');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    ModuleButton(
                      onTap: state.isLoading ? null : () => _submit(cubit),
                      title: tr('confirm'),
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
    );
  }
}
