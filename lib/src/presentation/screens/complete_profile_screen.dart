import 'dart:io';

import 'package:auth_module/auth_module.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({
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
    this.emailHint,
    this.phoneHint,
    this.contentPadding = const EdgeInsets.all(20),
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
  final String? emailHint;
  final String? phoneHint;
  final EdgeInsetsGeometry contentPadding;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  String tr(String key) => ModuleLocalizations.tr(widget.langCode, key);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefillUserData();
    });
  }

  Future<void> _prefillUserData() async {
    final cubit = context.read<AuthUiCubit>();
    final user = cubit.state.user ?? await cubit.fetchCurrentUser();
    if (!mounted || user == null) {
      return;
    }

    _nameController.text = user.name ?? '';
    _emailController.text = user.email ?? '';
    _phoneController.text = user.phone ?? '';
    if (user.phoneCountry != null && user.phoneCountry!.isNotEmpty) {
      cubit.setPhoneCountryCode(user.phoneCountry!);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

    final success = await cubit.updateProfile(
      image: _selectedImage,
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      countryCode: cubit.state.phoneCountryCode,
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
      create: (_) => AuthUiCubit(),
      child: BlocConsumer<AuthUiCubit, AuthUiState>(
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
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title ?? tr('complete_profile_title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((widget.subtitle ?? tr('complete_profile_subtitle'))
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle ?? tr('complete_profile_subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
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
                            return null;
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(input)) {
                            return tr('invalid_email');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ModulePhoneField(
                        title: widget.phoneLabel ?? tr('phone_number'),
                        hintText: widget.phoneHint,
                        controller: _phoneController,
                        langCode: widget.langCode,
                        onCodeChanged: cubit.setPhoneCountryCode,
                        onChanged: (_) {},
                        isRequired: false,
                      ),
                      const SizedBox(height: 22),
                      ModuleButton(
                        onTap: state.isLoading ? null : () => _submit(cubit),
                        title: tr('submit'),
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
