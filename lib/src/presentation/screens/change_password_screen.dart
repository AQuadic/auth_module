import 'package:auth_module/auth_module.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.langCode,
    required this.mainAppScreen,
    this.logo,
    this.title,
    this.subtitle,
    this.primaryColor,
    this.contentPadding = const EdgeInsets.all(20),
    this.module,
  });

  final String langCode;
  final Widget mainAppScreen;
  final Widget? logo;
  final String? title;
  final String? subtitle;
  final Color? primaryColor;
  final EdgeInsetsGeometry contentPadding;
  final AuthModule? module;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  String tr(String key) => ModuleLocalizations.tr(widget.langCode, key);

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthUiCubit cubit) async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final success = await cubit.changePassword(
      oldPassword: _oldPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
      confirmPassword: _confirmNewPasswordController.text.trim(),
    );

    if (!success || !mounted) {
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
      child: BlocBuilder<AuthUiCubit, AuthUiState>(
        builder: (context, state) {
          final cubit = context.read<AuthUiCubit>();
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
                            Icon(CupertinoIcons.lock, size: 76, color: color),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title ?? tr('change_password'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((widget.subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle ?? tr('change_password_msg'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      ModulePasswordTextField(
                        title: tr('old_password'),
                        hintText: tr('password_hint'),
                        controller: _oldPasswordController,
                        color: color,
                        validatorTextField: (value) {
                          final input = (value ?? '').trim();
                          if (input.isEmpty) {
                            return tr('old_password_is_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
      ),
    );
  }
}
