import 'dart:math' as math;
import 'dart:ui';

import '../../models/visualizer_settings.dart';
import '../visualizer_painter_base.dart';

/// A glowing circle that pulses its radius with overall amplitude, with
/// a secondary ring reacting to the low/mid frequency bands.
class PulseCirclePainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;
    final amp = (data.amplitude * settings.sensitivity).clamp(0.0, 1.3);

    final glow = settings.glowIntensity > 0.01
        ? MaskFilter.blur(BlurStyle.normal, 4 + settings.glowIntensity * 24)
        : null;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = settings.primaryColor.withValues(alpha: settings.opacity * 0.25)
      ..maskFilter = glow;
    canvas.drawCircle(center, maxRadius * (0.35 + amp * 0.5), fillPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.barWidth * 0.4
      ..color = settings.primaryColor.withValues(alpha: settings.opacity)
      ..maskFilter = glow;
    canvas.drawCircle(center, maxRadius * (0.5 + amp * 0.45), ringPaint);

    final bands = data.bands;
    final bandSample = bands.isEmpty
        ? 0.0
        : bands
                  .take((bands.length / 3).ceil().clamp(1, bands.length))
                  .reduce((a, b) => a + b) /
              (bands.length / 3).ceil().clamp(1, bands.length);
    final secondaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.barWidth * 0.25
      ..color = settings.secondaryColor.withValues(
        alpha: settings.opacity * 0.8,
      );
    canvas.drawCircle(
      center,
      maxRadius * (0.7 + bandSample * settings.sensitivity * 0.25),
      secondaryPaint,
    );
  }
}
