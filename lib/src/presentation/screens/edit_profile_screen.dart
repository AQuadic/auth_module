import 'dart:io';

import 'package:aq_tools/aq_tools.dart';
import 'package:auth_module/src/core/auth_module_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../localization/module_localizations.dart';
import '../widgets/module_button.dart';
import '../widgets/phone_field.dart';
import '../widgets/text_field_widget.dart';

class EditProfileScreen extends StatefulWidget {
  final String langCode;
  final Color? primaryColor;

  const EditProfileScreen({super.key, this.langCode = 'en', this.primaryColor});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  String? _phoneCountry = 'EG';
  String? _gender;
  XFile? _pickedImage;
  ResponsiveImageModel? _currentImageModel;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initFromUser();
  }

  void _initFromUser() {
    final user = AuthModule.instance.user;
    if (user == null) return;
    _nameCtrl.text = user.name ?? '';
    _emailCtrl.text = user.email ?? '';
    _phoneCtrl.text = user.phone ?? '';
    _phoneCountry = user.phoneCountry ?? 'EG';
    _gender = user.gender;
    _currentImageModel = user.image;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  ModuleLocalizations.tr(
                    widget.langCode,
                    'choose_from_gallery',
                  ),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(
                  ModuleLocalizations.tr(widget.langCode, 'take_photo'),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (picked == null) return;

    if (!mounted) return;
    setState(() => _pickedImage = picked);
  }

  Widget _buildResponsiveImage(double size) {
    final srcSet = _currentImageModel?.imageSrcSets ?? {0: ''};
    final uuid = _currentImageModel?.uuid;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: _pickedImage != null
          ? ClipOval(
              child: Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
            )
          : CachedNetworkImage(
              imageUrl: srcSet.values.isNotEmpty ? srcSet.values.first : '',
              cacheKey: uuid,
              fit: BoxFit.cover,
              placeholder: (ctx, _) => const SizedBox.shrink(),
              errorWidget: (ctx, err, _) =>
                  Image.asset('assets/images/logo.png', fit: BoxFit.scaleDown),
            ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final result = await AuthModule.instance.updateUser(
      image: _pickedImage,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      countryCode: _phoneCountry,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      gender: _gender,
    );

    setState(() => _isSaving = false);

    if (result.isSuccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                ModuleLocalizations.tr(widget.langCode, 'profile_updated'),
          ),
        ),
      );
      Navigator.of(context).maybePop();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                ModuleLocalizations.tr(
                  widget.langCode,
                  'profile_update_failed',
                ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary =
        widget.primaryColor ?? Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(ModuleLocalizations.tr(widget.langCode, 'edit_profile')),
        backgroundColor: primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _buildResponsiveImage(110),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ModuleTextField(
                fromAuth: true,
                hintText: ModuleLocalizations.tr(widget.langCode, 'name'),
                onSaved: (v) {},
                onChanged: (v) {},
                controller: _nameCtrl,
              ),
              const SizedBox(height: 12),
              ModuleTextField(
                fromAuth: true,
                hintText: ModuleLocalizations.tr(widget.langCode, 'email'),
                onSaved: (v) {},
                onChanged: (v) {},
                controller: _emailCtrl,
                textInputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              ModulePhoneField(
                langCode: widget.langCode,
                initialCountryCode: _phoneCountry,
                controller: _phoneCtrl,
                onChanged: (v) {},
                onCodeChanged: (code) => _phoneCountry = code,
              ),
              const SizedBox(height: 12),
              Text(
                ModuleLocalizations.tr(widget.langCode, 'gender'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String?>(
                      value: 'male',
                      groupValue: _gender,
                      title: Text(
                        ModuleLocalizations.tr(widget.langCode, 'male'),
                      ),
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String?>(
                      value: 'female',
                      groupValue: _gender,
                      title: Text(
                        ModuleLocalizations.tr(widget.langCode, 'female'),
                      ),
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ModuleButton(
                title: ModuleLocalizations.tr(widget.langCode, 'submit'),
                onTap: _onSave,
                isLoading: _isSaving,
                color: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
