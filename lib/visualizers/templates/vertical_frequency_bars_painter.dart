import 'dart:ui';

import '../../models/visualizer_settings.dart';
import '../visualizer_painter_base.dart';

/// Frequency bars arranged in a vertical column, growing rightward from
/// the left edge - a 90-degree rotated take on the classic equalizer.
class VerticalFrequencyBarsPainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    const rowCount = 18;
    final values = resample(data.bands, rowCount);
    final spacing = size.height / rowCount;
    final rowHeight = (spacing * 0.6).clamp(2.0, spacing);

    final glow = settings.glowIntensity > 0.01
        ? MaskFilter.blur(BlurStyle.normal, 1 + settings.glowIntensity * 10)
        : null;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < rowCount; i++) {
      final t = rowCount <= 1 ? 0.0 : i / (rowCount - 1);
      final color = Color.lerp(
        settings.primaryColor,
        settings.secondaryColor,
        t,
      )!;
      final value = (values[i] * settings.sensitivity).clamp(0.0, 1.3);
      final barLength = (size.width * value).clamp(2.0, size.width);
      // Highest frequencies at the top.
      final y = size.height - (i + 1) * spacing + (spacing - rowHeight) / 2;
      final rect = Rect.fromLTWH(0, y, barLength, rowHeight);
      paint
        ..color = color.withValues(alpha: settings.opacity)
        ..maskFilter = glow;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rowHeight * 0.3)),
        paint,
      );
    }
  }
}
