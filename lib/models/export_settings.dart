enum ExportResolutionPreset { res720p, res1080p, original }

extension ExportResolutionPresetX on ExportResolutionPreset {
  String get label {
    switch (this) {
      case ExportResolutionPreset.res720p:
        return '720p';
      case ExportResolutionPreset.res1080p:
        return '1080p';
      case ExportResolutionPreset.original:
        return 'Original';
    }
  }
}

enum ExportFpsPreset { fps24, fps30, source }

extension ExportFpsPresetX on ExportFpsPreset {
  String get label {
    switch (this) {
      case ExportFpsPreset.fps24:
        return '24 FPS';
      case ExportFpsPreset.fps30:
        return '30 FPS';
      case ExportFpsPreset.source:
        return 'Source FPS';
    }
  }
}

class ExportSettings {
  ExportResolutionPreset resolution;
  ExportFpsPreset fps;

  ExportSettings({
    this.resolution = ExportResolutionPreset.res720p,
    this.fps = ExportFpsPreset.fps30,
  });

  Map<String, dynamic> toJson() => {
    'resolution': resolution.name,
    'fps': fps.name,
  };

  factory ExportSettings.fromJson(Map<String, dynamic> json) {
    return ExportSettings(
      resolution: ExportResolutionPreset.values.firstWhere(
        (e) => e.name == json['resolution'],
        orElse: () => ExportResolutionPreset.res720p,
      ),
      fps: ExportFpsPreset.values.firstWhere(
        (e) => e.name == json['fps'],
        orElse: () => ExportFpsPreset.fps30,
      ),
    );
  }
}
