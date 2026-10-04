import 'dart:ui';

import '../../models/visualizer_settings.dart';
import '../visualizer_painter_base.dart';

/// A thin, understated single-line waveform - a calmer alternative to
/// Classic Waveform, with no glow and fewer sample points.
class MinimalLineWavePainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    const sampleCount = 20;
    final samples = resample(data.bands, sampleCount);
    final midY = size.height / 2;

    final path = Path()..moveTo(0, midY);
    for (var i = 0; i < sampleCount; i++) {
      final x = size.width * i / (sampleCount - 1);
      final value = (samples[i] * settings.sensitivity).clamp(0.0, 1.0);
      final y = midY - value * midY * 0.7;
      if (i == 0) {
        path.lineTo(x, y);
      } else {
        final prevX = size.width * (i - 1) / (sampleCount - 1);
        final cx = (prevX + x) / 2;
        path.quadraticBezierTo(prevX, y, cx, y);
      }
    }

    final paint = Paint()
      ..color = settings.primaryColor.withValues(alpha: settings.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.barWidth * 0.3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }
}
