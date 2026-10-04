import 'dart:math' as math;
import 'dart:ui';

/// Subtitle/caption timeline and motion-text data. Everything is stored as
/// plain JSON so projects stay offline/free and export can burn the same data
/// shown in preview. Values intentionally use normalized positions/sizes so
/// preview and final render match different aspect ratios.

enum SubtitleTextAlign { left, center, right }

enum SubtitleVerticalPosition { top, upper, center, lower, bottom, custom }

enum SubtitleAnimationType {
  none,
  fade,
  pop,
  zoom,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  typewriter,
  wordPop,
  characterPop,
  bounce,
  elastic,
  blur,
  glow,
  slowZoom,
  shake,
  heartbeat,
  flicker,
}

enum SubtitleLoopAnimation { none, pulse, breathing, glowPulse, floating, shake, heartbeat, neonFlicker }

enum SubtitleHighlightMode { none, color, glow, scale, bounce, pop, underline, background, gradient }

enum SubtitleBackgroundType { none, solid, rounded, pill, transparentBox, gradient, outline }

enum SubtitleGlowQuality { low, medium, high }

enum SubtitlePerformanceQuality { low, medium, high }

class SubtitleWordTiming {
  final String word;
  final double startMs;
  final double endMs;

  const SubtitleWordTiming({
    required this.word,
    required this.startMs,
    required this.endMs,
  });

  SubtitleWordTiming copyWith({String? word, double? startMs, double? endMs}) {
    return SubtitleWordTiming(
      word: word ?? this.word,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'startMs': startMs,
        'endMs': endMs,
      };

  factory SubtitleWordTiming.fromJson(Map<String, dynamic> json) {
    return SubtitleWordTiming(
      word: json['word']?.toString() ?? '',
      startMs: _double(json['startMs'], 0),
      endMs: _double(json['endMs'], 0),
    );
  }
}

class SubtitleGlowLayer {
  final bool enabled;
  final int colorValue;
  final double intensity;
  final double radius;
  final double spread;
  final double opacity;

  const SubtitleGlowLayer({
    this.enabled = true,
    this.colorValue = 0xFFFFFFFF,
    this.intensity = 0.35,
    this.radius = 0.35,
    this.spread = 0.25,
    this.opacity = 0.55,
  });

  Color get color => Color(colorValue);

  SubtitleGlowLayer copyWith({
    bool? enabled,
    int? colorValue,
    double? intensity,
    double? radius,
    double? spread,
    double? opacity,
  }) {
    return SubtitleGlowLayer(
      enabled: enabled ?? this.enabled,
      colorValue: colorValue ?? this.colorValue,
      intensity: intensity ?? this.intensity,
      radius: radius ?? this.radius,
      spread: spread ?? this.spread,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'colorValue': colorValue,
        'intensity': intensity,
        'radius': radius,
        'spread': spread,
        'opacity': opacity,
      };

  factory SubtitleGlowLayer.fromJson(Map<String, dynamic> json) {
    return SubtitleGlowLayer(
      enabled: json['enabled'] as bool? ?? true,
      colorValue: _int(json['colorValue'], 0xFFFFFFFF),
      intensity: _double(json['intensity'], 0.35).clamp(0.0, 1.0).toDouble(),
      radius: _double(json['radius'], 0.35).clamp(0.0, 1.0).toDouble(),
      spread: _double(json['spread'], 0.25).clamp(0.0, 1.0).toDouble(),
      opacity: _double(json['opacity'], 0.55).clamp(0.0, 1.0).toDouble(),
    );
  }
}

class SubtitleTextStyleConfig {
  final String templateId;
  final String fontFamily;
  final int fontWeight;
  final double fontSize;
  final double opacity;
  final int colorValue;
  final bool gradientEnabled;
  final int gradientStartValue;
  final int gradientEndValue;
  final double gradientAngle;
  final bool strokeEnabled;
  final int strokeColorValue;
  final double strokeWidth;
  final double strokeOpacity;
  final bool shadowEnabled;
  final int shadowColorValue;
  final double shadowOpacity;
  final double shadowBlur;
  final double shadowDistance;
  final double shadowAngle;
  final bool glowEnabled;
  final int glowColorValue;
  final int glowCoreColorValue;
  final double glowIntensity;
  final double glowRadius;
  final double glowSpread;
  final double glowOpacity;
  final double glowFalloff;
  final SubtitleGlowQuality glowQuality;
  final List<SubtitleGlowLayer> glowLayers;
  final SubtitleBackgroundType backgroundType;
  final int backgroundColorValue;
  final int backgroundSecondaryColorValue;
  final double backgroundOpacity;
  final double backgroundCornerRadius;
  final double backgroundPadding;
  final SubtitleTextAlign alignment;
  final double letterSpacing;
  final double lineSpacing;
  final SubtitleAnimationType inAnimation;
  final SubtitleAnimationType outAnimation;
  final SubtitleLoopAnimation loopAnimation;
  final SubtitleHighlightMode highlightMode;
  final int highlightColorValue;
  final int highlightBackgroundColorValue;
  final double highlightScale;
  final bool highlightGlow;
  final SubtitlePerformanceQuality performanceQuality;

  const SubtitleTextStyleConfig({
    this.templateId = 'story_clean_white',
    this.fontFamily = 'Noto Sans Bengali',
    this.fontWeight = 700,
    this.fontSize = 44,
    this.opacity = 1,
    this.colorValue = 0xFFFFFFFF,
    this.gradientEnabled = false,
    this.gradientStartValue = 0xFFFFFFFF,
    this.gradientEndValue = 0xFFFFD54F,
    this.gradientAngle = 0,
    this.strokeEnabled = true,
    this.strokeColorValue = 0xFF000000,
    this.strokeWidth = 3.5,
    this.strokeOpacity = 0.92,
    this.shadowEnabled = true,
    this.shadowColorValue = 0xFF000000,
    this.shadowOpacity = 0.65,
    this.shadowBlur = 10,
    this.shadowDistance = 4,
    this.shadowAngle = 90,
    this.glowEnabled = true,
    this.glowColorValue = 0x6638BDF8,
    this.glowCoreColorValue = 0xFFFFFFFF,
    this.glowIntensity = 0.22,
    this.glowRadius = 0.20,
    this.glowSpread = 0.15,
    this.glowOpacity = 0.40,
    this.glowFalloff = 0.55,
    this.glowQuality = SubtitleGlowQuality.medium,
    this.glowLayers = const [],
    this.backgroundType = SubtitleBackgroundType.none,
    this.backgroundColorValue = 0xCC000000,
    this.backgroundSecondaryColorValue = 0x66000000,
    this.backgroundOpacity = 0.0,
    this.backgroundCornerRadius = 0.18,
    this.backgroundPadding = 12,
    this.alignment = SubtitleTextAlign.center,
    this.letterSpacing = 0,
    this.lineSpacing = 1.08,
    this.inAnimation = SubtitleAnimationType.fade,
    this.outAnimation = SubtitleAnimationType.fade,
    this.loopAnimation = SubtitleLoopAnimation.none,
    this.highlightMode = SubtitleHighlightMode.color,
    this.highlightColorValue = 0xFFFFD54F,
    this.highlightBackgroundColorValue = 0xAA000000,
    this.highlightScale = 1.08,
    this.highlightGlow = true,
    this.performanceQuality = SubtitlePerformanceQuality.medium,
  });

  Color get color => Color(colorValue);
  Color get strokeColor => Color(strokeColorValue);
  Color get shadowColor => Color(shadowColorValue);
  Color get glowColor => Color(glowColorValue);
  Color get glowCoreColor => Color(glowCoreColorValue);
  Color get backgroundColor => Color(backgroundColorValue);
  Color get backgroundSecondaryColor => Color(backgroundSecondaryColorValue);
  Color get highlightColor => Color(highlightColorValue);
  Color get highlightBackgroundColor => Color(highlightBackgroundColorValue);

  SubtitleTextStyleConfig copyWith({
    String? templateId,
    String? fontFamily,
    int? fontWeight,
    double? fontSize,
    double? opacity,
    int? colorValue,
    bool? gradientEnabled,
    int? gradientStartValue,
    int? gradientEndValue,
    double? gradientAngle,
    bool? strokeEnabled,
    int? strokeColorValue,
    double? strokeWidth,
    double? strokeOpacity,
    bool? shadowEnabled,
    int? shadowColorValue,
    double? shadowOpacity,
    double? shadowBlur,
    double? shadowDistance,
    double? shadowAngle,
    bool? glowEnabled,
    int? glowColorValue,
    int? glowCoreColorValue,
    double? glowIntensity,
    double? glowRadius,
    double? glowSpread,
    double? glowOpacity,
    double? glowFalloff,
    SubtitleGlowQuality? glowQuality,
    List<SubtitleGlowLayer>? glowLayers,
    SubtitleBackgroundType? backgroundType,
    int? backgroundColorValue,
    int? backgroundSecondaryColorValue,
    double? backgroundOpacity,
    double? backgroundCornerRadius,
    double? backgroundPadding,
    SubtitleTextAlign? alignment,
    double? letterSpacing,
    double? lineSpacing,
    SubtitleAnimationType? inAnimation,
    SubtitleAnimationType? outAnimation,
    SubtitleLoopAnimation? loopAnimation,
    SubtitleHighlightMode? highlightMode,
    int? highlightColorValue,
    int? highlightBackgroundColorValue,
    double? highlightScale,
    bool? highlightGlow,
    SubtitlePerformanceQuality? performanceQuality,
  }) {
    return SubtitleTextStyleConfig(
      templateId: templateId ?? this.templateId,
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      colorValue: colorValue ?? this.colorValue,
      gradientEnabled: gradientEnabled ?? this.gradientEnabled,
      gradientStartValue: gradientStartValue ?? this.gradientStartValue,
      gradientEndValue: gradientEndValue ?? this.gradientEndValue,
      gradientAngle: gradientAngle ?? this.gradientAngle,
      strokeEnabled: strokeEnabled ?? this.strokeEnabled,
      strokeColorValue: strokeColorValue ?? this.strokeColorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeOpacity: strokeOpacity ?? this.strokeOpacity,
      shadowEnabled: shadowEnabled ?? this.shadowEnabled,
      shadowColorValue: shadowColorValue ?? this.shadowColorValue,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowDistance: shadowDistance ?? this.shadowDistance,
      shadowAngle: shadowAngle ?? this.shadowAngle,
      glowEnabled: glowEnabled ?? this.glowEnabled,
      glowColorValue: glowColorValue ?? this.glowColorValue,
      glowCoreColorValue: glowCoreColorValue ?? this.glowCoreColorValue,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      glowRadius: glowRadius ?? this.glowRadius,
      glowSpread: glowSpread ?? this.glowSpread,
      glowOpacity: glowOpacity ?? this.glowOpacity,
      glowFalloff: glowFalloff ?? this.glowFalloff,
      glowQuality: glowQuality ?? this.glowQuality,
      glowLayers: glowLayers ?? this.glowLayers,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      backgroundSecondaryColorValue: backgroundSecondaryColorValue ?? this.backgroundSecondaryColorValue,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      backgroundCornerRadius: backgroundCornerRadius ?? this.backgroundCornerRadius,
      backgroundPadding: backgroundPadding ?? this.backgroundPadding,
      alignment: alignment ?? this.alignment,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      inAnimation: inAnimation ?? this.inAnimation,
      outAnimation: outAnimation ?? this.outAnimation,
      loopAnimation: loopAnimation ?? this.loopAnimation,
      highlightMode: highlightMode ?? this.highlightMode,
      highlightColorValue: highlightColorValue ?? this.highlightColorValue,
      highlightBackgroundColorValue: highlightBackgroundColorValue ?? this.highlightBackgroundColorValue,
      highlightScale: highlightScale ?? this.highlightScale,
      highlightGlow: highlightGlow ?? this.highlightGlow,
      performanceQuality: performanceQuality ?? this.performanceQuality,
    );
  }

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'fontFamily': fontFamily,
        'fontWeight': fontWeight,
        'fontSize': fontSize,
        'opacity': opacity,
        'colorValue': colorValue,
        'gradientEnabled': gradientEnabled,
        'gradientStartValue': gradientStartValue,
        'gradientEndValue': gradientEndValue,
        'gradientAngle': gradientAngle,
        'strokeEnabled': strokeEnabled,
        'strokeColorValue': strokeColorValue,
        'strokeWidth': strokeWidth,
        'strokeOpacity': strokeOpacity,
        'shadowEnabled': shadowEnabled,
        'shadowColorValue': shadowColorValue,
        'shadowOpacity': shadowOpacity,
        'shadowBlur': shadowBlur,
        'shadowDistance': shadowDistance,
        'shadowAngle': shadowAngle,
        'glowEnabled': glowEnabled,
        'glowColorValue': glowColorValue,
        'glowCoreColorValue': glowCoreColorValue,
        'glowIntensity': glowIntensity,
        'glowRadius': glowRadius,
        'glowSpread': glowSpread,
        'glowOpacity': glowOpacity,
        'glowFalloff': glowFalloff,
        'glowQuality': glowQuality.name,
        'glowLayers': glowLayers.map((e) => e.toJson()).toList(),
        'backgroundType': backgroundType.name,
        'backgroundColorValue': backgroundColorValue,
        'backgroundSecondaryColorValue': backgroundSecondaryColorValue,
        'backgroundOpacity': backgroundOpacity,
        'backgroundCornerRadius': backgroundCornerRadius,
        'backgroundPadding': backgroundPadding,
        'alignment': alignment.name,
        'letterSpacing': letterSpacing,
        'lineSpacing': lineSpacing,
        'inAnimation': inAnimation.name,
        'outAnimation': outAnimation.name,
        'loopAnimation': loopAnimation.name,
        'highlightMode': highlightMode.name,
        'highlightColorValue': highlightColorValue,
        'highlightBackgroundColorValue': highlightBackgroundColorValue,
        'highlightScale': highlightScale,
        'highlightGlow': highlightGlow,
        'performanceQuality': performanceQuality.name,
      };

  factory SubtitleTextStyleConfig.fromJson(Map<String, dynamic> json) {
    return SubtitleTextStyleConfig(
      templateId: json['templateId']?.toString() ?? 'story_clean_white',
      fontFamily: json['fontFamily']?.toString() ?? 'Noto Sans Bengali',
      fontWeight: _int(json['fontWeight'], 700).clamp(100, 900).toInt(),
      fontSize: _double(json['fontSize'], 44).clamp(8.0, 160.0).toDouble(),
      opacity: _double(json['opacity'], 1).clamp(0.0, 1.0).toDouble(),
      colorValue: _int(json['colorValue'], 0xFFFFFFFF),
      gradientEnabled: json['gradientEnabled'] as bool? ?? false,
      gradientStartValue: _int(json['gradientStartValue'], 0xFFFFFFFF),
      gradientEndValue: _int(json['gradientEndValue'], 0xFFFFD54F),
      gradientAngle: _double(json['gradientAngle'], 0),
      strokeEnabled: json['strokeEnabled'] as bool? ?? true,
      strokeColorValue: _int(json['strokeColorValue'], 0xFF000000),
      strokeWidth: _double(json['strokeWidth'], 3.5).clamp(0.0, 20.0).toDouble(),
      strokeOpacity: _double(json['strokeOpacity'], 0.92).clamp(0.0, 1.0).toDouble(),
      shadowEnabled: json['shadowEnabled'] as bool? ?? true,
      shadowColorValue: _int(json['shadowColorValue'], 0xFF000000),
      shadowOpacity: _double(json['shadowOpacity'], 0.65).clamp(0.0, 1.0).toDouble(),
      shadowBlur: _double(json['shadowBlur'], 10).clamp(0.0, 80.0).toDouble(),
      shadowDistance: _double(json['shadowDistance'], 4).clamp(0.0, 80.0).toDouble(),
      shadowAngle: _double(json['shadowAngle'], 90),
      glowEnabled: json['glowEnabled'] as bool? ?? true,
      glowColorValue: _int(json['glowColorValue'], 0x6638BDF8),
      glowCoreColorValue: _int(json['glowCoreColorValue'], 0xFFFFFFFF),
      glowIntensity: _double(json['glowIntensity'], 0.22).clamp(0.0, 1.0).toDouble(),
      glowRadius: _double(json['glowRadius'], 0.20).clamp(0.0, 1.0).toDouble(),
      glowSpread: _double(json['glowSpread'], 0.15).clamp(0.0, 1.0).toDouble(),
      glowOpacity: _double(json['glowOpacity'], 0.40).clamp(0.0, 1.0).toDouble(),
      glowFalloff: _double(json['glowFalloff'], 0.55).clamp(0.0, 1.0).toDouble(),
      glowQuality: _enumByName(SubtitleGlowQuality.values, json['glowQuality'], SubtitleGlowQuality.medium),
      glowLayers: (json['glowLayers'] as List?)
              ?.map((e) => SubtitleGlowLayer.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      backgroundType: _enumByName(SubtitleBackgroundType.values, json['backgroundType'], SubtitleBackgroundType.none),
      backgroundColorValue: _int(json['backgroundColorValue'], 0xCC000000),
      backgroundSecondaryColorValue: _int(json['backgroundSecondaryColorValue'], 0x66000000),
      backgroundOpacity: _double(json['backgroundOpacity'], 0.0).clamp(0.0, 1.0).toDouble(),
      backgroundCornerRadius: _double(json['backgroundCornerRadius'], 0.18).clamp(0.0, 1.0).toDouble(),
      backgroundPadding: _double(json['backgroundPadding'], 12).clamp(0.0, 80.0).toDouble(),
      alignment: _enumByName(SubtitleTextAlign.values, json['alignment'], SubtitleTextAlign.center),
      letterSpacing: _double(json['letterSpacing'], 0).clamp(-10.0, 40.0).toDouble(),
      lineSpacing: _double(json['lineSpacing'], 1.08).clamp(0.6, 3.0).toDouble(),
      inAnimation: _enumByName(SubtitleAnimationType.values, json['inAnimation'], SubtitleAnimationType.fade),
      outAnimation: _enumByName(SubtitleAnimationType.values, json['outAnimation'], SubtitleAnimationType.fade),
      loopAnimation: _enumByName(SubtitleLoopAnimation.values, json['loopAnimation'], SubtitleLoopAnimation.none),
      highlightMode: _enumByName(SubtitleHighlightMode.values, json['highlightMode'], SubtitleHighlightMode.color),
      highlightColorValue: _int(json['highlightColorValue'], 0xFFFFD54F),
      highlightBackgroundColorValue: _int(json['highlightBackgroundColorValue'], 0xAA000000),
      highlightScale: _double(json['highlightScale'], 1.08).clamp(0.5, 2.2).toDouble(),
      highlightGlow: json['highlightGlow'] as bool? ?? true,
      performanceQuality: _enumByName(SubtitlePerformanceQuality.values, json['performanceQuality'], SubtitlePerformanceQuality.medium),
    );
  }
}

class SubtitleCue {
  final String id;
  final String layerId;
  final String text;
  final double startMs;
  final double endMs;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final double rotation;
  final double scale;
  final bool locked;
  final bool visible;
  final List<SubtitleWordTiming> words;
  final SubtitleTextStyleConfig style;

  const SubtitleCue({
    required this.id,
    required this.layerId,
    required this.text,
    required this.startMs,
    required this.endMs,
    this.posX = 0.09,
    this.posY = 0.68,
    this.width = 0.82,
    this.height = 0.20,
    this.rotation = 0,
    this.scale = 1,
    this.locked = false,
    this.visible = true,
    this.words = const [],
    this.style = const SubtitleTextStyleConfig(),
  });

  double get durationMs => math.max(1, endMs - startMs).toDouble();
  bool isActiveAt(double positionMs) => visible && positionMs >= startMs && positionMs <= endMs;

  SubtitleCue copyWith({
    String? id,
    String? layerId,
    String? text,
    double? startMs,
    double? endMs,
    double? posX,
    double? posY,
    double? width,
    double? height,
    double? rotation,
    double? scale,
    bool? locked,
    bool? visible,
    List<SubtitleWordTiming>? words,
    SubtitleTextStyleConfig? style,
  }) {
    return SubtitleCue(
      id: id ?? this.id,
      layerId: layerId ?? this.layerId,
      text: text ?? this.text,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      locked: locked ?? this.locked,
      visible: visible ?? this.visible,
      words: words ?? this.words,
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'layerId': layerId,
        'text': text,
        'startMs': startMs,
        'endMs': endMs,
        'posX': posX,
        'posY': posY,
        'width': width,
        'height': height,
        'rotation': rotation,
        'scale': scale,
        'locked': locked,
        'visible': visible,
        'words': words.map((e) => e.toJson()).toList(),
        'style': style.toJson(),
      };

  factory SubtitleCue.fromJson(Map<String, dynamic> json) {
    return SubtitleCue(
      id: json['id']?.toString() ?? _id('cue'),
      layerId: json['layerId']?.toString() ?? 'subtitles',
      text: json['text']?.toString() ?? '',
      startMs: _double(json['startMs'], 0),
      endMs: math.max(_double(json['endMs'], 2000), _double(json['startMs'], 0) + 100).toDouble(),
      posX: _double(json['posX'], 0.09).clamp(0.0, 1.0).toDouble(),
      posY: _double(json['posY'], 0.68).clamp(0.0, 1.0).toDouble(),
      width: _double(json['width'], 0.82).clamp(0.05, 1.0).toDouble(),
      height: _double(json['height'], 0.20).clamp(0.03, 1.0).toDouble(),
      rotation: _double(json['rotation'], 0),
      scale: _double(json['scale'], 1).clamp(0.1, 5.0).toDouble(),
      locked: json['locked'] as bool? ?? false,
      visible: json['visible'] as bool? ?? true,
      words: (json['words'] as List?)
              ?.map((e) => SubtitleWordTiming.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      style: json['style'] is Map
          ? SubtitleTextStyleConfig.fromJson(Map<String, dynamic>.from(json['style'] as Map))
          : const SubtitleTextStyleConfig(),
    );
  }
}

class SubtitleLayer {
  final String id;
  final String name;
  final bool visible;
  final bool locked;
  final List<SubtitleCue> cues;

  const SubtitleLayer({
    required this.id,
    required this.name,
    this.visible = true,
    this.locked = false,
    this.cues = const [],
  });

  SubtitleLayer copyWith({
    String? id,
    String? name,
    bool? visible,
    bool? locked,
    List<SubtitleCue>? cues,
  }) {
    return SubtitleLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      cues: cues ?? this.cues,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'visible': visible,
        'locked': locked,
        'cues': cues.map((e) => e.toJson()).toList(),
      };

  factory SubtitleLayer.fromJson(Map<String, dynamic> json) {
    return SubtitleLayer(
      id: json['id']?.toString() ?? _id('layer'),
      name: json['name']?.toString() ?? 'Subtitles',
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      cues: (json['cues'] as List?)
              ?.map((e) => SubtitleCue.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}

String newSubtitleId(String prefix) => _id(prefix);

String _id(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

double _double(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _int(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? int.tryParse(value.replaceFirst('#', '0xFF')) ?? fallback;
  }
  return fallback;
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  final value = name?.toString();
  for (final item in values) {
    if (item.name == value) return item;
  }
  return fallback;
}
