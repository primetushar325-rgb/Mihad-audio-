import 'dart:math' as math;
import 'dart:ui';

import '../models/audio_analysis_data.dart';
import '../models/visualizer_settings.dart';

/// One audio-analysis snapshot passed to a visualizer painter. Values are
/// already normalized to 0.0-1.0 by [AudioAnalysisService]/[AudioAnalysisData]
/// and are always derived from decoded real audio, never from random motion.
class VisualizerFrameData {
  final double amplitude;
  final double envelope;
  final double impact;
  final List<double> bands;
  final List<double> waveformSamples;
  final List<double> peakBands;
  final List<double> peakWaveformSamples;

  const VisualizerFrameData({
    required this.amplitude,
    this.envelope = 0,
    this.impact = 0,
    required this.bands,
    this.waveformSamples = const [],
    this.peakBands = const [],
    this.peakWaveformSamples = const [],
  });

  static const empty = VisualizerFrameData(amplitude: 0, bands: []);
}

VisualizerFrameData visualizerFrameFromAnalysis(
  AudioAnalysisData analysis,
  double positionMs,
  VisualizerSettings settings,
) {
  final amplitude = analysis.amplitudeAt(positionMs);
  return VisualizerFrameData(
    amplitude: amplitude,
    envelope: analysis.envelopeAt(
      positionMs,
      attack: settings.attack,
      release: settings.release,
    ),
    impact: analysis.impactAt(
      positionMs,
      sensitivity: settings.impactSensitivity,
    ),
    bands: analysis.bandsAt(positionMs),
    waveformSamples: analysis.waveformAt(positionMs),
    peakBands: analysis.peakBandsAt(positionMs),
    peakWaveformSamples: analysis.peakWaveformAt(positionMs),
  );
}

/// Base contract every built-in visualizer template implements. Templates
/// draw into the bounding box `Offset.zero & size` (the caller positions
/// and clips this box according to [VisualizerSettings]); they must only
/// use [data] and [settings] to decide what to draw - no static images,
/// no audio-independent looping animation.
abstract class VisualizerPainterDelegate {
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  );
}

/// Paints the premium overlay box shared by preview and export. This is
/// intentionally outside [VisualizerCanvasPainter] so ExportService can
/// render exactly the same rounded rectangle, background, border and
/// clipped delegate into a small transparent overlay image instead of a
/// full output frame.
void paintVisualizerOverlayBox({
  required Canvas canvas,
  required Size size,
  required VisualizerFrameData data,
  required VisualizerSettings settings,
  required VisualizerPainterDelegate delegate,
}) {
  if (size.width <= 0 || size.height <= 0) return;

  final rect = Offset.zero & size;
  final shortest = math.min(size.width, size.height).toDouble();
  final radius = Radius.circular(
    shortest * 0.5 * settings.cornerRadius.clamp(0.0, 1.0).toDouble(),
  );
  final rrect = RRect.fromRectAndRadius(rect, radius);

  if (settings.backgroundOpacity > 0.001) {
    final backgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = settings.backgroundColor.withValues(
        alpha: settings.backgroundOpacity.clamp(0.0, 1.0).toDouble(),
      );
    canvas.drawRRect(rrect, backgroundPaint);
  }

  if (settings.waveOpacity > 0.001) {
    canvas.save();
    canvas.clipRRect(rrect);
    delegate.paint(canvas, size, data, settings);
    canvas.restore();
  }

  if (settings.borderEnabled &&
      settings.borderWidth > 0 &&
      settings.borderOpacity > 0.001) {
    final inset = settings.borderWidth / 2;
    final safeInset = inset.clamp(0.0, shortest / 3).toDouble();
    final borderRect = rect.deflate(safeInset);
    final borderRadius = Radius.circular(
      math
          .max(0.0, radius.x - inset.clamp(0.0, radius.x).toDouble())
          .toDouble(),
    );
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.borderWidth
      ..color = settings.borderColor.withValues(
        alpha: settings.borderOpacity.clamp(0.0, 1.0).toDouble(),
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(borderRect, borderRadius),
      borderPaint,
    );
  }
}

/// Small helpers shared by multiple templates.
mixin VisualizerPaintHelpers {
  Paint glowPaint(Color color, double opacity, double glowIntensity) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0).toDouble())
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (glowIntensity > 0.01) {
      paint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        2 + glowIntensity.clamp(0.0, 1.0).toDouble() * 14,
      );
    }
    return paint;
  }

  List<double> resample(List<double> input, int targetCount) {
    if (targetCount <= 0) return const [];
    if (input.isEmpty) return List<double>.filled(targetCount, 0.0);
    if (input.length == targetCount) return List<double>.from(input);
    if (targetCount == 1) return [input.first];
    final output = List<double>.filled(targetCount, 0.0);
    for (var i = 0; i < targetCount; i++) {
      final srcPos = i * (input.length - 1) / (targetCount - 1);
      final lower = srcPos.floor().clamp(0, input.length - 1).toInt();
      final upper = srcPos.ceil().clamp(0, input.length - 1).toInt();
      final t = srcPos - lower;
      output[i] = input[lower] * (1 - t) + input[upper] * t;
    }
    return output;
  }

  double scaledThickness(
    VisualizerSettings settings,
    Size size, [
    double scale = 1,
  ]) {
    final referenceScale = math.min(size.width, size.height).toDouble() / 260.0;
    return (settings.barWidth * referenceScale * scale)
        .clamp(0.75, 80.0)
        .toDouble();
  }

  Color colorAt(
    VisualizerSettings settings,
    double t, {
    double alphaMultiplier = 1,
    bool rainbow = false,
    int salt = 0,
  }) {
    final clampedT = t.clamp(0.0, 1.0).toDouble();
    Color base;
    if (rainbow) {
      base = _hsvToColor((clampedT * 360 + salt * 19) % 360, 0.82, 1.0);
    } else {
      switch (settings.colorMode) {
        case VisualizerColorMode.single:
          base = settings.primaryColor;
          break;
        case VisualizerColorMode.gradient:
          base = Color.lerp(
            settings.primaryColor,
            settings.secondaryColor,
            clampedT,
          )!;
          break;
        case VisualizerColorMode.rainbow:
          base = _hsvToColor((clampedT * 330 + salt * 17) % 360, 0.82, 1.0);
          break;
        case VisualizerColorMode.random:
          final random = _randomColor(settings, clampedT, salt);
          final gradient = Color.lerp(
            settings.primaryColor,
            settings.secondaryColor,
            clampedT,
          )!;
          base = Color.lerp(random, gradient, 0.42)!;
          break;
      }
    }
    return base.withValues(
      alpha: (settings.waveOpacity * alphaMultiplier)
          .clamp(0.0, 1.0)
          .toDouble(),
    );
  }

  Shader waveShader(
    VisualizerSettings settings,
    Rect rect, {
    bool rainbow = false,
    int salt = 0,
  }) {
    if (rainbow || settings.colorMode == VisualizerColorMode.rainbow) {
      return Gradient.linear(
        rect.centerLeft,
        rect.centerRight,
        [
          colorAt(settings, 0.00, rainbow: true, salt: salt),
          colorAt(settings, 0.18, rainbow: true, salt: salt),
          colorAt(settings, 0.36, rainbow: true, salt: salt),
          colorAt(settings, 0.54, rainbow: true, salt: salt),
          colorAt(settings, 0.72, rainbow: true, salt: salt),
          colorAt(settings, 1.00, rainbow: true, salt: salt),
        ],
        [0.0, 0.18, 0.36, 0.54, 0.72, 1.0],
      );
    }
    switch (settings.colorMode) {
      case VisualizerColorMode.single:
        return Gradient.linear(rect.centerLeft, rect.centerRight, [
          colorAt(settings, 0),
          colorAt(settings, 0),
        ]);
      case VisualizerColorMode.gradient:
      case VisualizerColorMode.rainbow:
      case VisualizerColorMode.random:
        return Gradient.linear(
          rect.centerLeft,
          rect.centerRight,
          [
            colorAt(settings, 0, salt: salt),
            colorAt(settings, 0.5, salt: salt),
            colorAt(settings, 1, salt: salt),
          ],
          [0.0, 0.5, 1.0],
        );
    }
  }

  Paint fillPaint(
    VisualizerSettings settings,
    Rect rect, {
    double alphaMultiplier = 1,
    bool rainbow = false,
    int salt = 0,
  }) {
    return Paint()
      ..style = PaintingStyle.fill
      ..shader = waveShader(settings, rect, rainbow: rainbow, salt: salt)
      ..color = colorAt(
        settings,
        0.5,
        alphaMultiplier: alphaMultiplier,
        rainbow: rainbow,
        salt: salt,
      );
  }

  Paint strokePaint(
    VisualizerSettings settings,
    Rect rect, {
    required double strokeWidth,
    double alphaMultiplier = 1,
    bool rainbow = false,
    int salt = 0,
    bool glow = false,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = waveShader(settings, rect, rainbow: rainbow, salt: salt)
      ..color = colorAt(
        settings,
        0.5,
        alphaMultiplier: alphaMultiplier,
        rainbow: rainbow,
        salt: salt,
      );
    if (glow && settings.glowIntensity > 0.01) {
      paint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        2 + settings.glowIntensity.clamp(0.0, 1.0).toDouble() * 22,
      );
    }
    return paint;
  }

  double bandAverage(List<double> bands, int start, int end) {
    if (bands.isEmpty) return 0;
    final safeStart = start.clamp(0, bands.length - 1).toInt();
    final safeEnd = end.clamp(safeStart + 1, bands.length).toInt();
    var sum = 0.0;
    for (var i = safeStart; i < safeEnd; i++) {
      sum += bands[i];
    }
    return sum / (safeEnd - safeStart);
  }

  Color _randomColor(VisualizerSettings settings, double t, int salt) {
    var seed = settings.primaryColorValue ^
        (settings.secondaryColorValue << 7) ^
        ((t * 1009).round() << 3) ^
        (salt * 7919);
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    final hue = (seed % 360).toDouble();
    final sat = 0.68 + ((seed >> 9) % 24) / 100;
    final val = 0.82 + ((seed >> 17) % 18) / 100;
    return _hsvToColor(
      hue,
      sat.clamp(0.0, 1.0).toDouble(),
      val.clamp(0.0, 1.0).toDouble(),
    );
  }

  Color _hsvToColor(double hue, double saturation, double value) {
    final h = ((hue % 360) + 360) % 360;
    final c = value * saturation;
    final x = c * (1 - ((h / 60) % 2 - 1).abs());
    final m = value - c;
    double r = 0, g = 0, b = 0;
    if (h < 60) {
      r = c;
      g = x;
    } else if (h < 120) {
      r = x;
      g = c;
    } else if (h < 180) {
      g = c;
      b = x;
    } else if (h < 240) {
      g = x;
      b = c;
    } else if (h < 300) {
      r = x;
      b = c;
    } else {
      r = c;
      b = x;
    }
    return Color.fromARGB(
      255,
      ((r + m) * 255).round().clamp(0, 255).toInt(),
      ((g + m) * 255).round().clamp(0, 255).toInt(),
      ((b + m) * 255).round().clamp(0, 255).toInt(),
    );
  }
}
