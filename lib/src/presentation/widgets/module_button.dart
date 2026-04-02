import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ModuleButton extends StatefulWidget {
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
  final TextStyle? textStyle;
  final int? maxLines;
  final bool? center;
  final bool? forceTextDirection;
  final bool isLoading;

  const ModuleButton({
    super.key,
    required this.onTap,
    required this.title,
    this.color,
    this.forceLeftRight,
    this.title2,
    this.borderColor,
    this.width,
    this.height = 50,
    this.radius = 12.0,
    this.fontSize = 16,
    this.fontFamily,
    this.titleColor = Colors.white,
    this.fontWeight = FontWeight.w600,
    this.textStyle,
    this.maxLines,
    this.forceTextDirection,
    this.center = false,
    this.isLoading = false,
  });

  @override
  State<ModuleButton> createState() => _ModuleButtonState();
}

class _ModuleButtonState extends State<ModuleButton> {
  double? _fullWidth;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureWidth());
  }

  @override
  void didUpdateWidget(ModuleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureWidth());
    }
  }

  void _captureWidth() {
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final w = box.size.width;
    if (w > 0 && w.isFinite && w != _fullWidth) {
      setState(() => _fullWidth = w);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor =
        widget.color ?? Theme.of(context).colorScheme.primary;
    final Color resolvedTitleColor = widget.titleColor ?? Colors.white;

    // Don't animate until we have a real finite width
    final bool canAnimate = _fullWidth != null && _fullWidth!.isFinite;
    final double targetWidth = widget.isLoading
        ? widget.height
        : (_fullWidth ?? widget.height);

    return SizedBox(
      key: _key,
      width: widget.width ?? double.infinity,
      height: widget.height,
      child: Align(
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: canAnimate
              ? const Duration(milliseconds: 350)
              : Duration.zero,
          curve: Curves.easeInOut,
          width: targetWidth,
          height: widget.height,
          child: Material(
            color: resolvedColor,
            borderRadius: BorderRadius.circular(
              widget.isLoading ? widget.height / 2 : widget.radius,
            ),
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onTap,
              borderRadius: BorderRadius.circular(
                widget.isLoading ? widget.height / 2 : widget.radius,
              ),
              child: Container(
                alignment: Alignment.center,
                padding: widget.isLoading
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    widget.isLoading ? widget.height / 2 : widget.radius,
                  ),
                  border: widget.borderColor != null
                      ? Border.all(color: widget.borderColor!)
                      : null,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: widget.isLoading
                      ? SizedBox(
                          key: const ValueKey('loader'),
                          width: widget.height * 0.45,
                          height: widget.height * 0.45,
                          child: CupertinoActivityIndicator(
                            color: resolvedTitleColor,
                          ),
                        )
                      : Text(
                          key: const ValueKey('label'),
                          widget.title2 == null
                              ? widget.title
                              : '${widget.title} ${widget.title2!}',
                          style:
                              widget.textStyle ??
                              TextStyle(
                                fontSize: widget.fontSize,
                                fontWeight: widget.fontWeight,
                                color: resolvedTitleColor,
                                fontFamily: widget.fontFamily,
                              ),
                          maxLines: widget.maxLines,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          textDirection: widget.forceTextDirection == true
                              ? TextDirection.ltr
                              : null,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
