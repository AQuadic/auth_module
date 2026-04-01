import 'package:auth_module/src/presentation/cubit/auth_ui_cubit.dart';
import 'package:auth_module/src/presentation/cubit/auth_ui_state.dart';
import 'package:auth_module/src/presentation/localization/module_localizations.dart';
import 'package:auth_module/src/presentation/widgets/module_button.dart';
import 'package:auth_module/src/presentation/widgets/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.langCode,
    required this.mainAppScreen,
    this.email,
    this.phone,
    this.phoneCountry,
    this.verifyType,
    this.primaryColor,
  });

  final String langCode;
  final Widget mainAppScreen;
  final String? email;
  final String? phone;
  final String? phoneCountry;
  final String? verifyType;
  final Color? primaryColor;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _otp = '';

  String tr(String key) => ModuleLocalizations.tr(widget.langCode, key);

  @override
  void initState() {
    super.initState();
    context.read<AuthUiCubit>().startOtpCountdown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify(AuthUiCubit cubit) async {
    if (_otp.trim().length < 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('invalid_otp'))));
      return;
    }

    final success = await cubit.verifyOtp(
      code: _otp.trim(),
      email: widget.email,
      phone: widget.phone,
      phoneCountry: widget.phoneCountry,
      type: widget.verifyType,
    );

    if (!mounted || !success) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.mainAppScreen),
      (route) => false,
    );
  }

  Future<void> _resend(AuthUiCubit cubit) async {
    final success = await cubit.resendOtp(
      email: widget.email,
      phone: widget.phone,
      phoneCountry: widget.phoneCountry,
      verifyType: widget.verifyType,
    );

    if (success) {
      cubit.startOtpCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? Theme.of(context).colorScheme.primary;

    return BlocConsumer<AuthUiCubit, AuthUiState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<AuthUiCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(tr('otp_screen_title')),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Icon(Icons.mark_email_read_outlined, size: 72, color: color),
                const SizedBox(height: 16),
                Text(
                  widget.email ?? widget.phone ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                ModuleTextField(
                  controller: _codeController,
                  onSaved: (_) {},
                  fromAuth: true,
                  title: tr('otp_code'),
                  hintText: '000000',
                  maxLength: 6,
                  textInputType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    _otp = value ?? '';
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: state.waitingSeconds > 0 || state.isLoading
                      ? null
                      : () => _resend(cubit),
                  child: Text(
                    state.waitingSeconds > 0
                        ? '${tr('send_again')} (${state.waitingSeconds}s)'
                        : '${tr('dont_receive_code')} ${tr('send_again')}',
                  ),
                ),
                const SizedBox(height: 8),
                ModuleButton(
                  onTap: state.isLoading ? null : () => _verify(cubit),
                  title: tr('confirm'),
                  color: color,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
