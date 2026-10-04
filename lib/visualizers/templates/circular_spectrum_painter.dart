import 'dart:math' as math;
import 'dart:ui';

import '../../models/visualizer_settings.dart';
import '../visualizer_painter_base.dart';

/// Frequency bars radiating outward from a central circle - one bar per
/// band, arranged around 360 degrees.
class CircularSpectrumPainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    const barCount = 48;
    final values = resample(data.bands, barCount);
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius =
        math.min(size.width, size.height) *
        0.22 *
        (1 + data.amplitude * 0.15 * settings.sensitivity);
    final maxLen = math.min(size.width, size.height) * 0.3;

    final glow = settings.glowIntensity > 0.01
        ? MaskFilter.blur(BlurStyle.normal, 1 + settings.glowIntensity * 10)
        : null;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = settings.barWidth * 0.5;

    for (var i = 0; i < barCount; i++) {
      final angle = 2 * math.pi * i / barCount;
      final value = (values[i] * settings.sensitivity).clamp(0.0, 1.3);
      final len = maxLen * value;
      final inner = Offset(
        center.dx + baseRadius * math.cos(angle),
        center.dy + baseRadius * math.sin(angle),
      );
      final outer = Offset(
        center.dx + (baseRadius + len) * math.cos(angle),
        center.dy + (baseRadius + len) * math.sin(angle),
      );
      final t = i / barCount;
      paint
        ..color = Color.lerp(
          settings.primaryColor,
          settings.secondaryColor,
          t,
        )!.withValues(alpha: settings.opacity)
        ..maskFilter = glow;
      canvas.drawLine(inner, outer, paint);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = settings.primaryColor.withValues(alpha: settings.opacity * 0.5);
    canvas.drawCircle(center, baseRadius, ringPaint);
  }
}
