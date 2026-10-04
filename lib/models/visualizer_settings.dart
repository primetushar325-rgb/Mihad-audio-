import 'dart:ui';

import 'visualizer_template.dart';

enum VisualizerAlignment { left, center, right }

enum VisualizerColorMode { single, gradient, rainbow, random }

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

/// All user-adjustable appearance/position settings for a visualizer
/// overlay. Position and size are stored as *fractions* (0.0-1.0) of the
/// canvas, so the exact same settings object can drive both the live
/// preview widget and the final pixel-accurate export renderer.
///
/// The premium visualizer is a rounded, movable/resizable overlay box: it
/// owns the background, border, wave colors and all wave styling values.
/// Newly added fields use conservative defaults during JSON parsing so
/// projects saved by older MIHAD AUDIO builds continue to load correctly.
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

  /// Rounded-rectangle background color behind the waveform.
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
  /// `opacity` key. It now means wave opacity.
  double get opacity => waveOpacity;

  /// 0.0 (no glow) - 1.0 (maximum glow blur radius).
  double glowIntensity;

  /// Multiplier applied to incoming amplitude/band values before drawing.
  /// 1.0 = neutral, >1.0 = more reactive, <1.0 = calmer.
  double sensitivity;

  /// Stroke/bar thickness in logical pixels at a 1080-tall reference
  /// canvas; scaled proportionally for other output sizes.
  double barWidth;

  /// Number of spectrum columns to draw for dense bar/equalizer templates.
  /// Clamped to a mobile-friendly range by the renderer.
  int barCount;

  /// 0.0 - 1.0 spatial smoothing across neighboring frequency bars. This
  /// keeps dense spectrums fluid without adding a separate animation loop.
  double smoothing;

  /// User-facing alias for [barWidth].
  double get waveThickness => barWidth;

  VisualizerAlignment alignment;
  ExportAspectRatio aspectRatio;

  VisualizerSettings({
    this.template = VisualizerTemplateType.spectrumBars,
    this.posX = 0.1,
    this.posY = 0.65,
    this.width = 0.8,
    this.height = 0.25,
    int? primaryColorValue,
    int? secondaryColorValue,
    this.colorMode = VisualizerColorMode.gradient,
    int? backgroundColorValue,
    this.backgroundOpacity = 0.55,
    this.cornerRadius = 0.18,
    this.borderEnabled = false,
    int? borderColorValue,
    this.borderOpacity = 0.75,
    this.borderWidth = 1.5,
    double? opacity,
    double? waveOpacity,
    this.glowIntensity = 0.35,
    this.sensitivity = 1.0,
    this.barCount = 80,
    this.smoothing = 0.45,
    double? barWidth,
    double? waveThickness,
    this.alignment = VisualizerAlignment.center,
    this.aspectRatio = ExportAspectRatio.ratio16x9,
  }) : primaryColorValue = primaryColorValue ?? 0xFF00E5A8,
       secondaryColorValue = secondaryColorValue ?? 0xFF6C5CE7,
       backgroundColorValue = backgroundColorValue ?? 0xFF000000,
       borderColorValue = borderColorValue ?? 0xFFFFFFFF,
       waveOpacity = (waveOpacity ?? opacity ?? 1.0).clamp(0.0, 1.0).toDouble(),
       barWidth = (waveThickness ?? barWidth ?? 4.0)
           .clamp(0.5, 80.0)
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
    double? smoothing,
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
      smoothing: smoothing ?? this.smoothing,
      barWidth: waveThickness ?? barWidth ?? this.barWidth,
      alignment: alignment ?? this.alignment,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  /// Resets appearance to sane defaults while preserving the chosen
  /// template and aspect ratio (matches "Reset to default settings").
  VisualizerSettings resetAppearance() {
    return VisualizerSettings(template: template, aspectRatio: aspectRatio);
  }

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
    'smoothing': smoothing,
    'barWidth': barWidth,
    'waveThickness': barWidth,
    'alignment': alignment.name,
    'aspectRatio': aspectRatio.name,
  };

  factory VisualizerSettings.fromJson(Map<String, dynamic> json) {
    return VisualizerSettings(
      template: VisualizerTemplateType.values.firstWhere(
        (e) => e.name == json['template'],
        orElse: () => VisualizerTemplateType.spectrumBars,
      ),
      posX: _double(json['posX'], 0.1),
      posY: _double(json['posY'], 0.65),
      width: _double(json['width'], 0.8),
      height: _double(json['height'], 0.25),
      primaryColorValue: _int(json['primaryColorValue'], 0xFF00E5A8),
      secondaryColorValue: _int(json['secondaryColorValue'], 0xFF6C5CE7),
      colorMode: VisualizerColorMode.values.firstWhere(
        (e) => e.name == json['colorMode'],
        orElse: () => VisualizerColorMode.gradient,
      ),
      backgroundColorValue: _int(json['backgroundColorValue'], 0xFF000000),
      backgroundOpacity: _double(json['backgroundOpacity'], 0.0)
          .clamp(0.0, 1.0)
          .toDouble(),
      cornerRadius: _double(json['cornerRadius'], 0.18)
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
      sensitivity: _double(json['sensitivity'], 1.0)
          .clamp(0.05, 10.0)
          .toDouble(),
      barCount: _int(json['barCount'], 80).clamp(16, 160).toInt(),
      smoothing: _double(json['smoothing'], 0.45)
          .clamp(0.0, 1.0)
          .toDouble(),
      barWidth: _double(json['waveThickness'] ?? json['barWidth'], 4.0)
          .clamp(0.5, 80.0)
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
