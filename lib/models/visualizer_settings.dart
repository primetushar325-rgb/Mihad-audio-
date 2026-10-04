import 'dart:ui';

import 'visualizer_template.dart';

enum VisualizerAlignment { left, center, right }

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
/// preview widget and the final pixel-accurate export renderer -
/// guaranteeing WYSIWYG export (spec section 7).
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

  /// 0.0 (fully transparent) - 1.0 (fully opaque).
  double opacity;

  /// 0.0 (no glow) - 1.0 (maximum glow blur radius).
  double glowIntensity;

  /// Multiplier applied to incoming amplitude/band values before drawing.
  /// 1.0 = neutral, >1.0 = more reactive, <1.0 = calmer.
  double sensitivity;

  /// Stroke/bar thickness in logical pixels at a 1080-tall reference
  /// canvas; scaled proportionally for other output sizes.
  double barWidth;

  VisualizerAlignment alignment;
  ExportAspectRatio aspectRatio;

  VisualizerSettings({
    this.template = VisualizerTemplateType.equalizerBars,
    this.posX = 0.1,
    this.posY = 0.65,
    this.width = 0.8,
    this.height = 0.25,
    int? primaryColorValue,
    int? secondaryColorValue,
    this.opacity = 1.0,
    this.glowIntensity = 0.35,
    this.sensitivity = 1.0,
    this.barWidth = 6.0,
    this.alignment = VisualizerAlignment.center,
    this.aspectRatio = ExportAspectRatio.ratio16x9,
  }) : primaryColorValue = primaryColorValue ?? 0xFF00E5A8,
       secondaryColorValue = secondaryColorValue ?? 0xFF6C5CE7;

  Color get primaryColor => Color(primaryColorValue);
  Color get secondaryColor => Color(secondaryColorValue);

  VisualizerSettings copyWith({
    VisualizerTemplateType? template,
    double? posX,
    double? posY,
    double? width,
    double? height,
    int? primaryColorValue,
    int? secondaryColorValue,
    double? opacity,
    double? glowIntensity,
    double? sensitivity,
    double? barWidth,
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
      opacity: opacity ?? this.opacity,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      sensitivity: sensitivity ?? this.sensitivity,
      barWidth: barWidth ?? this.barWidth,
      alignment: alignment ?? this.alignment,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  /// Resets appearance to sane defaults while preserving the chosen
  /// template and aspect ratio (matches "Reset to default settings").
  VisualizerSettings resetAppearance() {
    final defaults = VisualizerSettings(
      template: template,
      aspectRatio: aspectRatio,
    );
    return defaults;
  }

  Map<String, dynamic> toJson() => {
    'template': template.name,
    'posX': posX,
    'posY': posY,
    'width': width,
    'height': height,
    'primaryColorValue': primaryColorValue,
    'secondaryColorValue': secondaryColorValue,
    'opacity': opacity,
    'glowIntensity': glowIntensity,
    'sensitivity': sensitivity,
    'barWidth': barWidth,
    'alignment': alignment.name,
    'aspectRatio': aspectRatio.name,
  };

  factory VisualizerSettings.fromJson(Map<String, dynamic> json) {
    return VisualizerSettings(
      template: VisualizerTemplateType.values.firstWhere(
        (e) => e.name == json['template'],
        orElse: () => VisualizerTemplateType.equalizerBars,
      ),
      posX: (json['posX'] as num?)?.toDouble() ?? 0.1,
      posY: (json['posY'] as num?)?.toDouble() ?? 0.65,
      width: (json['width'] as num?)?.toDouble() ?? 0.8,
      height: (json['height'] as num?)?.toDouble() ?? 0.25,
      primaryColorValue: json['primaryColorValue'] as int? ?? 0xFF00E5A8,
      secondaryColorValue: json['secondaryColorValue'] as int? ?? 0xFF6C5CE7,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      glowIntensity: (json['glowIntensity'] as num?)?.toDouble() ?? 0.35,
      sensitivity: (json['sensitivity'] as num?)?.toDouble() ?? 1.0,
      barWidth: (json['barWidth'] as num?)?.toDouble() ?? 6.0,
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
}
