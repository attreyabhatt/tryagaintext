import 'package:flutter/material.dart';

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient gradient;
  final String? semanticLabel;

  const GradientIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.gradient,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      blendMode: BlendMode.srcIn,
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
