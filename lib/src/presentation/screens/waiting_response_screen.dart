import 'package:auth_module/src/presentation/cubit/auth_ui_cubit.dart';
import 'package:auth_module/src/presentation/cubit/auth_ui_state.dart';
import 'package:auth_module/src/presentation/localization/module_localizations.dart';
import 'package:auth_module/src/presentation/screens/complete_profile_screen.dart';
import 'package:auth_module/src/presentation/widgets/module_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:libphonenumber_plugin/libphonenumber_plugin.dart';

class WaitingResponseScreen extends StatefulWidget {
  const WaitingResponseScreen({
    super.key,
    required this.phone,
    required this.country,
    required this.langCode,
    required this.nextScreen,
    this.clearStackOnVerified = true,
    this.primaryColor,
    this.onInterceptorDialogFlagChange,
    this.cloudwaLogo,
    this.hasCompleteProfile = false,
  });

  final String phone;
  final String country;
  final String langCode;
  final Widget nextScreen;
  final bool clearStackOnVerified;
  final Color? primaryColor;
  final ValueChanged<bool>? onInterceptorDialogFlagChange;
  final Widget? cloudwaLogo;
  final bool hasCompleteProfile;

  @override
  State<WaitingResponseScreen> createState() => _WaitingResponseScreenState();
}

class _WaitingResponseScreenState extends State<WaitingResponseScreen> {
  String tr(String key) => ModuleLocalizations.tr(widget.langCode, key);
  String? formattedPhone;
  late AuthUiCubit _cubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit = context.read<AuthUiCubit>();
  }

  @override
  void initState() {
    super.initState();
    widget.onInterceptorDialogFlagChange?.call(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      startService();
    });
  }

  void startService() async {
    formattedPhone = await PhoneNumberUtil.normalizePhoneNumber(
      widget.phone,
      widget.country,
    );
    setState(() {});
    if (mounted) {
      _cubit.startWaitingForPhoneVerification(
        phone: widget.phone,
        phoneCountry: widget.country,
        onVerified: _onVerified,
      );
    }
  }

  void _onVerified() {
    _handleVerifiedRoute();
  }

  Future<void> _handleVerifiedRoute() async {
    final user = _cubit.state.user;
    final shouldCompleteProfile =
        widget.hasCompleteProfile && (user?.isDefaultName ?? false);

    final target = shouldCompleteProfile
        ? CompleteProfileScreen(
            langCode: widget.langCode,
            mainAppScreen: widget.nextScreen,
            primaryColor: widget.primaryColor,
          )
        : widget.nextScreen;

    if (widget.clearStackOnVerified) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => target),
        (route) => false,
      );
      return;
    }

    widget.onInterceptorDialogFlagChange?.call(true);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
  }

  Future<void> _resend(AuthUiCubit cubit) async {
    await _cubit.resendOtp(
      phone: widget.phone,
      phoneCountry: widget.country,
      isNew: true,
    );
  }

  @override
  void dispose() {
    widget.onInterceptorDialogFlagChange?.call(true);
    _cubit.stopWaitingForPhoneVerification();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? Theme.of(context).colorScheme.primary;

    return BlocBuilder<AuthUiCubit, AuthUiState>(
      builder: (context, state) {
        final cubit = context.read<AuthUiCubit>();

        return Scaffold(
          appBar: AppBar(title: Text(tr('fast_verification'))),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                widget.cloudwaLogo ??
                    Image.asset(
                      'assets/images/rocket.png',
                      package: 'auth_module',
                      height: MediaQuery.of(context).size.height * 0.2,
                    ),
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
                  formattedPhone ?? widget.phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    tr('change_number'),
                    style: TextStyle(color: color),
                  ),
                ),
                SizedBox(height: 24),
                SelectableText(
                  state.otpResponse?.message ?? "",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                ModuleButton(
                  onTap: () => _resend(cubit),
                  title: tr('generate_new_code'),
                  color: Colors.transparent,
                  titleColor: color,
                  isLoading: state.isLoading,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 12),
                ModuleButton(
                  onTap: () {
                    final scheme = state.otpResponse?.scheme;
                    if (scheme != null && scheme.isNotEmpty) {
                      launchUrl(
                        Uri.parse(scheme),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  title: tr('continue'),
                  color: color,
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () {
                    launchUrl(
                      Uri.parse('https://www.cloudwa.net/'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tr('powered_by'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 4),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF8285F0), Color(0xFF473195)],
                            ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                        child: Text(
                          'CloudWa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
