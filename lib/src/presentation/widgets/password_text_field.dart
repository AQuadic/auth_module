import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'text_field_widget.dart';

class ModulePasswordTextField extends StatefulWidget {
  final FormFieldSetter<String?>? onChanged;
  final TextEditingController? controller;
  final String hintText;
  final String title;
  final FormFieldValidator? validatorTextField;
  final Color? color;

  const ModulePasswordTextField({
    super.key,
    this.onChanged,
    this.controller,
    required this.hintText,
    this.title = "password",
    this.validatorTextField,
    this.color,
  });

  @override
  State<ModulePasswordTextField> createState() =>
      _ModulePasswordTextFieldState();
}

class _ModulePasswordTextFieldState extends State<ModulePasswordTextField> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    return ModuleTextField(
      title: widget.title,
      onSaved: (v) {},
      readOnly: false,
      borderColor: Colors.grey.shade300,
      validatorTextField: widget.validatorTextField?.call,
      onChanged: widget.onChanged,
      controller: widget.controller,
      hintText: widget.hintText,
      fromAuth: true,
      obSecure: !showPassword,
      prefix: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(CupertinoIcons.lock, size: 20),
      ),
      suffixIcon: InkWell(
        onTap: () {
          setState(() {
            showPassword = !showPassword;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            showPassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
            size: 24,
            color: showPassword
                ? widget.color ?? Colors.blue
                : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
