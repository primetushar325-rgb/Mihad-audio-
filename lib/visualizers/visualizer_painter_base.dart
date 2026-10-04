import 'dart:ui';

import '../models/visualizer_settings.dart';

/// One audio-analysis snapshot passed to a visualizer painter: overall
/// amplitude plus per-band frequency energies, both already normalized to
/// 0.0-1.0 by [AudioAnalysisService].
class VisualizerFrameData {
  final double amplitude;
  final List<double> bands;

  const VisualizerFrameData({required this.amplitude, required this.bands});

  static const empty = VisualizerFrameData(amplitude: 0, bands: []);
}

/// Base contract every built-in visualizer template implements. Templates
/// draw into the bounding box `Offset.zero & size` (the caller positions
/// and clips this box according to [VisualizerSettings]); they must only
/// use [data] and [settings] to decide what to draw - no static images,
/// no audio-independent looping animation (spec section 6).
abstract class VisualizerPainterDelegate {
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  );
}

/// Small helpers shared by multiple templates.
mixin VisualizerPaintHelpers {
  Paint glowPaint(Color color, double opacity, double glowIntensity) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke;
    if (glowIntensity > 0.01) {
      paint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        2 + glowIntensity * 14,
      );
    }
    return paint;
  }

  List<double> resample(List<double> input, int targetCount) {
    if (input.isEmpty) return List<double>.filled(targetCount, 0.0);
    if (input.length == targetCount) return input;
    final output = List<double>.filled(targetCount, 0.0);
    for (var i = 0; i < targetCount; i++) {
      final srcPos =
          i * (input.length - 1) / (targetCount - 1).clamp(1, 1 << 30);
      final lower = srcPos.floor().clamp(0, input.length - 1);
      final upper = srcPos.ceil().clamp(0, input.length - 1);
      final t = srcPos - lower;
      output[i] = input[lower] * (1 - t) + input[upper] * t;
    }
    return output;
  }
}
