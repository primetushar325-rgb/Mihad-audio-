import 'dart:ui';

import '../../models/visualizer_settings.dart';
import '../visualizer_painter_base.dart';

/// Bars that extend both above and below a center line - a "butterfly"
/// style equalizer.
class MirrorBarsPainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    const barCount = 28;
    final values = resample(data.bands, barCount);
    final spacing = size.width / barCount;
    final barWidth = (spacing * 0.55).clamp(2.0, spacing);
    final midY = size.height / 2;

    final glow = settings.glowIntensity > 0.01
        ? MaskFilter.blur(BlurStyle.normal, 1 + settings.glowIntensity * 10)
        : null;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < barCount; i++) {
      final t = barCount <= 1 ? 0.0 : i / (barCount - 1);
      final color = Color.lerp(
        settings.primaryColor,
        settings.secondaryColor,
        t,
      )!;
      final value = (values[i] * settings.sensitivity).clamp(0.0, 1.3);
      final halfHeight = (midY * value).clamp(1.5, midY);
      final x = i * spacing + (spacing - barWidth) / 2;
      final rect = Rect.fromLTWH(
        x,
        midY - halfHeight,
        barWidth,
        halfHeight * 2,
      );
      paint
        ..color = color.withValues(alpha: settings.opacity)
        ..maskFilter = glow;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth * 0.3)),
        paint,
      );
    }
  }
}
