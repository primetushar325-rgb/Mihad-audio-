import 'dart:ui';

import 'visualizer_template.dart';

enum VisualizerAlignment { left, center, right }

enum VisualizerColorMode { single, gradient, rainbow, random }

enum VisualizerDensity { low, medium, high, ultra }

enum ExportAspectRatio { ratio16x9, ratio9x16, ratio1x1, original }

extension ExportAspectRatioX on ExportAspectRatio {
  /// Returns width/height, or null for [ExportAspectRatio.original]
  /// (meaning: use the source video's own aspect ratio).
  double? get value {
    switch (this) {
      case ExportAspectRatio.ratio16x9:
        return 16 / 9;
      case ExportAspectRatio.ratio9x16:
        return 9 / 16;
      case ExportAspectRatio.ratio1x1:
        return 1.0;
      case ExportAspectRatio.original:
        return null;
    }
  }

  String get label {
    switch (this) {
      case ExportAspectRatio.ratio16x9:
        return '16:9';
      case ExportAspectRatio.ratio9x16:
        return '9:16';
      case ExportAspectRatio.ratio1x1:
        return '1:1';
      case ExportAspectRatio.original:
        return 'Original';
    }
  }
}

extension VisualizerDensityX on VisualizerDensity {
  String get label {
    switch (this) {
      case VisualizerDensity.low:
        return 'Low';
      case VisualizerDensity.medium:
        return 'Medium';
      case VisualizerDensity.high:
        return 'High';
      case VisualizerDensity.ultra:
        return 'Ultra';
    }
  }
}

/// All user-adjustable appearance/position settings for a visualizer
/// overlay. Position and size are stored as *fractions* (0.0-1.0) of the
/// canvas, so the exact same settings object can drive both the live
/// preview widget and the final pixel-accurate export renderer.
///
/// The default MIHAD AUDIO visualizer is now a story-friendly equalizer:
/// many thin, independent, fixed-baseline vertical sticks driven by the
/// analyzed audio. Old JSON fields are still accepted so existing projects
/// keep opening.
class VisualizerSettings {
  VisualizerTemplateType template;

  /// Top-left X position of the visualizer bounding box, as a fraction
  /// (0.0 - 1.0) of the canvas width.
  double posX;

  /// Top-left Y position of the visualizer bounding box, as a fraction
  /// (0.0 - 1.0) of the canvas height.
  double posY;

  /// Width of the visualizer bounding box, as a fraction of canvas width.
  double width;

  /// Height of the visualizer bounding box, as a fraction of canvas height.
  double height;

  int primaryColorValue;
  int secondaryColorValue;

  /// How the wave colors are derived from [primaryColorValue] and
  /// [secondaryColorValue]. Random mode stores the generated random pair in
  /// those same two color fields so preview/export remain deterministic.
  VisualizerColorMode colorMode;

  /// Rounded-rectangle background color behind the waveform/equalizer.
  int backgroundColorValue;

  /// 0.0 (fully transparent) - 1.0 (fully opaque).
  double backgroundOpacity;

  /// 0.0 - 1.0 percentage of the shortest box side used as corner radius.
  double cornerRadius;

  bool borderEnabled;
  int borderColorValue;
  double borderOpacity;
  double borderWidth;

  /// 0.0 (fully transparent) - 1.0 (fully opaque).
  double waveOpacity;

  /// Backwards-compatible alias used by older code/tests and old JSON's
  /// `opacity` key. It now means wave/equalizer opacity.
  double get opacity => waveOpacity;

  /// 0.0 (no glow) - 1.0 (maximum glow blur radius).
  double glowIntensity;

  /// Multiplier applied to incoming amplitude/band values before drawing.
  /// 1.0 = neutral, >1.0 = more reactive, <1.0 = calmer.
  double sensitivity;

  /// Stroke/bar thickness in logical pixels. The default is intentionally
  /// thin so the visualizer reads as many radio-equalizer sticks, not large
  /// blocks or a connected rope.
  double barWidth;

  /// Number of equalizer columns to draw for dense templates. Clamped by
  /// the renderer to a mobile-friendly range.
  int barCount;

  /// Coarse density preset shown in the UI. The renderer combines this with
  /// [barCount] and the available width to keep mobile performance safe.
  VisualizerDensity density;

  /// 0.0 - 1.0 spatial smoothing across neighboring bars.
  double smoothing;

  /// 0.0 - 1.0 maximum vertical travel inside the overlay box. Real audio
  /// still controls the actual height; this only caps the ceiling.
  double waveHeight;

  /// Optional sudden-impact boost, 0.0 - 1.0. Used for horror hits, screams,
  /// whooshes and other quiet-to-loud changes detected in real audio.
  double impactSensitivity;

  /// 0.0 - 1.0 attack speed. Higher values rise faster on sudden sounds.
  double attack;

  /// 0.0 - 1.0 release length. Higher values fall more slowly/cinematically.
  double release;

  /// Default is OFF: bars grow upward from one fixed bottom baseline.
  /// Mirrored growth is available only when the user/template requests it.
  bool mirrored;

  /// Draws a subtle fixed baseline (or center line for mirrored templates).
  bool centerLineEnabled;

  /// User-facing alias for [barWidth].
  double get waveThickness => barWidth;

  VisualizerAlignment alignment;
  ExportAspectRatio aspectRatio;

  VisualizerSettings({
    this.template = VisualizerTemplateType.storyWave,
    this.posX = 0.1,
    this.posY = 0.65,
    this.width = 0.8,
    this.height = 0.25,
    int? primaryColorValue,
    int? secondaryColorValue,
    this.colorMode = VisualizerColorMode.gradient,
    int? backgroundColorValue,
    this.backgroundOpacity = 0.20,
    this.cornerRadius = 0.14,
    this.borderEnabled = false,
    int? borderColorValue,
    this.borderOpacity = 0.75,
    this.borderWidth = 1.5,
    double? opacity,
    double? waveOpacity,
    this.glowIntensity = 0.35,
    this.sensitivity = 1.10,
    this.barCount = 88,
    this.density = VisualizerDensity.high,
    this.smoothing = 0.65,
    this.waveHeight = 0.78,
    this.impactSensitivity = 0.65,
    this.attack = 0.86,
    this.release = 0.58,
    this.mirrored = false,
    this.centerLineEnabled = true,
    double? barWidth,
    double? waveThickness,
    this.alignment = VisualizerAlignment.center,
    this.aspectRatio = ExportAspectRatio.ratio16x9,
  }) : primaryColorValue = primaryColorValue ?? 0xFF17D7FF,
       secondaryColorValue = secondaryColorValue ?? 0xFF8B5CF6,
       backgroundColorValue = backgroundColorValue ?? 0xFF000000,
       borderColorValue = borderColorValue ?? 0xFFFFFFFF,
       waveOpacity = (waveOpacity ?? opacity ?? 1.0).clamp(0.0, 1.0).toDouble(),
       barWidth = (waveThickness ?? barWidth ?? 1.6)
           .clamp(0.5, 12.0)
           .toDouble();

  Color get primaryColor => Color(primaryColorValue);
  Color get secondaryColor => Color(secondaryColorValue);
  Color get backgroundColor => Color(backgroundColorValue);
  Color get borderColor => Color(borderColorValue);

  VisualizerSettings copyWith({
    VisualizerTemplateType? template,
    double? posX,
    double? posY,
    double? width,
    double? height,
    int? primaryColorValue,
    int? secondaryColorValue,
    VisualizerColorMode? colorMode,
    int? backgroundColorValue,
    double? backgroundOpacity,
    double? cornerRadius,
    bool? borderEnabled,
    int? borderColorValue,
    double? borderOpacity,
    double? borderWidth,
    double? opacity,
    double? waveOpacity,
    double? glowIntensity,
    double? sensitivity,
    int? barCount,
    VisualizerDensity? density,
    double? smoothing,
    double? waveHeight,
    double? impactSensitivity,
    double? attack,
    double? release,
    bool? mirrored,
    bool? centerLineEnabled,
    double? barWidth,
    double? waveThickness,
    VisualizerAlignment? alignment,
    ExportAspectRatio? aspectRatio,
  }) {
    return VisualizerSettings(
      template: template ?? this.template,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      secondaryColorValue: secondaryColorValue ?? this.secondaryColorValue,
      colorMode: colorMode ?? this.colorMode,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      borderEnabled: borderEnabled ?? this.borderEnabled,
      borderColorValue: borderColorValue ?? this.borderColorValue,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      borderWidth: borderWidth ?? this.borderWidth,
      waveOpacity: waveOpacity ?? opacity ?? this.waveOpacity,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      sensitivity: sensitivity ?? this.sensitivity,
      barCount: barCount ?? this.barCount,
      density: density ?? this.density,
      smoothing: smoothing ?? this.smoothing,
      waveHeight: waveHeight ?? this.waveHeight,
      impactSensitivity: impactSensitivity ?? this.impactSensitivity,
      attack: attack ?? this.attack,
      release: release ?? this.release,
      mirrored: mirrored ?? this.mirrored,
      centerLineEnabled: centerLineEnabled ?? this.centerLineEnabled,
      barWidth: waveThickness ?? barWidth ?? this.barWidth,
      alignment: alignment ?? this.alignment,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  /// Applies a template and its sensible story/music/horror preset without
  /// moving or resizing the user's overlay box.
  VisualizerSettings applyTemplatePreset(VisualizerTemplateType next) {
    final base = copyWith(template: next);
    switch (next) {
      case VisualizerTemplateType.storyWave:
        return base.copyWith(
          colorMode: VisualizerColorMode.gradient,
          primaryColorValue: 0xFF17D7FF,
          secondaryColorValue: 0xFF8B5CF6,
          backgroundOpacity: 0.20,
          glowIntensity: 0.35,
          sensitivity: 1.10,
          density: VisualizerDensity.high,
          barCount: 88,
          smoothing: 0.65,
          waveHeight: 0.78,
          impactSensitivity: 0.58,
          attack: 0.86,
          release: 0.58,
          mirrored: false,
          centerLineEnabled: true,
          barWidth: 1.6,
        );
      case VisualizerTemplateType.horrorWave:
      case VisualizerTemplateType.darkWave:
        return base.copyWith(
          colorMode: VisualizerColorMode.gradient,
          primaryColorValue: 0xFFE11D48,
          secondaryColorValue: 0xFF3B0764,
          backgroundOpacity: 0.28,
          glowIntensity: 0.40,
          sensitivity: 1.30,
          density: VisualizerDensity.high,
          barCount: 96,
          smoothing: 0.55,
          waveHeight: 0.86,
          impactSensitivity: 0.70,
          attack: 0.92,
          release: 0.56,
          mirrored: false,
          centerLineEnabled: true,
          barWidth: 1.4,
        );
      case VisualizerTemplateType.cinematicWave:
      case VisualizerTemplateType.cinematicGlow:
        return base.copyWith(
          colorMode: VisualizerColorMode.gradient,
          primaryColorValue: 0xFF38BDF8,
          secondaryColorValue: 0xFFA855F7,
          backgroundOpacity: 0.24,
          glowIntensity: 0.45,
          sensitivity: 1.10,
          density: VisualizerDensity.high,
          barCount: 96,
          smoothing: 0.70,
          waveHeight: 0.80,
          impactSensitivity: 0.62,
          attack: 0.80,
          release: 0.70,
          mirrored: false,
          centerLineEnabled: true,
          barWidth: 1.7,
        );
      case VisualizerTemplateType.spectrumBars:
      case VisualizerTemplateType.equalizerBars:
      case VisualizerTemplateType.gradientBars:
        return base.copyWith(
          colorMode: VisualizerColorMode.gradient,
          primaryColorValue: 0xFFFF3B30,
          secondaryColorValue: 0xFF0A84FF,
          glowIntensity: 0.38,
          sensitivity: 1.10,
          density: VisualizerDensity.high,
          barCount: 96,
          smoothing: 0.45,
          waveHeight: 0.84,
          impactSensitivity: 0.55,
          attack: 0.88,
          release: 0.45,
          mirrored: false,
          centerLineEnabled: true,
          barWidth: 1.8,
        );
      case VisualizerTemplateType.rainbowWave:
        return base.copyWith(
          colorMode: VisualizerColorMode.rainbow,
          glowIntensity: 0.42,
          sensitivity: 1.10,
          density: VisualizerDensity.high,
          barCount: 100,
          smoothing: 0.45,
          waveHeight: 0.84,
          mirrored: false,
          centerLineEnabled: true,
          barWidth: 1.8,
        );
      case VisualizerTemplateType.mirrorBars:
      case VisualizerTemplateType.mirrorWave:
      case VisualizerTemplateType.dualWaveform:
      case VisualizerTemplateType.doubleWave:
        return base.copyWith(
          mirrored: true,
          centerLineEnabled: true,
          density: VisualizerDensity.high,
          barCount: 88,
          barWidth: 1.8,
          smoothing: 0.58,
        );
      case VisualizerTemplateType.minimalStory:
      case VisualizerTemplateType.minimalLineWave:
        return base.copyWith(
          colorMode: VisualizerColorMode.single,
          primaryColorValue: 0xFFFFFFFF,
          secondaryColorValue: 0xFFFFFFFF,
          backgroundOpacity: 0.08,
          glowIntensity: 0.18,
          sensitivity: 1.00,
          density: VisualizerDensity.medium,
          barCount: 72,
          smoothing: 0.70,
          waveHeight: 0.64,
          impactSensitivity: 0.45,
          mirrored: false,
          centerLineEnabled: true,
          barWidth: 1.2,
        );
      case VisualizerTemplateType.bassPulse:
      case VisualizerTemplateType.thickBars:
        return base.copyWith(
          density: VisualizerDensity.medium,
          barCount: 64,
          smoothing: 0.42,
          waveHeight: 0.88,
          sensitivity: 1.20,
          impactSensitivity: 0.62,
          mirrored: false,
          centerLineEnabled: true,
          barWidth: 2.2,
        );
      default:
        return base;
    }
  }

  /// Reset restores the whole visualizer to the built-in Story Equalizer
  /// default, including template, colors, density, controls, position and
  /// size. This matches the editor's reset expectation.
  VisualizerSettings resetAppearance() => VisualizerSettings();

  Map<String, dynamic> toJson() => {
    'template': template.name,
    'posX': posX,
    'posY': posY,
    'width': width,
    'height': height,
    'primaryColorValue': primaryColorValue,
    'secondaryColorValue': secondaryColorValue,
    'colorMode': colorMode.name,
    'backgroundColorValue': backgroundColorValue,
    'backgroundOpacity': backgroundOpacity,
    'cornerRadius': cornerRadius,
    'borderEnabled': borderEnabled,
    'borderColorValue': borderColorValue,
    'borderOpacity': borderOpacity,
    'borderWidth': borderWidth,
    'waveOpacity': waveOpacity,
    // Keep writing the old key too so older builds can still interpret the
    // project as a normal wave-opacity setting.
    'opacity': waveOpacity,
    'glowIntensity': glowIntensity,
    'sensitivity': sensitivity,
    'barCount': barCount,
    'density': density.name,
    'smoothing': smoothing,
    'waveHeight': waveHeight,
    'impactSensitivity': impactSensitivity,
    'attack': attack,
    'release': release,
    'mirrored': mirrored,
    'centerLineEnabled': centerLineEnabled,
    'barWidth': barWidth,
    'waveThickness': barWidth,
    'alignment': alignment.name,
    'aspectRatio': aspectRatio.name,
  };

  factory VisualizerSettings.fromJson(Map<String, dynamic> json) {
    return VisualizerSettings(
      template: VisualizerTemplateType.values.firstWhere(
        (e) => e.name == json['template'],
        orElse: () => VisualizerTemplateType.storyWave,
      ),
      posX: _double(json['posX'], 0.1),
      posY: _double(json['posY'], 0.65),
      width: _double(json['width'], 0.8),
      height: _double(json['height'], 0.25),
      primaryColorValue: _int(json['primaryColorValue'], 0xFF17D7FF),
      secondaryColorValue: _int(json['secondaryColorValue'], 0xFF8B5CF6),
      colorMode: VisualizerColorMode.values.firstWhere(
        (e) => e.name == json['colorMode'],
        orElse: () => VisualizerColorMode.gradient,
      ),
      backgroundColorValue: _int(json['backgroundColorValue'], 0xFF000000),
      backgroundOpacity: _double(json['backgroundOpacity'], 0.0)
          .clamp(0.0, 1.0)
          .toDouble(),
      cornerRadius: _double(json['cornerRadius'], 0.14)
          .clamp(0.0, 1.0)
          .toDouble(),
      borderEnabled: json['borderEnabled'] as bool? ?? false,
      borderColorValue: _int(json['borderColorValue'], 0xFFFFFFFF),
      borderOpacity: _double(json['borderOpacity'], 0.75)
          .clamp(0.0, 1.0)
          .toDouble(),
      borderWidth: _double(json['borderWidth'], 1.5)
          .clamp(0.0, 20.0)
          .toDouble(),
      waveOpacity: _double(json['waveOpacity'] ?? json['opacity'], 1.0)
          .clamp(0.0, 1.0)
          .toDouble(),
      glowIntensity: _double(json['glowIntensity'], 0.35)
          .clamp(0.0, 1.0)
          .toDouble(),
      sensitivity: _double(json['sensitivity'], 1.10)
          .clamp(0.05, 10.0)
          .toDouble(),
      barCount: _int(json['barCount'], 88).clamp(16, 180).toInt(),
      density: VisualizerDensity.values.firstWhere(
        (e) => e.name == json['density'],
        orElse: () => VisualizerDensity.high,
      ),
      smoothing: _double(json['smoothing'], 0.65)
          .clamp(0.0, 1.0)
          .toDouble(),
      waveHeight: _double(json['waveHeight'], 0.78)
          .clamp(0.05, 1.0)
          .toDouble(),
      impactSensitivity: _double(json['impactSensitivity'], 0.65)
          .clamp(0.0, 1.0)
          .toDouble(),
      attack: _double(json['attack'], 0.86).clamp(0.0, 1.0).toDouble(),
      release: _double(json['release'], 0.58).clamp(0.0, 1.0).toDouble(),
      mirrored: json['mirrored'] as bool? ?? false,
      centerLineEnabled: json['centerLineEnabled'] as bool? ?? true,
      barWidth: _double(json['waveThickness'] ?? json['barWidth'], 1.6)
          .clamp(0.5, 12.0)
          .toDouble(),
      alignment: VisualizerAlignment.values.firstWhere(
        (e) => e.name == json['alignment'],
        orElse: () => VisualizerAlignment.center,
      ),
      aspectRatio: ExportAspectRatio.values.firstWhere(
        (e) => e.name == json['aspectRatio'],
        orElse: () => ExportAspectRatio.ratio16x9,
      ),
    );
  }

  static double _double(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int _int(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? int.tryParse(value.replaceFirst('#', '0xFF')) ?? fallback;
    }
    return fallback;
  }
}
