import 'dart:math' as math;
import 'dart:ui';

import '../../models/visualizer_settings.dart';
import '../visualizer_painter_base.dart';

enum PremiumWaveShape {
  smooth,
  thick,
  thin,
  double,
  triple,
  mirror,
  filled,
  neon,
  glow,
  pulse,
  frequency,
  rainbow,
  cinematic,
  voice,
  jagged,
}

class PremiumWavePainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  final PremiumWaveShape shape;
  final int sampleCount;

  PremiumWavePainter({required this.shape, this.sampleCount = 56});

  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    if (shape == PremiumWaveShape.voice) {
      _paintVoice(canvas, size, data, settings);
      return;
    }

    final count = switch (shape) {
      PremiumWaveShape.frequency => sampleCount < 96 ? 96 : sampleCount,
      PremiumWaveShape.cinematic => sampleCount < 72 ? 72 : sampleCount,
      PremiumWaveShape.jagged => sampleCount < 64 ? 64 : sampleCount,
      _ => sampleCount,
    };
    final samples = resample(data.bands, count);
    final amp = (data.amplitude * settings.sensitivity)
        .clamp(0.0, 1.6)
        .toDouble();
    final rect = Offset.zero & size;
    final lanes = switch (shape) {
      PremiumWaveShape.double => 2,
      PremiumWaveShape.triple => 3,
      _ => 1,
    };
    final mirror = shape == PremiumWaveShape.mirror;
    final filled = shape == PremiumWaveShape.filled;
    final rainbow = shape == PremiumWaveShape.rainbow;
    final cinematic = shape == PremiumWaveShape.cinematic;
    final jagged = shape == PremiumWaveShape.jagged;
    final pulse = shape == PremiumWaveShape.pulse;
    final neon = shape == PremiumWaveShape.neon ||
        shape == PremiumWaveShape.glow ||
        shape == PremiumWaveShape.cinematic;

    if (cinematic) {
      final beam = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = scaledThickness(settings, size, 0.18)
        ..color = colorAt(settings, 0.5, alphaMultiplier: 0.24)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          8 + settings.glowIntensity * 30,
        );
      canvas.drawLine(
        Offset(size.width * 0.04, size.height / 2),
        Offset(size.width * 0.96, size.height / 2),
        beam,
      );
    }

    for (var lane = 0; lane < lanes; lane++) {
      final laneCenter = size.height * (lane + 1) / (lanes + 1);
      final laneHeight = size.height / (lanes + 1);
      final path = _buildWavePath(
        samples: samples,
        size: size,
        centerY: lanes == 1 ? size.height / 2 : laneCenter,
        availableHeight: lanes == 1 ? size.height * 0.46 : laneHeight * 0.38,
        amp: amp,
        settings: settings,
        mirrorSign: lane.isEven ? 1 : -1,
        jagged: jagged,
      );

      if (filled) {
        final fillPath = Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(
          fillPath,
          fillPaint(settings, rect, alphaMultiplier: 0.42),
        );
      }

      if (mirror) {
        final top = _buildWavePath(
          samples: samples,
          size: size,
          centerY: size.height / 2,
          availableHeight: size.height * 0.42,
          amp: amp,
          settings: settings,
          mirrorSign: 1,
          jagged: false,
        );
        final bottom = _buildWavePath(
          samples: samples,
          size: size,
          centerY: size.height / 2,
          availableHeight: size.height * 0.42,
          amp: amp,
          settings: settings,
          mirrorSign: -1,
          jagged: false,
        );
        _drawPremiumPath(
          canvas,
          top,
          rect,
          settings,
          strokeScale: 0.62,
          glow: true,
        );
        _drawPremiumPath(
          canvas,
          bottom,
          rect,
          settings,
          strokeScale: 0.62,
          glow: true,
          salt: 3,
        );
        _drawCenterLine(canvas, size, settings);
        return;
      }

      final strokeScale = switch (shape) {
        PremiumWaveShape.thick => 1.25,
        PremiumWaveShape.thin => 0.28,
        PremiumWaveShape.glow => 0.72,
        PremiumWaveShape.neon => 0.58,
        PremiumWaveShape.pulse => 0.52 + amp * 0.45,
        PremiumWaveShape.frequency => 0.36,
        PremiumWaveShape.cinematic => 0.72,
        PremiumWaveShape.jagged => 0.48,
        _ => 0.55,
      };

      _drawPremiumPath(
        canvas,
        path,
        rect,
        settings,
        strokeScale: pulse ? strokeScale * (0.85 + amp * 0.35) : strokeScale,
        glow: neon || settings.glowIntensity > 0.03,
        rainbow: rainbow,
        salt: lane,
      );

      if (shape == PremiumWaveShape.double || shape == PremiumWaveShape.triple) {
        _drawCenterLine(
          canvas,
          Size(size.width, laneCenter * 2),
          settings,
          yOverride: laneCenter,
          alpha: 0.12,
        );
      }
    }
  }

  Path _buildWavePath({
    required List<double> samples,
    required Size size,
    required double centerY,
    required double availableHeight,
    required double amp,
    required VisualizerSettings settings,
    required int mirrorSign,
    required bool jagged,
  }) {
    final path = Path();
    if (samples.isEmpty) {
      path.moveTo(0, centerY);
      path.lineTo(size.width, centerY);
      return path;
    }

    for (var i = 0; i < samples.length; i++) {
      final t = samples.length == 1 ? 0.0 : i / (samples.length - 1);
      final x = size.width * t;
      final band = (samples[i] * settings.sensitivity)
          .clamp(0.0, 1.45)
          .toDouble();
      final harmonic = math.sin(t * math.pi * 2) * 0.10 * amp;
      final alternating = jagged ? (i.isEven ? 1.0 : -0.82) : 1.0;
      final direction = jagged ? alternating : math.sin(t * math.pi * 2 + band);
      final shaped = jagged
          ? band * alternating
          : (band * 0.72 + direction * band * 0.22 + harmonic);
      final y = centerY -
          mirrorSign *
              shaped *
              availableHeight *
              (0.45 + amp * 0.55).clamp(0.35, 1.35).toDouble();
      if (i == 0) {
        path.moveTo(x, y);
      } else if (jagged) {
        path.lineTo(x, y);
      } else {
        final prevX = size.width * (i - 1) / (samples.length - 1);
        final midX = (prevX + x) / 2;
        path.quadraticBezierTo(midX, y, x, y);
      }
    }
    return path;
  }

  void _drawPremiumPath(
    Canvas canvas,
    Path path,
    Rect rect,
    VisualizerSettings settings, {
    required double strokeScale,
    bool glow = false,
    bool rainbow = false,
    int salt = 0,
  }) {
    final stroke = scaledThickness(settings, rect.size, strokeScale);
    if (glow && settings.glowIntensity > 0.001) {
      canvas.drawPath(
        path,
        strokePaint(
          settings,
          rect,
          strokeWidth: stroke * (2.4 + settings.glowIntensity * 2.2),
          alphaMultiplier: 0.34,
          rainbow: rainbow,
          salt: salt,
          glow: true,
        ),
      );
    }
    canvas.drawPath(
      path,
      strokePaint(
        settings,
        rect,
        strokeWidth: stroke,
        alphaMultiplier: 1,
        rainbow: rainbow,
        salt: salt,
      ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = (stroke * 0.28).clamp(0.7, 8.0).toDouble()
        ..color = const Color(0xFFFFFFFF).withValues(
          alpha: (settings.waveOpacity * 0.26).clamp(0.0, 1.0).toDouble(),
        ),
    );
  }

  void _drawCenterLine(
    Canvas canvas,
    Size size,
    VisualizerSettings settings, {
    double? yOverride,
    double alpha = 0.18,
  }) {
    final y = yOverride ?? size.height / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colorAt(settings, 0.5, alphaMultiplier: alpha);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  void _paintVoice(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    // Voice Wave is the one intentional waveform-line template. It uses
    // real time-domain samples from the analyzer, but remains optional and
    // is never the default story/horror visualizer.
    final samples = resample(
      data.waveformSamples.isNotEmpty ? data.waveformSamples : data.bands,
      72,
    );
    final amp = (data.amplitude * settings.sensitivity)
        .clamp(0.0, 1.35)
        .toDouble();
    final rect = Offset.zero & size;
    final midY = size.height / 2;
    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final t = samples.length <= 1 ? 0.0 : i / (samples.length - 1);
      final x = size.width * t;
      final value = (samples[i] * settings.sensitivity)
          .clamp(0.0, 1.25)
          .toDouble();
      final sign = i.isEven ? 1.0 : -1.0;
      final y = midY - sign * value * size.height * 0.38 * (0.35 + amp * 0.65);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = size.width * (i - 1) / (samples.length - 1);
        final cx = (prevX + x) / 2;
        path.quadraticBezierTo(cx, y, x, y);
      }
    }
    if (settings.glowIntensity > 0.02) {
      canvas.drawPath(
        path,
        strokePaint(
          settings,
          rect,
          strokeWidth: scaledThickness(settings, size, 0.80),
          alphaMultiplier: 0.35,
          glow: true,
        ),
      );
    }
    canvas.drawPath(
      path,
      strokePaint(
        settings,
        rect,
        strokeWidth: scaledThickness(settings, size, 0.34),
      ),
    );
    final center = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colorAt(settings, 0.5, alphaMultiplier: 0.22);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), center);
  }
}


enum PremiumSpectrumStyle {
  story,
  horror,
  cinematic,
  spectrum,
  rainbow,
  classic,
  thin,
  rounded,
  neon,
  bass,
  minimal,
  impact,
  dense,
  mirrored,
  bottom,
  top,
}

enum PremiumSpectrumSource { waveform, spectrum, cinematic }

/// Professional fixed-baseline equalizer renderer.
///
/// It draws many independent, extremely thin vertical sticks on a single
/// Flutter Canvas. In the default (non-mirrored) mode every bar has the same
/// fixed bottom baseline and only the top Y changes from real audio data.
/// This replaces the old connected zigzag/wire waveform as the primary MIHAD
/// AUDIO story/horror/music visualizer.
class PremiumSpectrumPainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  final PremiumSpectrumStyle style;
  final PremiumSpectrumSource source;
  final int? barCount;
  final double widthFactor;

  PremiumSpectrumPainter({
    this.style = PremiumSpectrumStyle.spectrum,
    this.source = PremiumSpectrumSource.spectrum,
    this.barCount,
    this.widthFactor = 0.28,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final denseCount = _effectiveBarCount(size, settings);
    final rawValues = _sourceValues(data, denseCount);
    final values = _smoothValues(rawValues, settings.smoothing);
    if (values.isEmpty) return;

    final rect = Offset.zero & size;
    final rainbow = style == PremiumSpectrumStyle.rainbow ||
        settings.colorMode == VisualizerColorMode.rainbow;
    final forcedMirror = style == PremiumSpectrumStyle.mirrored;
    final mirrored = forcedMirror || settings.mirrored;
    final topAnchored = style == PremiumSpectrumStyle.top;
    final baselinePadding = math.max(1.0, size.height * 0.055).toDouble();
    final topPadding = math.max(1.0, size.height * 0.055).toDouble();
    final baseline = mirrored
        ? size.height / 2
        : (topAnchored ? topPadding : size.height - baselinePadding);
    final availableHeight = mirrored
        ? size.height * 0.44 * settings.waveHeight
        : (size.height - topPadding - baselinePadding) * settings.waveHeight;
    final maxHeight = math.max(1.0, availableHeight).toDouble();
    final spacing = size.width / denseCount;
    final thinLimit = spacing * 0.58;
    final styleWidthFactor = switch (style) {
      PremiumSpectrumStyle.classic => 0.46,
      PremiumSpectrumStyle.rounded => 0.42,
      PremiumSpectrumStyle.neon => 0.34,
      PremiumSpectrumStyle.cinematic => 0.30,
      PremiumSpectrumStyle.horror => 0.20,
      PremiumSpectrumStyle.thin => 0.18,
      PremiumSpectrumStyle.minimal => 0.16,
      PremiumSpectrumStyle.bass => 0.36,
      PremiumSpectrumStyle.impact => 0.24,
      PremiumSpectrumStyle.top => 0.26,
      _ => widthFactor,
    };
    final strokeWidth = math.min(
      settings.barWidth.clamp(0.8, 5.0).toDouble(),
      math.max(1.0, thinLimit * styleWidthFactor / 0.28).toDouble(),
    ).clamp(0.8, math.max(0.9, spacing * 0.55)).toDouble();

    final envelope = (data.envelope == 0 ? data.amplitude : data.envelope)
        .clamp(0.0, 1.0)
        .toDouble();
    final impact = data.impact.clamp(0.0, 1.0).toDouble();
    final bass = bandAverage(data.bands, 0, (data.bands.length / 4).ceil());
    final mids = bandAverage(
      data.bands,
      (data.bands.length * 0.25).floor(),
      (data.bands.length * 0.70).ceil(),
    );
    final highs = bandAverage(
      data.bands,
      (data.bands.length * 0.70).floor(),
      data.bands.length,
    );

    if (style == PremiumSpectrumStyle.cinematic) {
      _paintCinematicUnderGlow(canvas, size, settings, baseline, rainbow);
    }

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < denseCount; i++) {
      final t = denseCount <= 1 ? 0.0 : i / (denseCount - 1);
      final value = values[i];
      final height = _barHeight(
        t: t,
        value: value,
        envelope: envelope,
        impact: impact,
        bass: bass,
        mids: mids,
        highs: highs,
        maxHeight: maxHeight,
        settings: settings,
      );
      final x = i * spacing + spacing / 2;
      final color = _templateColor(settings, t, rainbow: rainbow, salt: i);

      if (settings.glowIntensity > 0.01 &&
          style != PremiumSpectrumStyle.minimal) {
        final glowWidth = (strokeWidth * (2.6 + settings.glowIntensity * 2.2))
            .clamp(strokeWidth + 0.8, spacing * 1.35)
            .toDouble();
        glowPaint
          ..strokeWidth = glowWidth
          ..color = color.withValues(
            alpha: (settings.waveOpacity *
                    (0.14 + settings.glowIntensity * 0.24))
                .clamp(0.0, 0.42)
                .toDouble(),
          )
          ..shader = null
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            0.8 + settings.glowIntensity * 5.5,
          );
        _drawAnchoredStick(
          canvas,
          x,
          baseline,
          height,
          mirrored,
          topAnchored,
          glowPaint,
        );
      }

      corePaint
        ..strokeWidth = strokeWidth
        ..color = color
        ..shader = _barShader(rect, settings, t, rainbow: rainbow, salt: i)
        ..maskFilter = null;
      _drawAnchoredStick(
        canvas,
        x,
        baseline,
        height,
        mirrored,
        topAnchored,
        corePaint,
      );

      if (style == PremiumSpectrumStyle.neon ||
          style == PremiumSpectrumStyle.cinematic ||
          style == PremiumSpectrumStyle.horror) {
        highlightPaint
          ..strokeWidth = (strokeWidth * 0.34).clamp(0.55, 1.2).toDouble()
          ..color = const Color(0xFFFFFFFF).withValues(
            alpha: (settings.waveOpacity * 0.20).clamp(0.0, 1.0).toDouble(),
          )
          ..shader = null
          ..maskFilter = null;
        _drawAnchoredStick(
          canvas,
          x,
          baseline,
          height * 0.82,
          mirrored,
          topAnchored,
          highlightPaint,
        );
      }
    }

    if (settings.centerLineEnabled) {
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _templateColor(
          settings,
          0.5,
          alphaMultiplier: mirrored ? 0.22 : 0.18,
          rainbow: rainbow,
        );
      canvas.drawLine(
        Offset(size.width * 0.03, baseline),
        Offset(size.width * 0.97, baseline),
        line,
      );
    }
  }

  int _effectiveBarCount(Size size, VisualizerSettings settings) {
    final requested = barCount ?? settings.barCount;
    final densityTarget = switch (settings.density) {
      VisualizerDensity.low => 56,
      VisualizerDensity.medium => 72,
      VisualizerDensity.high => 96,
      VisualizerDensity.ultra => 132,
    };
    final styleMinimum = switch (style) {
      PremiumSpectrumStyle.thin => 96,
      PremiumSpectrumStyle.minimal => 64,
      PremiumSpectrumStyle.classic => 56,
      PremiumSpectrumStyle.bass => 64,
      PremiumSpectrumStyle.horror => 88,
      PremiumSpectrumStyle.story => 88,
      PremiumSpectrumStyle.cinematic => 96,
      PremiumSpectrumStyle.rainbow => 100,
      _ => 72,
    };
    final mobileMax = size.width < 720 ? 100 : 180;
    final desired = math.max(requested, math.max(densityTarget, styleMinimum));
    return desired.clamp(36, mobileMax).toInt();
  }

  List<double> _sourceValues(VisualizerFrameData data, int count) {
    switch (source) {
      case PremiumSpectrumSource.waveform:
        final sourceValues = data.waveformSamples.isNotEmpty
            ? data.waveformSamples
            : (data.bands.isNotEmpty ? data.bands : const <double>[]);
        return resample(sourceValues, count);
      case PremiumSpectrumSource.spectrum:
        return resample(data.bands, count);
      case PremiumSpectrumSource.cinematic:
        final wave = resample(
          data.waveformSamples.isNotEmpty ? data.waveformSamples : data.bands,
          count,
        );
        final spectrum = resample(data.bands, count);
        return List<double>.generate(count, (i) {
          final w = i < wave.length ? wave[i] : 0.0;
          final s = i < spectrum.length ? spectrum[i] : 0.0;
          return (w * 0.68 + s * 0.32).clamp(0.0, 1.0).toDouble();
        });
    }
  }

  double _barHeight({
    required double t,
    required double value,
    required double envelope,
    required double impact,
    required double bass,
    required double mids,
    required double highs,
    required double maxHeight,
    required VisualizerSettings settings,
  }) {
    final bassWeight = math.pow(1 - t, 1.45).toDouble();
    final midWeight = (1 - (t - 0.52).abs() * 2.15).clamp(0.0, 1.0).toDouble();
    final highWeight = math.pow(t, 1.18).toDouble();
    final spectrumBlend = (bass * bassWeight * 0.32 +
            mids * midWeight * 0.20 +
            highs * highWeight * 0.14)
        .clamp(0.0, 1.0)
        .toDouble();

    final sourceBoost = switch (source) {
      PremiumSpectrumSource.waveform => value * (0.92 + envelope * 0.35),
      PremiumSpectrumSource.spectrum => value * 0.92 + spectrumBlend * 0.55,
      PremiumSpectrumSource.cinematic => value * 0.78 + spectrumBlend * 0.42,
    };
    final styleBoost = switch (style) {
      PremiumSpectrumStyle.horror => 1.10,
      PremiumSpectrumStyle.impact => 1.18,
      PremiumSpectrumStyle.bass => 0.70 + bassWeight * 0.70,
      PremiumSpectrumStyle.minimal => 0.62,
      PremiumSpectrumStyle.classic => 0.88,
      PremiumSpectrumStyle.cinematic => 0.90,
      _ => 1.0,
    };
    final impactCenter = switch (style) {
      PremiumSpectrumStyle.horror => 0.42,
      PremiumSpectrumStyle.impact => 0.50,
      PremiumSpectrumStyle.bass => 0.20,
      _ => 0.38,
    };
    final impactWidth = style == PremiumSpectrumStyle.horror ? 0.22 : 0.30;
    final impactShape = math.exp(
      -math.pow((t - impactCenter) / impactWidth, 2).toDouble(),
    );
    final impactScale = switch (style) {
      PremiumSpectrumStyle.horror => 1.45,
      PremiumSpectrumStyle.impact => 1.60,
      PremiumSpectrumStyle.cinematic => 0.78,
      _ => 0.90,
    };
    final impactBoost =
        impact * settings.impactSensitivity * impactShape * impactScale;

    final sensitivity = settings.sensitivity.clamp(0.05, 10.0).toDouble();
    final driven = (sourceBoost * styleBoost * sensitivity +
            envelope * 0.08 +
            impactBoost)
        .clamp(0.0, 1.85)
        .toDouble();
    final curve = switch (style) {
      PremiumSpectrumStyle.horror => 0.58,
      PremiumSpectrumStyle.impact => 0.54,
      PremiumSpectrumStyle.minimal => 0.86,
      PremiumSpectrumStyle.classic => 0.74,
      _ => 0.68,
    };
    final shaped = math.pow(driven, curve)
        .toDouble()
        .clamp(0.0, 1.0)
        .toDouble();
    final silenceFloor = switch (style) {
      PremiumSpectrumStyle.minimal => 0.010,
      PremiumSpectrumStyle.thin => 0.012,
      PremiumSpectrumStyle.horror => 0.014,
      _ => 0.018,
    };
    final floor = maxHeight * silenceFloor;
    return (floor + shaped * (maxHeight - floor))
        .clamp(1.0, maxHeight)
        .toDouble();
  }

  void _drawAnchoredStick(
    Canvas canvas,
    double x,
    double baseline,
    double height,
    bool mirrored,
    bool topAnchored,
    Paint paint,
  ) {
    if (mirrored) {
      canvas.drawLine(
        Offset(x, baseline - height),
        Offset(x, baseline + height),
        paint,
      );
    } else if (topAnchored) {
      canvas.drawLine(Offset(x, baseline), Offset(x, baseline + height), paint);
    } else {
      canvas.drawLine(Offset(x, baseline - height), Offset(x, baseline), paint);
    }
  }

  Shader? _barShader(
    Rect rect,
    VisualizerSettings settings,
    double t, {
    required bool rainbow,
    int salt = 0,
  }) {
    if (settings.colorMode == VisualizerColorMode.single && !rainbow) {
      return null;
    }
    return Gradient.linear(
      rect.bottomCenter,
      rect.topCenter,
      [
        _templateColor(
          settings,
          t,
          alphaMultiplier: 0.70,
          rainbow: rainbow,
          salt: salt,
        ),
        _templateColor(settings, 1 - t, rainbow: rainbow, salt: salt),
      ],
    );
  }

  Color _templateColor(
    VisualizerSettings settings,
    double t, {
    double alphaMultiplier = 1,
    bool rainbow = false,
    int salt = 0,
  }) {
    if (style == PremiumSpectrumStyle.horror &&
        settings.colorMode == VisualizerColorMode.gradient &&
        settings.primaryColorValue == 0xFF17D7FF &&
        settings.secondaryColorValue == 0xFF8B5CF6) {
      final crimson = const Color(0xFFE11D48);
      final purple = const Color(0xFF3B0764);
      return Color.lerp(crimson, purple, t.clamp(0.0, 1.0).toDouble())!
          .withValues(
        alpha: (settings.waveOpacity * alphaMultiplier)
            .clamp(0.0, 1.0)
            .toDouble(),
      );
    }
    return colorAt(
      settings,
      t,
      alphaMultiplier: alphaMultiplier,
      rainbow: rainbow,
      salt: salt,
    );
  }

  void _paintCinematicUnderGlow(
    Canvas canvas,
    Size size,
    VisualizerSettings settings,
    double baseline,
    bool rainbow,
  ) {
    final beam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _templateColor(
        settings,
        0.5,
        alphaMultiplier: 0.20,
        rainbow: rainbow,
      )
      ..maskFilter = settings.glowIntensity > 0.05
          ? MaskFilter.blur(BlurStyle.normal, 3 + settings.glowIntensity * 10)
          : null;
    canvas.drawLine(
      Offset(size.width * 0.04, baseline),
      Offset(size.width * 0.96, baseline),
      beam,
    );
  }

  List<double> _smoothValues(List<double> input, double smoothing) {
    if (input.length < 3) return input;
    final radius = (smoothing.clamp(0.0, 1.0) * 4).round();
    if (radius <= 0) return input;
    final output = List<double>.filled(input.length, 0.0);
    for (var i = 0; i < input.length; i++) {
      var sum = 0.0;
      var weight = 0.0;
      for (var j = i - radius; j <= i + radius; j++) {
        if (j < 0 || j >= input.length) continue;
        final w = (radius + 1 - (i - j).abs()).toDouble();
        sum += input[j] * w;
        weight += w;
      }
      output[i] = weight == 0 ? input[i] : sum / weight;
    }
    return output;
  }
}

enum PremiumBarsAnchor { bottom, top, center, mirror, floating, vertical }

class PremiumBarsPainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  final int barCount;
  final double widthFactor;
  final PremiumBarsAnchor anchor;
  final bool rounded;
  final bool spectrumCaps;
  final bool rainbow;

  PremiumBarsPainter({
    this.barCount = 32,
    this.widthFactor = 0.58,
    this.anchor = PremiumBarsAnchor.bottom,
    this.rounded = true,
    this.spectrumCaps = false,
    this.rainbow = false,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    if (anchor == PremiumBarsAnchor.vertical) {
      _paintVertical(canvas, size, data, settings);
      return;
    }

    final values = resample(data.bands, barCount);
    final spacing = size.width / values.length;
    final barW = math.max(1.4, spacing * widthFactor).toDouble();
    final maxH = size.height * 0.88;
    final rect = Offset.zero & size;
    final glow = settings.glowIntensity > 0.01
        ? MaskFilter.blur(BlurStyle.normal, 1 + settings.glowIntensity * 12)
        : null;
    final fill = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < values.length; i++) {
      final t = values.length <= 1 ? 0.0 : i / (values.length - 1);
      final value = (values[i] * settings.sensitivity)
          .clamp(0.0, 1.35)
          .toDouble();
      final ampLift = (0.20 + data.amplitude * settings.sensitivity * 0.25)
          .clamp(0.0, 0.42)
          .toDouble();
      final h = (size.height * ampLift + maxH * value)
          .clamp(2.0, size.height)
          .toDouble();
      final x = i * spacing + (spacing - barW) / 2;
      final barRect = switch (anchor) {
        PremiumBarsAnchor.top => Rect.fromLTWH(x, 0, barW, h),
        PremiumBarsAnchor.center => Rect.fromLTWH(x, size.height / 2 - h / 2, barW, h),
        PremiumBarsAnchor.mirror => Rect.fromLTWH(x, size.height / 2 - h / 2, barW, h),
        PremiumBarsAnchor.floating => Rect.fromLTWH(
            x,
            (size.height / 2 - h / 2) +
                (value - data.amplitude).clamp(-1.0, 1.0).toDouble() *
                size.height *
                0.12,
            barW,
            h,
          ),
        _ => Rect.fromLTWH(x, size.height - h, barW, h),
      };

      fill
        ..shader = rainbow
            ? waveShader(settings, rect, rainbow: true, salt: i)
            : (settings.colorMode == VisualizerColorMode.single
                ? null
                : Gradient.linear(barRect.bottomCenter, barRect.topCenter, [
                    colorAt(settings, t, alphaMultiplier: 0.62, salt: i),
                    colorAt(settings, 1 - t, salt: i),
                  ]))
        ..color = colorAt(settings, t, rainbow: rainbow, salt: i)
        ..maskFilter = glow;
      final radius = rounded ? Radius.circular(barW * 0.55) : Radius.zero;
      canvas.drawRRect(RRect.fromRectAndRadius(barRect, radius), fill);

      if (spectrumCaps) {
        final capY = anchor == PremiumBarsAnchor.top ? barRect.bottom : barRect.top;
        final capPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, barW * 0.18).toDouble()
          ..strokeCap = StrokeCap.round
          ..color = colorAt(settings, t, alphaMultiplier: 0.9, salt: i);
        canvas.drawLine(
          Offset(x, capY),
          Offset(x + barW, capY),
          capPaint,
        );
      }
    }

    if (anchor == PremiumBarsAnchor.center || anchor == PremiumBarsAnchor.mirror) {
      final line = Paint()
        ..strokeWidth = 1
        ..color = colorAt(settings, 0.5, alphaMultiplier: 0.22);
      canvas.drawLine(
        Offset(size.width * 0.04, size.height / 2),
        Offset(size.width * 0.96, size.height / 2),
        line,
      );
    }
  }

  void _paintVertical(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final values = resample(data.bands, barCount.clamp(12, 42).toInt());
    final spacing = size.height / values.length;
    final rowH = math.max(2.0, spacing * widthFactor).toDouble();
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < values.length; i++) {
      final t = i / (values.length - 1);
      final value = (values[i] * settings.sensitivity)
          .clamp(0.0, 1.3)
          .toDouble();
      final w = (size.width * (0.08 + value * 0.9))
          .clamp(2.0, size.width)
          .toDouble();
      final y = size.height - (i + 1) * spacing + (spacing - rowH) / 2;
      final r = Rect.fromLTWH(0, y, w, rowH);
      paint
        ..shader = settings.colorMode == VisualizerColorMode.single
            ? null
            : Gradient.linear(r.centerLeft, r.centerRight, [
                colorAt(settings, 0, salt: i),
                colorAt(settings, t, salt: i),
              ])
        ..color = colorAt(settings, t, salt: i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(rowH * 0.45)),
        paint,
      );
    }
  }
}

enum PremiumCircleShape {
  spectrum,
  radial,
  doubleRing,
  pulseRing,
  dotRing,
  audioRing,
  dotSpectrum,
  pulseCircle,
}

class PremiumCirclePainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  final PremiumCircleShape shape;
  final int count;

  PremiumCirclePainter({required this.shape, this.count = 72});

  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    switch (shape) {
      case PremiumCircleShape.dotSpectrum:
        _paintDotSpectrum(canvas, size, data, settings);
        return;
      case PremiumCircleShape.pulseCircle:
        _paintPulseCircle(canvas, size, data, settings);
        return;
      case PremiumCircleShape.doubleRing:
        _paintDoubleRing(canvas, size, data, settings);
        return;
      case PremiumCircleShape.pulseRing:
        _paintPulseRing(canvas, size, data, settings);
        return;
      case PremiumCircleShape.dotRing:
        _paintDotRing(canvas, size, data, settings);
        return;
      case PremiumCircleShape.audioRing:
        _paintAudioRing(canvas, size, data, settings);
        return;
      case PremiumCircleShape.spectrum:
      case PremiumCircleShape.radial:
        _paintRadialBars(canvas, size, data, settings);
        return;
    }
  }

  void _paintRadialBars(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final values = resample(data.bands, shape == PremiumCircleShape.radial ? 96 : count);
    final center = Offset(size.width / 2, size.height / 2);
    final minSide = math.min(size.width, size.height).toDouble();
    final amp = (data.amplitude * settings.sensitivity)
        .clamp(0.0, 1.4)
        .toDouble();
    final base = minSide * (shape == PremiumCircleShape.radial ? 0.22 : 0.18) *
        (1 + amp * 0.14);
    final maxLen = minSide * (shape == PremiumCircleShape.radial ? 0.28 : 0.24);
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = scaledThickness(settings, size, 0.28);
    if (settings.glowIntensity > 0.01) {
      paint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        1 + settings.glowIntensity * 10,
      );
    }
    for (var i = 0; i < values.length; i++) {
      final t = i / values.length;
      final angle = math.pi * 2 * t - math.pi / 2;
      final value = (values[i] * settings.sensitivity)
          .clamp(0.0, 1.35)
          .toDouble();
      final inner = Offset(center.dx + base * math.cos(angle), center.dy + base * math.sin(angle));
      final outerRadius = base + maxLen * (0.08 + value * 0.92);
      final outer = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      paint
        ..shader = waveShader(settings, rect, rainbow: shape == PremiumCircleShape.radial, salt: i)
        ..color = colorAt(settings, t, rainbow: shape == PremiumCircleShape.radial, salt: i);
      canvas.drawLine(inner, outer, paint);
    }
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = scaledThickness(settings, size, 0.18)
      ..color = colorAt(settings, 0.5, alphaMultiplier: 0.5);
    canvas.drawCircle(center, base, ring);
  }

  void _paintDoubleRing(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final minSide = math.min(size.width, size.height).toDouble();
    final bass = bandAverage(data.bands, 0, (data.bands.length / 3).ceil());
    final treble = bandAverage(data.bands, (data.bands.length / 2).floor(), data.bands.length);
    final rect = Offset.zero & size;
    for (final ring in [
      (radius: 0.25 + bass * 0.12, width: 0.34, t: 0.1),
      (radius: 0.38 + treble * 0.10, width: 0.20, t: 0.9),
    ]) {
      final paint = strokePaint(
        settings,
        rect,
        strokeWidth: scaledThickness(settings, size, ring.width),
        alphaMultiplier: 0.85,
        salt: (ring.t * 10).round(),
        glow: true,
      );
      paint.color = colorAt(settings, ring.t, alphaMultiplier: 0.85);
      canvas.drawCircle(center, minSide * ring.radius, paint);
    }
  }

  void _paintPulseRing(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final minSide = math.min(size.width, size.height).toDouble();
    final amp = (data.amplitude * settings.sensitivity)
        .clamp(0.0, 1.4)
        .toDouble();
    final rect = Offset.zero & size;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = scaledThickness(settings, size, 1.1)
      ..color = colorAt(settings, 0.5, alphaMultiplier: 0.20)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + settings.glowIntensity * 26);
    canvas.drawCircle(center, minSide * (0.25 + amp * 0.18), glow);
    final ring = strokePaint(
      settings,
      rect,
      strokeWidth: scaledThickness(settings, size, 0.38 + amp * 0.2),
      glow: true,
    );
    canvas.drawCircle(center, minSide * (0.28 + amp * 0.16), ring);
  }

  void _paintDotRing(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final values = resample(data.bands, count.clamp(32, 96).toInt());
    final center = Offset(size.width / 2, size.height / 2);
    final minSide = math.min(size.width, size.height).toDouble();
    final base = minSide * 0.28;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < values.length; i++) {
      final t = i / values.length;
      final angle = math.pi * 2 * t - math.pi / 2;
      final value = (values[i] * settings.sensitivity)
          .clamp(0.0, 1.35)
          .toDouble();
      final radius = base + minSide * 0.10 * value;
      final p = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      paint.color = colorAt(settings, t, salt: i);
      if (settings.glowIntensity > 0.01) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + settings.glowIntensity * 8);
      }
      canvas.drawCircle(p, scaledThickness(settings, size, 0.28) * (0.7 + value * 0.9), paint);
    }
  }

  void _paintAudioRing(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    _paintPulseRing(canvas, size, data, settings);
    _paintRadialBars(canvas, size, data, settings);
    final center = Offset(size.width / 2, size.height / 2);
    final dot = Paint()
      ..style = PaintingStyle.fill
      ..color = colorAt(settings, 0.5, alphaMultiplier: 0.85);
    canvas.drawCircle(center, math.min(size.width, size.height).toDouble() * 0.065, dot);
  }

  void _paintDotSpectrum(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final values = resample(data.bands, 28);
    final spacing = size.width / values.length;
    final baseRadius = scaledThickness(settings, size, 0.38)
        .clamp(1.5, spacing / 2)
        .toDouble();
    final paint = Paint()..style = PaintingStyle.fill;
    final stem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < values.length; i++) {
      final t = i / (values.length - 1);
      final value = (values[i] * settings.sensitivity)
          .clamp(0.0, 1.25)
          .toDouble();
      final x = spacing * i + spacing / 2;
      final y = size.height - value * (size.height - baseRadius * 2) - baseRadius;
      stem.color = colorAt(settings, t, alphaMultiplier: 0.25, salt: i);
      canvas.drawLine(Offset(x, size.height), Offset(x, y), stem);
      paint.color = colorAt(settings, t, salt: i);
      if (settings.glowIntensity > 0.01) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + settings.glowIntensity * 8);
      }
      canvas.drawCircle(Offset(x, y), baseRadius * (0.7 + value * 0.8), paint);
    }
  }

  void _paintPulseCircle(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final minSide = math.min(size.width, size.height).toDouble();
    final amp = (data.amplitude * settings.sensitivity)
        .clamp(0.0, 1.4)
        .toDouble();
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = colorAt(settings, 0.2, alphaMultiplier: 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + settings.glowIntensity * 18);
    canvas.drawCircle(center, minSide * (0.18 + amp * 0.22), fill);
    final stroke = strokePaint(
      settings,
      Offset.zero & size,
      strokeWidth: scaledThickness(settings, size, 0.36),
      glow: true,
    );
    canvas.drawCircle(center, minSide * (0.24 + amp * 0.20), stroke);
  }
}

enum PremiumStoryShape {
  minimal,
  dark,
  horror,
  cinematicGlow,
  podcast,
  story,
  centerPulse,
  bassPulse,
}

class PremiumStoryPainter extends VisualizerPainterDelegate
    with VisualizerPaintHelpers {
  final PremiumStoryShape shape;

  PremiumStoryPainter(this.shape);

  @override
  void paint(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    switch (shape) {
      case PremiumStoryShape.minimal:
        _minimal(canvas, size, data, settings);
        break;
      case PremiumStoryShape.dark:
        _dark(canvas, size, data, settings);
        break;
      case PremiumStoryShape.horror:
        PremiumWavePainter(shape: PremiumWaveShape.jagged).paint(canvas, size, data, settings);
        break;
      case PremiumStoryShape.cinematicGlow:
        _cinematicGlow(canvas, size, data, settings);
        break;
      case PremiumStoryShape.podcast:
        _podcast(canvas, size, data, settings);
        break;
      case PremiumStoryShape.story:
        _story(canvas, size, data, settings);
        break;
      case PremiumStoryShape.centerPulse:
        _centerPulse(canvas, size, data, settings);
        break;
      case PremiumStoryShape.bassPulse:
        _bassPulse(canvas, size, data, settings);
        break;
    }
  }

  void _minimal(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colorAt(settings, 0.5, alphaMultiplier: 0.20);
    canvas.drawLine(Offset(size.width * 0.06, size.height / 2), Offset(size.width * 0.94, size.height / 2), line);
    PremiumWavePainter(shape: PremiumWaveShape.thin, sampleCount: 48).paint(canvas, size, data, settings);
  }

  void _dark(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final vignette = Paint()
      ..style = PaintingStyle.fill
      ..shader = Gradient.radial(
        Offset(size.width / 2, size.height / 2),
        math.max(size.width, size.height).toDouble() * 0.65,
        [
          const Color(0x00000000),
          const Color(0xAA000000),
        ],
      );
    canvas.drawRect(Offset.zero & size, vignette);
    PremiumWavePainter(shape: PremiumWaveShape.glow, sampleCount: 64).paint(canvas, size, data, settings);
  }

  void _cinematicGlow(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final amp = (data.amplitude * settings.sensitivity)
        .clamp(0.0, 1.4)
        .toDouble();
    final center = Offset(size.width / 2, size.height / 2);
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..color = colorAt(settings, 0.5, alphaMultiplier: 0.16)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + settings.glowIntensity * 36);
    canvas.drawCircle(center, math.min(size.width, size.height).toDouble() * (0.14 + amp * 0.18), glow);
    PremiumWavePainter(shape: PremiumWaveShape.cinematic, sampleCount: 72).paint(canvas, size, data, settings);
  }

  void _podcast(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    PremiumBarsPainter(
      barCount: 44,
      widthFactor: 0.36,
      anchor: PremiumBarsAnchor.center,
      rounded: true,
    ).paint(canvas, size, data, settings);
    final badge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = scaledThickness(settings, size, 0.22)
      ..color = colorAt(settings, 0.5, alphaMultiplier: 0.55);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), math.min(size.width, size.height).toDouble() * 0.12, badge);
  }

  void _story(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    PremiumBarsPainter(
      barCount: 38,
      widthFactor: 0.52,
      anchor: PremiumBarsAnchor.bottom,
      rounded: true,
    ).paint(canvas, size, data, settings);
    final topLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colorAt(settings, 0.5, alphaMultiplier: 0.16);
    canvas.drawLine(Offset(size.width * 0.08, size.height * 0.18), Offset(size.width * 0.92, size.height * 0.18), topLine);
  }

  void _centerPulse(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final amp = (data.amplitude * settings.sensitivity)
        .clamp(0.0, 1.4)
        .toDouble();
    final center = Offset(size.width / 2, size.height / 2);
    final rays = resample(data.bands, 18);
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = scaledThickness(settings, size, 0.22);
    for (var i = 0; i < rays.length; i++) {
      final t = i / rays.length;
      final angle = math.pi * 2 * t;
      final len = math.min(size.width, size.height).toDouble() * (0.12 + rays[i] * settings.sensitivity * 0.25);
      rayPaint.color = colorAt(settings, t, alphaMultiplier: 0.72, salt: i);
      canvas.drawLine(
        center,
        Offset(center.dx + len * math.cos(angle), center.dy + len * math.sin(angle)),
        rayPaint,
      );
    }
    final pulse = Paint()
      ..style = PaintingStyle.fill
      ..color = colorAt(settings, 0.5, alphaMultiplier: 0.32)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + settings.glowIntensity * 20);
    canvas.drawCircle(center, math.min(size.width, size.height).toDouble() * (0.08 + amp * 0.10), pulse);
  }

  void _bassPulse(
    Canvas canvas,
    Size size,
    VisualizerFrameData data,
    VisualizerSettings settings,
  ) {
    final bass = bandAverage(data.bands, 0, (data.bands.length / 4).ceil());
    final values = resample(data.bands, 16);
    final spacing = size.width / values.length;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < values.length; i++) {
      final t = i / (values.length - 1);
      final value = ((values[i] * 0.45 + bass * 0.9) * settings.sensitivity)
          .clamp(0.0, 1.45)
          .toDouble();
      final w = spacing * 0.72;
      final h = (size.height * (0.12 + value * 0.76))
          .clamp(2.0, size.height)
          .toDouble();
      final x = i * spacing + (spacing - w) / 2;
      final rect = Rect.fromLTWH(x, size.height / 2 - h / 2, w, h);
      paint
        ..shader = Gradient.linear(rect.bottomCenter, rect.topCenter, [
          colorAt(settings, 0.0, alphaMultiplier: 0.52),
          colorAt(settings, t, salt: i),
        ])
        ..color = colorAt(settings, t, salt: i)
        ..maskFilter = settings.glowIntensity > 0.01
            ? MaskFilter.blur(BlurStyle.normal, 2 + settings.glowIntensity * 16)
            : null;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.22)), paint);
    }
  }
}
