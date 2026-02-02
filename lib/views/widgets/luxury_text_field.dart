import 'package:flutter/material.dart';

class LuxuryTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final InputCounterWidgetBuilder? buildCounter;
  final bool showShadow;
  final bool useDarkOutlineBorder;

  const LuxuryTextField({
    super.key,
    required this.controller,
    this.decoration = const InputDecoration(),
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.buildCounter,
    this.showShadow = true,
    this.useDarkOutlineBorder = false,
  });

  @override
  State<LuxuryTextField> createState() => _LuxuryTextFieldState();
}

class _LuxuryTextFieldState extends State<LuxuryTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final isFocused = _focusNode.hasFocus;
    final borderRadius = BorderRadius.circular(12);

    final baseFill = isLight
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLow;
    final focusedFill = isLight ? colorScheme.surface : baseFill;
    final fillColor = widget.enabled
        ? (isFocused ? focusedFill : baseFill)
        : baseFill.withValues(alpha: 0.6);

    final baseShadowColor = isLight
        ? const Color(0xFF9E9E9E).withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.25);
    final focusShadowColor =
        colorScheme.secondary.withValues(alpha: isLight ? 0.25 : 0.35);

    final shadows = widget.showShadow
        ? <BoxShadow>[
            BoxShadow(
              color: baseShadowColor,
              blurRadius: isLight ? 24 : 18,
              offset: isLight ? const Offset(0, 12) : const Offset(0, 6),
              spreadRadius: isLight ? -6 : 0,
            ),
            if (isLight && isFocused)
              BoxShadow(
                color: focusShadowColor,
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -6,
            ),
          ]
        : const <BoxShadow>[];

    final enabledBorderSide = isLight
        ? BorderSide.none
        : (widget.useDarkOutlineBorder
            ? BorderSide(color: const Color(0xFFC4A462).withValues(alpha: 0.3))
            : BorderSide.none);
    final focusedBorderSide = BorderSide(
      color: isLight
          ? colorScheme.secondary
          : (widget.useDarkOutlineBorder
              ? const Color(0xFFC4A462) // Champagne Gold for dark mode
              : colorScheme.primary),
      width: 1,
    );

    final decoration = widget.decoration.copyWith(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: enabledBorderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: focusedBorderSide,
      ),
      contentPadding:
          widget.decoration.contentPadding ?? const EdgeInsets.all(16),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadows,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        validator: widget.validator,
        onChanged: widget.onChanged,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        buildCounter: widget.buildCounter,
        decoration: decoration,
      ),
    );
  }
}
