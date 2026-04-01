import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
export 'package:flutter/services.dart';

class ModuleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final TextStyle? hintStyle;
  final TextStyle? style;
  final String? title;
  final String? errorText;
  final String? label;
  final String? initialValue;
  final FormFieldSetter<String?>? onSaved;
  final FormFieldSetter<String?>? onChanged;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final TextAlign? textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? textInputType;
  final bool? obSecure;
  final Color? fillColor;
  final Color? cursorColor;
  final bool readOnly;
  final bool filled;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? titleAction;
  final VoidCallback? onTap;
  final bool isSearch;
  final bool hasBorder;
  final bool fullBorder;
  final double? width;
  final FormFieldValidator<String>? validatorTextField;
  final TextInputAction? textInputAction;
  final double padding;
  final TextStyle? titleStyle;
  final double? radius;
  final Color? borderColor;
  final FocusNode? focusNode;

  /// from auth => fill color in input border is different in auth and the rest of the app
  final bool fromAuth;

  const ModuleTextField({
    super.key,
    @required this.onSaved,
    this.hintStyle,
    this.onChanged,
    this.title,
    this.readOnly = false,
    required this.hintText,
    this.label,
    this.filled = false,
    this.textAlign,
    this.style,
    this.width,
    this.errorText,
    this.initialValue,
    this.titleAction,
    this.controller,
    this.fillColor,
    this.inputFormatters,
    this.maxLines = 1,
    this.validatorTextField,
    this.validator,
    this.textInputType,
    this.cursorColor,
    this.obSecure = false,
    this.suffixIcon,
    this.maxLength,
    this.prefix,
    this.onTap,
    this.textInputAction,
    required this.fromAuth,
    this.isSearch = false,
    this.padding = 0,
    this.titleStyle,
    this.radius,
    this.focusNode,
    this.borderColor,
    this.fullBorder = true,
    this.hasBorder = true,
  });

  Color? getFillColor(BuildContext context) {
    if (fillColor != null) {
      return fillColor;
    }
    return fromAuth
        ? Theme.of(context).inputDecorationTheme.fillColor
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style:
                      titleStyle ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (titleAction != null) titleAction!,
              ],
            ),
          ),
        if (title != null) const SizedBox(height: 8),
        TextFormField(
          focusNode: focusNode,
          onTap: onTap,
          onTapOutside: (event) {
            FocusScope.of(context).unfocus();
          },
          readOnly: readOnly,
          textAlignVertical: TextAlignVertical.top,
          obscureText: obSecure ?? false,
          controller: controller,
          enabled: onSaved != null,
          onChanged: onChanged,
          cursorColor: cursorColor ?? Theme.of(context).colorScheme.primary,
          validator: validator ?? validatorTextField,
          onSaved: onSaved,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          keyboardType: textInputType,
          maxLength: maxLength,
          style:
              style ??
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          initialValue: initialValue,
          textAlign: textAlign ?? TextAlign.start,
          textInputAction: textInputAction ?? TextInputAction.done,
          decoration: InputDecoration(
            fillColor: getFillColor(context),
            enabledBorder: hasBorder
                ? fullBorder
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radius ?? 10),
                          borderSide: BorderSide(
                            color: borderColor ?? Colors.grey.shade300,
                            width: 1,
                          ),
                        )
                      : UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: borderColor ?? Colors.grey.shade300,
                            width: 1,
                          ),
                        )
                : null,
            focusedBorder: hasBorder
                ? fullBorder
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(radius ?? 8),
                          borderSide: BorderSide(
                            color:
                                borderColor ??
                                Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        )
                      : UnderlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                borderColor ??
                                Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 8,
            ),
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: prefix,
                  )
                : null,
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle:
                hintStyle ??
                TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).hintColor,
                ),
            filled: filled,
            labelText: label,
            isDense: true,
            counter: const SizedBox(),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('hasBorder', hasBorder));
  }
}
