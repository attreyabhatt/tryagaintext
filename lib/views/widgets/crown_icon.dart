import 'package:flutter/material.dart';

class CrownIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const CrownIcon({
    super.key,
    required this.color,
    this.size = 20,
    this.strokeWidth = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CrownPainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _CrownPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final baseY = h * 0.78;
    final leftX = w * 0.12;
    final rightX = w * 0.88;

    final path = Path()
      ..moveTo(leftX, baseY)
      ..lineTo(w * 0.24, h * 0.40)
      ..lineTo(w * 0.40, h * 0.60)
      ..lineTo(w * 0.50, h * 0.30)
      ..lineTo(w * 0.60, h * 0.60)
      ..lineTo(w * 0.76, h * 0.40)
      ..lineTo(rightX, baseY)
      ..lineTo(leftX, baseY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
