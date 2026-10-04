import 'export_settings.dart';

enum PreviewQuality { low, medium, high }

extension PreviewQualityX on PreviewQuality {
  String get label {
    switch (this) {
      case PreviewQuality.low:
        return 'Low (fastest)';
      case PreviewQuality.medium:
        return 'Medium';
      case PreviewQuality.high:
        return 'High (best quality)';
    }
  }

  /// Target analysis frame rate used while scrubbing the live preview.
  /// Lower values reduce CPU load on slower devices.
  double get analysisFps {
    switch (this) {
      case PreviewQuality.low:
        return 15;
      case PreviewQuality.medium:
        return 24;
      case PreviewQuality.high:
        return 30;
    }
  }
}

/// App-wide defaults, independent of any single project. Persisted via
/// [StorageService] as a small local JSON file.
class AppSettings {
  ExportResolutionPreset defaultResolution;
  ExportFpsPreset defaultFps;
  int defaultPrimaryColorValue;
  PreviewQuality previewQuality;

  AppSettings({
    this.defaultResolution = ExportResolutionPreset.res720p,
    this.defaultFps = ExportFpsPreset.fps30,
    this.defaultPrimaryColorValue = 0xFF00E5A8,
    this.previewQuality = PreviewQuality.medium,
  });

  Map<String, dynamic> toJson() => {
    'defaultResolution': defaultResolution.name,
    'defaultFps': defaultFps.name,
    'defaultPrimaryColorValue': defaultPrimaryColorValue,
    'previewQuality': previewQuality.name,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      defaultResolution: ExportResolutionPreset.values.firstWhere(
        (e) => e.name == json['defaultResolution'],
        orElse: () => ExportResolutionPreset.res720p,
      ),
      defaultFps: ExportFpsPreset.values.firstWhere(
        (e) => e.name == json['defaultFps'],
        orElse: () => ExportFpsPreset.fps30,
      ),
      defaultPrimaryColorValue:
          json['defaultPrimaryColorValue'] as int? ?? 0xFF00E5A8,
      previewQuality: PreviewQuality.values.firstWhere(
        (e) => e.name == json['previewQuality'],
        orElse: () => PreviewQuality.medium,
      ),
    );
  }
}
