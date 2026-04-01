import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';

import 'text_field_widget.dart';

class ModulePhoneField extends StatefulWidget {
  final String? title;
  final String? hintText;
  final Function(String?)? onChanged;
  final Function(String)? onCodeChanged;
  final String? initialCountryCode;
  final TextEditingController? controller;
  final bool readOnly;
  final bool isRequired;

  const ModulePhoneField({
    super.key,
    this.title,
    this.hintText,
    this.onChanged,
    this.onCodeChanged,
    this.initialCountryCode = 'EG',
    this.controller,
    this.readOnly = false,
    this.isRequired = true,
  });

  @override
  State<ModulePhoneField> createState() => _ModulePhoneFieldState();
}

class _ModulePhoneFieldState extends State<ModulePhoneField> {
  final FlCountryCodePicker _picker = const FlCountryCodePicker();
  late CountryCode _countryCode;

  @override
  void initState() {
    super.initState();
    _countryCode = _picker.countryCodes.firstWhere(
      (element) =>
          element.code.toLowerCase() ==
          (widget.initialCountryCode?.toLowerCase() ?? 'eg'),
    );
  }

  String? get isoCode => _countryCode.code;
  String get dialCode => _countryCode.dialCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              widget.title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: ModuleTextField(
                    readOnly: widget.readOnly,
                    controller: widget.controller,
                    hasBorder: false,
                    fromAuth: true,
                    hintText: widget.hintText ?? '1223456789',
                    onChanged: widget.onChanged,
                    onSaved: (v) {},
                    textInputType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                    ],
                    validator: widget.isRequired
                        ? (value) {
                            final valid = (value ?? '').trim().isNotEmpty;
                            return valid ? null : 'Phone number is required';
                          }
                        : null,
                    prefix: InkWell(
                      onTap: () async {
                        if (widget.readOnly) return;
                        final code = await _picker.showPicker(
                          context: context,
                          initialSelectedLocale:
                              widget.initialCountryCode ?? 'KW',
                        );
                        if (code != null) {
                          setState(() {
                            _countryCode = code;
                            widget.onCodeChanged?.call(code.code);
                          });
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _countryCode.flagImage(),
                          const SizedBox(width: 8),
                          Container(
                            color: Colors.grey.shade300,
                            height: 35,
                            width: 0.5,
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              _countryCode.dialCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
