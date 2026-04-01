import 'package:auth_module/src/presentation/cubit/auth_ui_cubit.dart';
import 'package:auth_module/src/presentation/cubit/auth_ui_state.dart';
import 'package:auth_module/src/presentation/localization/module_localizations.dart';
import 'package:auth_module/src/presentation/widgets/module_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WaitingResponseScreen extends StatefulWidget {
  const WaitingResponseScreen({
    super.key,
    required this.phone,
    required this.country,
    required this.langCode,
    required this.mainAppScreen,
    this.primaryColor,
  });

  final String phone;
  final String country;
  final String langCode;
  final Widget mainAppScreen;
  final Color? primaryColor;

  @override
  State<WaitingResponseScreen> createState() => _WaitingResponseScreenState();
}

class _WaitingResponseScreenState extends State<WaitingResponseScreen> {
  String tr(String key) => ModuleLocalizations.tr(widget.langCode, key);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AuthUiCubit>().startWaitingForPhoneVerification(
        phone: widget.phone,
        phoneCountry: widget.country,
        onVerified: _onVerified,
      );
    });
  }

  void _onVerified() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.mainAppScreen),
      (route) => false,
    );
  }

  Future<void> _resend(AuthUiCubit cubit) async {
    await cubit.resendOtp(
      phone: widget.phone,
      phoneCountry: widget.country,
      isNew: true,
    );
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
        final message = state.verificationMessage;

        return Scaffold(
          appBar: AppBar(title: Text(tr('fast_verification'))),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Icon(Icons.mark_chat_unread_outlined, size: 72, color: color),
                const SizedBox(height: 20),
                Text(
                  tr('whatsapp_verification_msg'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Text(
                  tr('sure_send_message'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.country} ${widget.phone}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (message != null && message.isNotEmpty)
                  SelectableText(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ModuleButton(
                  onTap: state.isLoading ? null : () => _resend(cubit),
                  title: tr('generate_new_code'),
                  color: color,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr('change_number')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
