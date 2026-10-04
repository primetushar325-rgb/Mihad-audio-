import 'dart:ui';

import '../../models/visualizer_settings.dart';
import '../visualizer_painter_base.dart';

/// Two waveforms sharing a center line: the primary-colored wave above,
/// a secondary-colored mirrored wave below.
class DualWaveformPainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    const sampleCount = 32;
    final samples = resample(data.bands, sampleCount);
    final midY = size.height / 2;

    Path buildPath(bool flip) {
      final path = Path();
      for (var i = 0; i < sampleCount; i++) {
        final x = size.width * i / (sampleCount - 1);
        final value = (samples[i] * settings.sensitivity).clamp(0.0, 1.2);
        final dy = value * midY * 0.85;
        final y = flip ? midY + dy : midY - dy;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prevX = size.width * (i - 1) / (sampleCount - 1);
          final cx = (prevX + x) / 2;
          path.quadraticBezierTo(prevX, y, cx, y);
        }
      }
      return path;
    }

    final topPaint = glowPaint(
      settings.primaryColor,
      settings.opacity,
      settings.glowIntensity,
    )..strokeWidth = settings.barWidth * 0.4;
    final bottomPaint = glowPaint(
      settings.secondaryColor,
      settings.opacity,
      settings.glowIntensity,
    )..strokeWidth = settings.barWidth * 0.4;

    canvas.drawPath(buildPath(false), topPaint);
    canvas.drawPath(buildPath(true), bottomPaint);

    final centerLine = Paint()
      ..color = settings.primaryColor.withValues(alpha: settings.opacity * 0.25)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), centerLine);
  }
}
