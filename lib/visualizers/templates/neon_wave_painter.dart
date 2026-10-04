import 'dart:ui';

import '../../models/visualizer_settings.dart';
import '../visualizer_painter_base.dart';

/// A glowing, neon-styled waveform: a strong blurred backing stroke plus a
/// bright core line, both driven by the live frequency-band snapshot.
class NeonWavePainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    const sampleCount = 40;
    final samples = resample(data.bands, sampleCount);
    final midY = size.height / 2;
    final amp = (0.5 + data.amplitude * 0.5 * settings.sensitivity);

    Path buildPath() {
      final path = Path();
      for (var i = 0; i < sampleCount; i++) {
        final x = size.width * i / (sampleCount - 1);
        final value = (samples[i] * settings.sensitivity).clamp(0.0, 1.3);
        final y = midY - value * midY * 0.85 * amp;
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

    final path = buildPath();

    final outerGlow = Paint()
      ..color = settings.primaryColor.withValues(alpha: settings.opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.barWidth * 1.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        6 + settings.glowIntensity * 20,
      );
    canvas.drawPath(path, outerGlow);

    final core = Paint()
      ..color = Color.lerp(
        settings.primaryColor,
        const Color(0xFFFFFFFF),
        0.5,
      )!.withValues(alpha: settings.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.barWidth * 0.3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, core);
  }
}
