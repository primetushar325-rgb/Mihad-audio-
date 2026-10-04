import 'package:flutter_test/flutter_test.dart';
import 'package:mihad_audio/models/audio_source.dart';
import 'package:mihad_audio/models/export_settings.dart';
import 'package:mihad_audio/models/project.dart';
import 'package:mihad_audio/models/visualizer_settings.dart';
import 'package:mihad_audio/models/visualizer_template.dart';

void main() {
  group('Project JSON persistence', () {
    test('round-trips a fully populated project', () {
      final project = Project(
        id: 'abc-123',
        name: 'My Concert Edit',
        sourceVideoPath: '/storage/emulated/0/Movies/concert.mp4',
        audioSource: AudioSourceConfig(
          type: AudioSourceType.separateFile,
          filePath: '/storage/emulated/0/Music/track.mp3',
          volume: 0.8,
        ),
        visualizerSettings: VisualizerSettings(
          template: VisualizerTemplateType.circularSpectrum,
        ),
        exportSettings: ExportSettings(
          resolution: ExportResolutionPreset.res1080p,
          fps: ExportFpsPreset.fps24,
        ),
        exportedVideoPaths: ['/storage/emulated/0/Movies/out1.mp4'],
      );

      final json = project.toJson();
      final restored = Project.fromJson(json);

      expect(restored.id, project.id);
      expect(restored.name, project.name);
      expect(restored.sourceVideoPath, project.sourceVideoPath);
      expect(restored.audioSource.type, AudioSourceType.separateFile);
      expect(restored.audioSource.filePath, project.audioSource.filePath);
      expect(restored.audioSource.volume, 0.8);
      expect(
        restored.visualizerSettings.template,
        VisualizerTemplateType.circularSpectrum,
      );
      expect(
        restored.exportSettings.resolution,
        ExportResolutionPreset.res1080p,
      );
      expect(restored.exportSettings.fps, ExportFpsPreset.fps24);
      expect(restored.exportedVideoPaths, project.exportedVideoPaths);
    });

    test('a project with no source video yet still serializes safely', () {
      final project = Project(id: 'new-project', name: 'Untitled');
      final restored = Project.fromJson(project.toJson());

      expect(restored.sourceVideoPath, isNull);
      expect(restored.audioSource.type, AudioSourceType.originalVideo);
      expect(restored.exportedVideoPaths, isEmpty);
    });

    test('missing/corrupted keys fall back instead of throwing', () {
      expect(() => Project.fromJson({'id': 'x'}), returnsNormally);
      final restored = Project.fromJson({'id': 'x'});
      expect(restored.name, 'Untitled project');
    });
  });
}
