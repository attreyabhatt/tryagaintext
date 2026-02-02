import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;
  final List<Color>? colors;

  const PremiumGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 50,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradientColors = colors ??
        <Color>[
          colorScheme.primary,
          Color.lerp(colorScheme.primary, colorScheme.secondary, 0.35) ??
              colorScheme.primary,
        ];

    final resolvedOnPressed = onPressed == null
        ? null
        : () {
            HapticFeedback.mediumImpact();
            onPressed!.call();
          };

    final button = SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: resolvedOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: colorScheme.onPrimary,
            disabledForegroundColor:
                colorScheme.onPrimary.withValues(alpha: 0.8),
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: padding,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          child: child,
        ),
      ),
    );

    if (onPressed == null) {
      return Opacity(opacity: 0.5, child: button);
    }
    return button;
  }
}
