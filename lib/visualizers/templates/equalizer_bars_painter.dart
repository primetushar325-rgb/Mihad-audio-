import 'dart:ui';

import '../../models/visualizer_settings.dart';
import '../visualizer_painter_base.dart';

/// Classic vertical frequency-bar equalizer: one bar per frequency band,
/// bottom-aligned, height proportional to that band's current energy.
class EqualizerBarsPainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    const barCount = 24;
    final values = resample(data.bands, barCount);
    final spacing = size.width / barCount;
    final barWidth = (spacing * 0.6).clamp(2.0, spacing);

    final paint = Paint()..style = PaintingStyle.fill;
    final glow = settings.glowIntensity > 0.01
        ? MaskFilter.blur(BlurStyle.normal, 1 + settings.glowIntensity * 10)
        : null;

    for (var i = 0; i < barCount; i++) {
      final t = barCount <= 1 ? 0.0 : i / (barCount - 1);
      final color = Color.lerp(
        settings.primaryColor,
        settings.secondaryColor,
        t,
      )!;
      final value = (values[i] * settings.sensitivity).clamp(0.0, 1.3);
      final barHeight = (size.height * value).clamp(2.0, size.height);
      final x = i * spacing + (spacing - barWidth) / 2;
      final rect = Rect.fromLTWH(
        x,
        size.height - barHeight,
        barWidth,
        barHeight,
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
