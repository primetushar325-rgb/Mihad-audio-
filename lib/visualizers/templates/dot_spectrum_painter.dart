import 'dart:ui';

import '../../models/visualizer_settings.dart';
import '../visualizer_painter_base.dart';

/// A row of dots, one per frequency band, each rising and falling with
/// that band's energy.
class DotSpectrumPainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    const dotCount = 20;
    final values = resample(data.bands, dotCount);
    final spacing = size.width / dotCount;
    final baseRadius = (settings.barWidth * 0.5).clamp(2.0, spacing / 2);

    final glow = settings.glowIntensity > 0.01
        ? MaskFilter.blur(BlurStyle.normal, 1 + settings.glowIntensity * 8)
        : null;
    final paint = Paint()..style = PaintingStyle.fill;
    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < dotCount; i++) {
      final t = dotCount <= 1 ? 0.0 : i / (dotCount - 1);
      final color = Color.lerp(
        settings.primaryColor,
        settings.secondaryColor,
        t,
      )!;
      final value = (values[i] * settings.sensitivity).clamp(0.0, 1.3);
      final x = spacing * i + spacing / 2;
      final y =
          size.height - value * (size.height - baseRadius * 2) - baseRadius;

      stemPaint.color = color.withValues(alpha: settings.opacity * 0.35);
      canvas.drawLine(Offset(x, size.height), Offset(x, y), stemPaint);

      paint
        ..color = color.withValues(alpha: settings.opacity)
        ..maskFilter = glow;
      canvas.drawCircle(Offset(x, y), baseRadius * (0.7 + value * 0.6), paint);
    }
  }
}
