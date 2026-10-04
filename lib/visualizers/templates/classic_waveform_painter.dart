import 'dart:ui';

import '../../models/visualizer_settings.dart';
import '../visualizer_painter_base.dart';

/// Smooth oscilloscope-style line driven by the current frequency-band
/// snapshot: each band becomes one sample point of the waveform, scaled
/// by overall amplitude and user sensitivity.
class ClassicWaveformPainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    const sampleCount = 48;
    final samples = resample(data.bands, sampleCount);
    final midY = size.height / 2;
    final amp = (data.amplitude * settings.sensitivity).clamp(0.0, 1.5);

    final path = Path();
    for (var i = 0; i < sampleCount; i++) {
      final x = size.width * i / (sampleCount - 1);
      final value = samples[i] * settings.sensitivity;
      final sign = (i.isEven) ? 1.0 : -1.0;
      final y = midY - sign * value * (midY * 0.9) * (0.4 + 0.6 * amp);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = size.width * (i - 1) / (sampleCount - 1);
        final midX = (prevX + x) / 2;
        path.quadraticBezierTo(prevX, y, midX, y);
      }
    }

    final paint = glowPaint(
      settings.primaryColor,
      settings.opacity,
      settings.glowIntensity,
    )..strokeWidth = settings.barWidth * 0.6;
    canvas.drawPath(path, paint);

    final sharpPaint = Paint()
      ..color = settings.primaryColor.withValues(alpha: settings.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.barWidth * 0.35
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, sharpPaint);
  }
}
