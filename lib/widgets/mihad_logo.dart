import 'package:flutter/material.dart';

import '../app/theme.dart';

/// MIHAD AUDIO's original, entirely Flutter-drawn brand mark: a rounded
/// tile with a small waveform glyph. No external assets or third-party
/// logos are used.
class MihadLogo extends StatelessWidget {
  final double size;
  const MihadLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: MihadColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: MihadColors.accentPrimary.withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: CustomPaint(painter: _LogoWavePainter()),
    );
  }
}

class _LogoWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;

    final heights = [0.3, 0.6, 0.95, 0.5, 0.75, 0.35];
    final barSpace = size.width / (heights.length + 1);
    for (var i = 0; i < heights.length; i++) {
      final x = barSpace * (i + 1);
      final h = size.height * heights[i] * 0.55;
      final midY = size.height / 2;
      canvas.drawLine(Offset(x, midY - h / 2), Offset(x, midY + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
