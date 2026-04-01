import 'package:flutter/material.dart';

class ModuleButton extends StatelessWidget {
  final String title;
  final String? title2;
  final VoidCallback? onTap;
  final FontWeight fontWeight;
  final Color? color;
  final Color? titleColor;
  final Color? borderColor;
  final double? fontSize;
  final String? fontFamily;
  final double? width;
  final double height;
  final double radius;
  final bool? forceLeftRight;
  final Widget? suffex;
  final Widget? prefix;
  final TextStyle? textStyle;
  final int? maxLines;
  final bool? center;
  final bool? forceTextDirection;

  const ModuleButton({
    super.key,
    required this.onTap,
    required this.title,
    this.color,
    this.forceLeftRight,
    this.title2,
    this.borderColor,
    this.width,
    this.height = 55,
    this.radius = 12.0,
    this.fontSize = 16,
    this.fontFamily,
    this.titleColor = Colors.white,
    this.fontWeight = FontWeight.w600,
    this.suffex,
    this.prefix,
    this.textStyle,
    this.maxLines,
    this.forceTextDirection,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    final Color resolvedTitleColor = titleColor ?? Colors.white;

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Material(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: borderColor != null
                  ? Border.all(color: borderColor!)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (prefix != null) prefix!,
                if (prefix != null) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title2 == null ? title : '$title ${title2!}',
                    style:
                        textStyle ??
                        TextStyle(
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                          color: resolvedTitleColor,
                          fontFamily: fontFamily,
                        ),
                    maxLines: maxLines,
                    textAlign: TextAlign.center,
                    textDirection: forceTextDirection == true
                        ? TextDirection.ltr
                        : null,
                  ),
                ),
                if (suffex != null) const SizedBox(width: 8),
                if (suffex != null) suffex!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
