import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:video_player/video_player.dart';

import '../models/audio_analysis_data.dart';
import '../models/audio_source.dart';
import '../models/project.dart';
import '../models/visualizer_settings.dart';
import '../services/audio_analysis_service.dart';
import '../services/media_probe_service.dart';
import 'projects_library_provider.dart';

enum EditorLoadState { idle, loadingVideo, analyzingAudio, ready, error }

/// Owns everything needed by the Editor screen for one open [Project]:
/// video playback, on-device audio analysis, and live-editable visualizer
/// settings. Export itself is handled by [ExportController] (kept
/// separate so export can keep running conceptually independent of
/// in-editor playback state).
///
/// When the chosen audio source is a separate file, the source video's
/// own audio track is muted and a dedicated `just_audio` player is kept
/// in sync with video playback (play/pause/seek), so preview truly
/// reflects "Option B: Separate Audio" from the spec rather than just
/// silently ignoring it.
class EditorProvider extends ChangeNotifier {
  final ProjectsLibraryProvider _library;
  final MediaProbeService _probeService = MediaProbeService();
  final AudioAnalysisService _analysisService = AudioAnalysisService();

  Project? _project;
  VideoPlayerController? _videoController;
  ja.AudioPlayer? _separateAudioPlayer;
  AudioAnalysisData _analysisData = AudioAnalysisData.empty();
  EditorLoadState _state = EditorLoadState.idle;
  String? _errorMessage;
  double _analysisProgress = 0;
  double _videoAspectRatio = 16 / 9;

  EditorProvider(this._library);

  Project? get project => _project;
  VideoPlayerController? get videoController => _videoController;
  AudioAnalysisData get analysisData => _analysisData;
  EditorLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  double get analysisProgress => _analysisProgress;
  double get videoAspectRatio => _videoAspectRatio;
  bool get isUsingSeparateAudio => _separateAudioPlayer != null;

  /// Opens [project] for editing. If its source video path is missing or
  /// no longer accessible, [state] becomes [EditorLoadState.error] and the
  /// UI should prompt the user to reselect the video (spec section 11).
  Future<void> open(Project project) async {
    _project = project;
    _state = EditorLoadState.idle;
    _errorMessage = null;
    notifyListeners();

    final path = project.sourceVideoPath;
    if (path == null || !await File(path).exists()) {
      _state = EditorLoadState.error;
      _errorMessage = path == null
          ? 'No video has been selected for this project yet.'
          : 'The original video file could not be found. '
                'Please reselect it.';
      notifyListeners();
      return;
    }

    await setSourceVideo(path, persist: false);
  }

  Future<void> setSourceVideo(String path, {bool persist = true}) async {
    if (_project == null) return;
    _state = EditorLoadState.loadingVideo;
    _errorMessage = null;
    notifyListeners();

    try {
      await _videoController?.dispose();
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      _videoController = controller;
      _videoAspectRatio = controller.value.aspectRatio == 0
          ? 16 / 9
          : controller.value.aspectRatio;

      _project!.sourceVideoPath = path;
      if (persist) await _library.upsert(_project!);

      await _syncAudioOutputs();
      await _runAnalysis();
    } catch (e) {
      _state = EditorLoadState.error;
      _errorMessage =
          'This video format could not be opened on this '
          'device. Please try a different file. ($e)';
      notifyListeners();
    }
  }

  Future<void> setAudioSource(AudioSourceConfig config) async {
    if (_project == null) return;
    _project!.audioSource = config;
    await _library.upsert(_project!);
    await _syncAudioOutputs();
    await _runAnalysis();
  }

  /// Updates only the separate-audio volume, without re-running the
  /// (expensive) full decode + FFT analysis pass - used by the volume
  /// slider so dragging it stays instant (spec: avoid unnecessary
  /// repeated decoding).
  Future<void> setAudioVolume(double volume) async {
    final project = _project;
    if (project == null) return;
    project.audioSource.volume = volume;
    notifyListeners();
    await _separateAudioPlayer?.setVolume(volume);
    await _library.upsert(project);
  }

  /// Mutes/unmutes the source video and starts/stops the dedicated
  /// separate-audio player to match the current [AudioSourceConfig].
  Future<void> _syncAudioOutputs() async {
    final project = _project;
    final controller = _videoController;
    if (project == null || controller == null) return;

    if (project.audioSource.type == AudioSourceType.separateFile) {
      final path = project.audioSource.filePath;
      await controller.setVolume(0);
      if (path != null && await File(path).exists()) {
        _separateAudioPlayer ??= ja.AudioPlayer();
        try {
          await _separateAudioPlayer!.setFilePath(path);
          await _separateAudioPlayer!.setVolume(project.audioSource.volume);
          await _separateAudioPlayer!.seek(controller.value.position);
          if (controller.value.isPlaying) {
            await _separateAudioPlayer!.play();
          }
        } catch (_) {
          // Surfaced to the user separately via the audio-analysis error
          // path when this same file fails to decode for analysis.
        }
      }
    } else {
      await controller.setVolume(1.0);
      await _separateAudioPlayer?.stop();
      await _separateAudioPlayer?.dispose();
      _separateAudioPlayer = null;
    }
  }

  Future<void> _runAnalysis({double fps = 24}) async {
    final project = _project;
    if (project == null) return;

    final audioPath = project.audioSource.type == AudioSourceType.originalVideo
        ? project.sourceVideoPath
        : project.audioSource.filePath;

    if (audioPath == null || !await File(audioPath).exists()) {
      _state = EditorLoadState.error;
      _errorMessage = project.audioSource.type == AudioSourceType.separateFile
          ? 'The selected audio file could not be found. Please reselect it.'
          : 'This video has no audio track available to analyze.';
      notifyListeners();
      return;
    }

    _state = EditorLoadState.analyzingAudio;
    _analysisProgress = 0;
    notifyListeners();

    try {
      final data = await _analysisService.analyze(
        audioPath,
        fps: fps,
        onProgress: (p) {
          _analysisProgress = p;
          notifyListeners();
        },
      );
      _analysisData = data;
      _state = EditorLoadState.ready;
      _errorMessage = null;
    } on AudioAnalysisException catch (e) {
      _state = EditorLoadState.error;
      _errorMessage = e.message;
    } catch (e) {
      _state = EditorLoadState.error;
      _errorMessage = 'Audio analysis failed: $e';
    }
    notifyListeners();
  }

  Future<void> updateVisualizerSettings(
    VisualizerSettings Function(VisualizerSettings current) updater,
  ) async {
    final project = _project;
    if (project == null) return;
    project.visualizerSettings = updater(project.visualizerSettings);
    notifyListeners();
    await _library.upsert(project);
  }

  Future<void> renameProject(String name) async {
    final project = _project;
    if (project == null) return;
    project.name = name.trim().isEmpty ? project.name : name.trim();
    notifyListeners();
    await _library.upsert(project);
  }

  Future<void> play() async {
    final controller = _videoController;
    if (controller == null) return;
    if (_separateAudioPlayer != null) {
      await _separateAudioPlayer!.seek(controller.value.position);
      unawaited(_separateAudioPlayer!.play());
    }
    await controller.play();
  }

  Future<void> pause() async {
    await _videoController?.pause();
    await _separateAudioPlayer?.pause();
  }

  Future<void> seekTo(Duration position) async {
    await _videoController?.seekTo(position);
    await _separateAudioPlayer?.seek(position);
  }

  Future<MediaMetadataSummary?> probeCurrentVideo() async {
    final path = _project?.sourceVideoPath;
    if (path == null) return null;
    final meta = await _probeService.probe(path);
    if (meta == null) return null;
    return MediaMetadataSummary(
      duration: meta.duration,
      width: meta.width,
      height: meta.height,
      fps: meta.fps,
      hasAudioTrack: meta.hasAudioTrack,
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _separateAudioPlayer?.dispose();
    super.dispose();
  }
}

/// Lightweight read-only copy of [MediaMetadata] exposed to the UI layer.
class MediaMetadataSummary {
  final Duration duration;
  final int? width;
  final int? height;
  final double? fps;
  final bool hasAudioTrack;

  const MediaMetadataSummary({
    required this.duration,
    this.width,
    this.height,
    this.fps,
    required this.hasAudioTrack,
  });
}
