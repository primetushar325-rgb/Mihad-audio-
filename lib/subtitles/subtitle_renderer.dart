import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/subtitle_models.dart';

class SubtitlePaintResult {
  final Rect rect;
  final SubtitleCue cue;
  const SubtitlePaintResult(this.rect, this.cue);
}

List<SubtitleCue> activeSubtitleCues(
  List<SubtitleLayer> layers,
  double positionMs,
) {
  final active = <SubtitleCue>[];
  for (final layer in layers) {
    if (!layer.visible) continue;
    for (final cue in layer.cues) {
      if (cue.isActiveAt(positionMs)) active.add(cue);
    }
  }
  active.sort((a, b) => a.startMs.compareTo(b.startMs));
  return active;
}

List<SubtitlePaintResult> paintSubtitles({
  required Canvas canvas,
  required Size size,
  required List<SubtitleLayer> layers,
  required double positionMs,
  String? selectedCueId,
  bool showSelection = false,
}) {
  final results = <SubtitlePaintResult>[];
  for (final cue in activeSubtitleCues(layers, positionMs)) {
    final rect = Rect.fromLTWH(
      cue.posX * size.width,
      cue.posY * size.height,
      cue.width * size.width,
      cue.height * size.height,
    );
    _paintCue(canvas, size, rect, cue, positionMs);
    if (showSelection && cue.id == selectedCueId) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF00E5A8).withValues(alpha: 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        paint,
      );
    }
    results.add(SubtitlePaintResult(rect, cue));
  }
  return results;
}

void _paintCue(
  Canvas canvas,
  Size canvasSize,
  Rect rect,
  SubtitleCue cue,
  double positionMs,
) {
  final style = cue.style;
  final localT = ((positionMs - cue.startMs) / cue.durationMs)
      .clamp(0.0, 1.0)
      .toDouble();
  final anim = _animationTransform(style, localT, positionMs);
  final center = rect.center;

  canvas.save();
  canvas.translate(center.dx + anim.offset.dx, center.dy + anim.offset.dy);
  canvas.rotate(cue.rotation * math.pi / 180);
  canvas.scale(cue.scale * anim.scale, cue.scale * anim.scale);
  canvas.translate(-center.dx, -center.dy);

  final animatedOpacity = (style.opacity * anim.opacity).clamp(0.0, 1.0).toDouble();
  if (animatedOpacity <= 0.001) {
    canvas.restore();
    return;
  }

  final paddedRect = rect.deflate(math.min(rect.width, rect.height) * 0.02);
  final textBox = _textBoxForBackground(paddedRect, style);
  _paintBackground(canvas, textBox, style, animatedOpacity);

  final textPainter = _buildTextPainter(
    cue,
    positionMs,
    style,
    rect.width,
    animatedOpacity,
  );
  textPainter.layout(maxWidth: math.max(1, rect.width - style.backgroundPadding * 2));

  final textOffset = _textOffset(rect, textPainter, style);
  if (style.shadowEnabled) {
    _paintTextLayer(
      canvas,
      cue,
      positionMs,
      style,
      rect.width,
      textOffset + _shadowOffset(style),
      animatedOpacity * style.shadowOpacity,
      foreground: Paint()
        ..color = style.shadowColor.withValues(
          alpha: (animatedOpacity * style.shadowOpacity).clamp(0.0, 1.0).toDouble(),
        )
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, style.shadowBlur),
    );
  }

  if (style.glowEnabled && style.glowIntensity > 0.001) {
    _paintGlow(canvas, cue, positionMs, style, rect.width, textOffset, animatedOpacity);
  }

  if (style.strokeEnabled && style.strokeWidth > 0) {
    _paintTextLayer(
      canvas,
      cue,
      positionMs,
      style,
      rect.width,
      textOffset,
      animatedOpacity * style.strokeOpacity,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = style.strokeColor.withValues(
          alpha: (animatedOpacity * style.strokeOpacity).clamp(0.0, 1.0).toDouble(),
        ),
    );
  }

  textPainter.paint(canvas, textOffset);
  _paintUnderlineHighlight(canvas, cue, positionMs, style, rect, textPainter, textOffset, animatedOpacity);

  canvas.restore();
}

Rect _textBoxForBackground(Rect rect, SubtitleTextStyleConfig style) {
  if (style.backgroundType == SubtitleBackgroundType.none || style.backgroundOpacity <= 0) {
    return rect;
  }
  return rect.deflate(style.backgroundPadding * 0.25);
}

void _paintBackground(
  Canvas canvas,
  Rect rect,
  SubtitleTextStyleConfig style,
  double opacity,
) {
  if (style.backgroundType == SubtitleBackgroundType.none || style.backgroundOpacity <= 0.001) {
    return;
  }
  final alpha = (style.backgroundOpacity * opacity).clamp(0.0, 1.0).toDouble();
  final paint = Paint()
    ..style = style.backgroundType == SubtitleBackgroundType.outline
        ? PaintingStyle.stroke
        : PaintingStyle.fill
    ..strokeWidth = 2
    ..color = style.backgroundColor.withValues(alpha: alpha);
  if (style.backgroundType == SubtitleBackgroundType.gradient) {
    paint.shader = ui.Gradient.linear(
      rect.centerLeft,
      rect.centerRight,
      [
        style.backgroundColor.withValues(alpha: alpha),
        style.backgroundSecondaryColor.withValues(alpha: alpha),
      ],
    );
  }
  final radius = switch (style.backgroundType) {
    SubtitleBackgroundType.pill => Radius.circular(rect.height / 2),
    SubtitleBackgroundType.rounded || SubtitleBackgroundType.gradient || SubtitleBackgroundType.transparentBox =>
      Radius.circular(math.min(rect.width, rect.height) * style.backgroundCornerRadius),
    _ => Radius.circular(math.min(rect.width, rect.height) * 0.06),
  };
  canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
}

TextPainter _buildTextPainter(
  SubtitleCue cue,
  double positionMs,
  SubtitleTextStyleConfig style,
  double maxWidth,
  double opacity, {
  Paint? foreground,
}) {
  return TextPainter(
    text: _buildSpan(cue, positionMs, style, opacity, foreground: foreground),
    textDirection: TextDirection.ltr,
    textAlign: switch (style.alignment) {
      SubtitleTextAlign.left => TextAlign.left,
      SubtitleTextAlign.center => TextAlign.center,
      SubtitleTextAlign.right => TextAlign.right,
    },
    maxLines: 3,
    ellipsis: '…',
    strutStyle: StrutStyle(
      fontFamily: style.fontFamily,
      fontSize: style.fontSize,
      height: style.lineSpacing,
      forceStrutHeight: false,
    ),
  )..layout(maxWidth: math.max(1, maxWidth - style.backgroundPadding * 2));
}

TextSpan _buildSpan(
  SubtitleCue cue,
  double positionMs,
  SubtitleTextStyleConfig style,
  double opacity, {
  Paint? foreground,
}) {
  final base = TextStyle(
    fontFamily: style.fontFamily,
    fontSize: style.fontSize,
    height: style.lineSpacing,
    letterSpacing: style.letterSpacing,
    fontWeight: _fontWeight(style.fontWeight),
    color: foreground == null ? style.color.withValues(alpha: opacity) : null,
    foreground: foreground,
  );
  final words = _wordTimings(cue);
  if (words.isEmpty || style.highlightMode == SubtitleHighlightMode.none || foreground != null) {
    return TextSpan(text: cue.text, style: _withGradientIfNeeded(base, style, opacity));
  }
  final activeIndex = words.indexWhere((word) => positionMs >= word.startMs && positionMs <= word.endMs);
  final spans = <InlineSpan>[];
  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    final active = i == activeIndex;
    var wordStyle = _withGradientIfNeeded(base, style, opacity);
    if (active) {
      wordStyle = wordStyle.copyWith(
        color: style.highlightMode == SubtitleHighlightMode.gradient
            ? null
            : style.highlightColor.withValues(alpha: opacity),
        fontSize: style.fontSize * (style.highlightMode == SubtitleHighlightMode.scale || style.highlightMode == SubtitleHighlightMode.pop ? style.highlightScale : 1),
        shadows: style.highlightGlow
            ? [
                Shadow(
                  color: style.highlightColor.withValues(alpha: 0.75 * opacity),
                  blurRadius: style.glowRadius * 30 + 4,
                ),
              ]
            : null,
        backgroundColor: style.highlightMode == SubtitleHighlightMode.background
            ? style.highlightBackgroundColor.withValues(alpha: 0.75 * opacity)
            : null,
      );
    }
    spans.add(TextSpan(text: '${word.word}${i == words.length - 1 ? '' : ' '}', style: wordStyle));
  }
  return TextSpan(children: spans);
}

TextStyle _withGradientIfNeeded(TextStyle base, SubtitleTextStyleConfig style, double opacity) {
  if (!style.gradientEnabled) return base;
  return base.copyWith(
    foreground: Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(250 * math.cos(style.gradientAngle * math.pi / 180), 250 * math.sin(style.gradientAngle * math.pi / 180)),
        [
          Color(style.gradientStartValue).withValues(alpha: opacity),
          Color(style.gradientEndValue).withValues(alpha: opacity),
        ],
      ),
  );
}

void _paintTextLayer(
  Canvas canvas,
  SubtitleCue cue,
  double positionMs,
  SubtitleTextStyleConfig style,
  double maxWidth,
  Offset offset,
  double opacity, {
  required Paint foreground,
}) {
  final painter = _buildTextPainter(
    cue,
    positionMs,
    style,
    maxWidth,
    opacity.clamp(0.0, 1.0).toDouble(),
    foreground: foreground,
  );
  painter.paint(canvas, offset);
}

void _paintGlow(
  Canvas canvas,
  SubtitleCue cue,
  double positionMs,
  SubtitleTextStyleConfig style,
  double maxWidth,
  Offset offset,
  double opacity,
) {
  final qualityPasses = switch (style.performanceQuality) {
    SubtitlePerformanceQuality.low => 1,
    SubtitlePerformanceQuality.medium => style.glowQuality == SubtitleGlowQuality.high ? 2 : 1,
    SubtitlePerformanceQuality.high => switch (style.glowQuality) {
        SubtitleGlowQuality.low => 1,
        SubtitleGlowQuality.medium => 2,
        SubtitleGlowQuality.high => 3,
      },
  };
  final layers = style.glowLayers.isNotEmpty
      ? style.glowLayers.where((layer) => layer.enabled).toList()
      : [
          SubtitleGlowLayer(
            colorValue: style.glowCoreColorValue,
            intensity: style.glowIntensity * 0.65,
            radius: style.glowRadius * 0.55,
            opacity: style.glowOpacity * 0.75,
          ),
          SubtitleGlowLayer(
            colorValue: style.glowColorValue,
            intensity: style.glowIntensity,
            radius: style.glowRadius,
            opacity: style.glowOpacity,
          ),
        ];
  var pass = 0;
  for (final layer in layers) {
    if (pass >= qualityPasses + 1) break;
    final blur = (2 + layer.radius * 32 + layer.spread * 18)
        .clamp(1.0, style.performanceQuality == SubtitlePerformanceQuality.low ? 12.0 : 42.0)
        .toDouble();
    final paint = Paint()
      ..color = layer.color.withValues(
        alpha: (opacity * layer.opacity * (0.45 + layer.intensity)).clamp(0.0, 1.0).toDouble(),
      )
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blur);
    _paintTextLayer(canvas, cue, positionMs, style, maxWidth, offset, opacity, foreground: paint);
    pass++;
  }
}

Offset _textOffset(Rect rect, TextPainter painter, SubtitleTextStyleConfig style) {
  final dx = switch (style.alignment) {
    SubtitleTextAlign.left => rect.left + style.backgroundPadding,
    SubtitleTextAlign.center => rect.left + (rect.width - painter.width) / 2,
    SubtitleTextAlign.right => rect.right - painter.width - style.backgroundPadding,
  };
  final dy = rect.top + (rect.height - painter.height) / 2;
  return Offset(dx, dy);
}

Offset _shadowOffset(SubtitleTextStyleConfig style) {
  final radians = style.shadowAngle * math.pi / 180;
  return Offset(math.cos(radians), math.sin(radians)) * style.shadowDistance;
}

List<SubtitleWordTiming> _wordTimings(SubtitleCue cue) {
  if (cue.words.isNotEmpty) return cue.words;
  final words = cue.text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  final slice = cue.durationMs / words.length;
  return List<SubtitleWordTiming>.generate(words.length, (index) {
    final start = cue.startMs + slice * index;
    return SubtitleWordTiming(
      word: words[index],
      startMs: start,
      endMs: index == words.length - 1 ? cue.endMs : start + slice,
    );
  });
}

void _paintUnderlineHighlight(
  Canvas canvas,
  SubtitleCue cue,
  double positionMs,
  SubtitleTextStyleConfig style,
  Rect rect,
  TextPainter painter,
  Offset textOffset,
  double opacity,
) {
  if (style.highlightMode != SubtitleHighlightMode.underline) return;
  final words = _wordTimings(cue);
  final activeIndex = words.indexWhere((word) => positionMs >= word.startMs && positionMs <= word.endMs);
  if (activeIndex == -1) return;
  final activeWord = words[activeIndex].word;
  final prefix = words.take(activeIndex).map((e) => e.word).join(' ');
  final prefixPainter = TextPainter(
    text: TextSpan(text: prefix.isEmpty ? '' : '$prefix ', style: TextStyle(fontFamily: style.fontFamily, fontSize: style.fontSize, fontWeight: _fontWeight(style.fontWeight))),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: rect.width);
  final wordPainter = TextPainter(
    text: TextSpan(text: activeWord, style: TextStyle(fontFamily: style.fontFamily, fontSize: style.fontSize, fontWeight: _fontWeight(style.fontWeight))),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: rect.width);
  final y = textOffset.dy + painter.height + 2;
  final paint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(2, style.fontSize * 0.07).toDouble()
    ..color = style.highlightColor.withValues(alpha: opacity);
  canvas.drawLine(
    Offset(textOffset.dx + prefixPainter.width, y),
    Offset(textOffset.dx + prefixPainter.width + wordPainter.width, y),
    paint,
  );
}

_FontWeight _fontWeight(int weight) => FontWeight.values[((weight.clamp(100, 900) ~/ 100) - 1).clamp(0, 8)];

typedef _FontWeight = FontWeight;

class _AnimationState {
  final double opacity;
  final double scale;
  final Offset offset;
  const _AnimationState({this.opacity = 1, this.scale = 1, this.offset = Offset.zero});
}

_AnimationState _animationTransform(
  SubtitleTextStyleConfig style,
  double t,
  double positionMs,
) {
  var opacity = 1.0;
  var scale = 1.0;
  var offset = Offset.zero;
  final inT = (t / 0.16).clamp(0.0, 1.0).toDouble();
  final outT = ((1 - t) / 0.12).clamp(0.0, 1.0).toDouble();
  opacity *= _animationOpacity(style.inAnimation, inT);
  opacity *= _animationOpacity(style.outAnimation, outT);
  scale *= _animationScale(style.inAnimation, inT);
  scale *= _animationScale(style.outAnimation, outT);
  offset += _animationOffset(style.inAnimation, inT);
  offset += -_animationOffset(style.outAnimation, outT);

  final phase = positionMs / 1000;
  switch (style.loopAnimation) {
    case SubtitleLoopAnimation.none:
      break;
    case SubtitleLoopAnimation.pulse:
      scale *= 1 + math.sin(phase * math.pi * 2) * 0.025;
      break;
    case SubtitleLoopAnimation.breathing:
      scale *= 1 + math.sin(phase * math.pi) * 0.018;
      break;
    case SubtitleLoopAnimation.glowPulse:
      scale *= 1 + math.sin(phase * math.pi * 2) * 0.012;
      break;
    case SubtitleLoopAnimation.floating:
      offset += Offset(0, math.sin(phase * math.pi * 2) * 2.5);
      break;
    case SubtitleLoopAnimation.shake:
      offset += Offset(math.sin(phase * math.pi * 14) * 1.6, 0);
      break;
    case SubtitleLoopAnimation.heartbeat:
      final beat = math.pow(math.sin(phase * math.pi * 2).abs(), 8).toDouble();
      scale *= 1 + beat * 0.045;
      break;
    case SubtitleLoopAnimation.neonFlicker:
      opacity *= 0.92 + (math.sin(phase * 19.0) > 0.82 ? 0.08 : 0.0);
      break;
  }
  return _AnimationState(opacity: opacity.clamp(0.0, 1.0).toDouble(), scale: scale, offset: offset);
}

double _animationOpacity(SubtitleAnimationType type, double t) {
  switch (type) {
    case SubtitleAnimationType.none:
    case SubtitleAnimationType.pop:
    case SubtitleAnimationType.zoom:
    case SubtitleAnimationType.slideUp:
    case SubtitleAnimationType.slideDown:
    case SubtitleAnimationType.slideLeft:
    case SubtitleAnimationType.slideRight:
    case SubtitleAnimationType.wordPop:
    case SubtitleAnimationType.characterPop:
    case SubtitleAnimationType.bounce:
    case SubtitleAnimationType.elastic:
    case SubtitleAnimationType.slowZoom:
    case SubtitleAnimationType.shake:
    case SubtitleAnimationType.heartbeat:
      return 1;
    case SubtitleAnimationType.fade:
    case SubtitleAnimationType.typewriter:
    case SubtitleAnimationType.blur:
    case SubtitleAnimationType.glow:
    case SubtitleAnimationType.flicker:
      return t;
  }
}

double _animationScale(SubtitleAnimationType type, double t) {
  final eased = Curves.easeOutBack.transform(t);
  switch (type) {
    case SubtitleAnimationType.pop:
    case SubtitleAnimationType.wordPop:
    case SubtitleAnimationType.characterPop:
      return 0.86 + eased * 0.14;
    case SubtitleAnimationType.zoom:
      return 0.72 + Curves.easeOutCubic.transform(t) * 0.28;
    case SubtitleAnimationType.elastic:
    case SubtitleAnimationType.bounce:
      return 0.88 + math.sin(t * math.pi) * 0.08 + t * 0.12;
    case SubtitleAnimationType.slowZoom:
      return 1 + t * 0.03;
    default:
      return 1;
  }
}

Offset _animationOffset(SubtitleAnimationType type, double t) {
  final d = (1 - Curves.easeOutCubic.transform(t)) * 34;
  switch (type) {
    case SubtitleAnimationType.slideUp:
      return Offset(0, d);
    case SubtitleAnimationType.slideDown:
      return Offset(0, -d);
    case SubtitleAnimationType.slideLeft:
      return Offset(d, 0);
    case SubtitleAnimationType.slideRight:
      return Offset(-d, 0);
    default:
      return Offset.zero;
  }
}
