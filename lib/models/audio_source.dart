enum AudioSourceType {
  /// Use the audio track embedded in the imported video.
  originalVideo,

  /// Use a separate audio file selected from the device.
  separateFile,
}

/// Describes where the audio that drives the visualizer (and ends up in
/// the exported MP4) comes from.
class AudioSourceConfig {
  AudioSourceType type;

  /// Only used when [type] is [AudioSourceType.separateFile]: absolute
  /// path to the audio file on device storage.
  String? filePath;

  /// Playback volume for the chosen audio source during preview/export,
  /// 0.0 - 1.0.
  double volume;

  AudioSourceConfig({
    this.type = AudioSourceType.originalVideo,
    this.filePath,
    this.volume = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'filePath': filePath,
    'volume': volume,
  };

  factory AudioSourceConfig.fromJson(Map<String, dynamic> json) {
    return AudioSourceConfig(
      type: AudioSourceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AudioSourceType.originalVideo,
      ),
      filePath: json['filePath'] as String?,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
