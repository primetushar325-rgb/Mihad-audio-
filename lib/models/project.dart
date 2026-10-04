import 'audio_source.dart';
import 'export_settings.dart';
import 'visualizer_settings.dart';

/// Persisted metadata for one MIHAD AUDIO project. This is saved as a
/// small local JSON file (see `storage_service.dart`) - no cloud, no
/// account, no backend. The actual source video/audio files are *not*
/// copied; only their on-device paths are referenced, so the user may be
/// asked to reselect media if the original file has moved or been
/// deleted (spec section 11).
class Project {
  final String id;
  String name;
  String? sourceVideoPath;
  DateTime createdAt;
  DateTime updatedAt;

  AudioSourceConfig audioSource;
  VisualizerSettings visualizerSettings;
  ExportSettings exportSettings;

  /// Paths to videos exported from this project, most recent first.
  List<String> exportedVideoPaths;

  Project({
    required this.id,
    required this.name,
    this.sourceVideoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    AudioSourceConfig? audioSource,
    VisualizerSettings? visualizerSettings,
    ExportSettings? exportSettings,
    List<String>? exportedVideoPaths,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       audioSource = audioSource ?? AudioSourceConfig(),
       visualizerSettings = visualizerSettings ?? VisualizerSettings(),
       exportSettings = exportSettings ?? ExportSettings(),
       exportedVideoPaths = exportedVideoPaths ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sourceVideoPath': sourceVideoPath,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'audioSource': audioSource.toJson(),
    'visualizerSettings': visualizerSettings.toJson(),
    'exportSettings': exportSettings.toJson(),
    'exportedVideoPaths': exportedVideoPaths,
  };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled project',
      sourceVideoPath: json['sourceVideoPath'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      audioSource: json['audioSource'] != null
          ? AudioSourceConfig.fromJson(
              Map<String, dynamic>.from(json['audioSource'] as Map),
            )
          : AudioSourceConfig(),
      visualizerSettings: json['visualizerSettings'] != null
          ? VisualizerSettings.fromJson(
              Map<String, dynamic>.from(json['visualizerSettings'] as Map),
            )
          : VisualizerSettings(),
      exportSettings: json['exportSettings'] != null
          ? ExportSettings.fromJson(
              Map<String, dynamic>.from(json['exportSettings'] as Map),
            )
          : ExportSettings(),
      exportedVideoPaths:
          (json['exportedVideoPaths'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
