import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:video_player/video_player.dart';

import '../models/audio_analysis_data.dart';
import '../models/audio_source.dart';
import '../models/project.dart';
import '../models/subtitle_catalog.dart';
import '../models/subtitle_models.dart';
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

  List<SubtitleLayer> get subtitleLayers => _project?.subtitleLayers ?? const [];
  String? get selectedSubtitleId => _project?.selectedSubtitleId;

  SubtitleCue? get selectedSubtitle {
    final id = selectedSubtitleId;
    if (id == null) return null;
    for (final layer in subtitleLayers) {
      for (final cue in layer.cues) {
        if (cue.id == id) return cue;
      }
    }
    return null;
  }

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

  Future<void> selectSubtitle(String? id) async {
    final project = _project;
    if (project == null) return;
    project.selectedSubtitleId = id;
    notifyListeners();
    await _library.upsert(project);
  }

  Future<SubtitleCue> addManualSubtitle({String? text}) async {
    final project = _project;
    if (project == null) {
      throw StateError('No project is open.');
    }
    final layer = _ensureSubtitleLayer(project);
    final position = _videoController?.value.position ?? Duration.zero;
    final startMs = position.inMilliseconds.toDouble();
    final endMs = startMs + 2600;
    final cueText = text ?? 'এই গল্পটা শুরু হয়েছিল মধ্যরাতে...';
    final cue = SubtitleCue(
      id: _newId('subtitle'),
      layerId: layer.id,
      text: cueText,
      startMs: startMs,
      endMs: endMs,
      words: _generateWordTimings(cueText, startMs, endMs),
      style: const SubtitleTextStyleConfig(),
    );
    _replaceLayer(
      project,
      layer.copyWith(cues: [...layer.cues, cue]),
    );
    project.selectedSubtitleId = cue.id;
    notifyListeners();
    await _library.upsert(project);
    return cue;
  }

  /// Free/offline auto-caption hook. No paid API key is required or used.
  /// The current Android build does not bundle a local speech-recognition
  /// model yet, so the editor falls back cleanly to manual captions while
  /// keeping a replaceable architecture for future on-device engines.
  Future<String> requestAutoSubtitleFallback() async {
    await addManualSubtitle(text: 'Automatic transcription is not available on this device. Edit this subtitle manually.');
    return 'Automatic transcription is not available on this device. You can enter subtitles manually.';
  }

  Future<void> updateSubtitleCue(
    String cueId,
    SubtitleCue Function(SubtitleCue cue) updater,
  ) async {
    final project = _project;
    if (project == null) return;
    final updatedLayers = project.subtitleLayers.map((layer) {
      final cues = layer.cues.map((cue) {
        if (cue.id != cueId || layer.locked || cue.locked) return cue;
        final next = updater(cue);
        return next.copyWith(
          words: next.words.isEmpty || next.text != cue.text || next.startMs != cue.startMs || next.endMs != cue.endMs
              ? _generateWordTimings(next.text, next.startMs, next.endMs)
              : next.words,
        );
      }).toList();
      return layer.copyWith(cues: cues);
    }).toList();
    project.subtitleLayers = updatedLayers;
    notifyListeners();
    await _library.upsert(project);
  }

  Future<void> applySubtitleTemplate(String cueId, String templateId) async {
    final template = subtitleTemplateById(templateId);
    await updateSubtitleCue(
      cueId,
      (cue) => cue.copyWith(style: template.style),
    );
  }

  Future<void> duplicateSubtitle(String cueId) async {
    final project = _project;
    if (project == null) return;
    for (final layer in project.subtitleLayers) {
      final index = layer.cues.indexWhere((cue) => cue.id == cueId);
      if (index == -1 || layer.locked) continue;
      final source = layer.cues[index];
      final copy = source.copyWith(
        id: _newId('subtitle'),
        startMs: source.endMs,
        endMs: source.endMs + source.durationMs,
      );
      final cues = [...layer.cues]..insert(index + 1, copy);
      _replaceLayer(project, layer.copyWith(cues: cues));
      project.selectedSubtitleId = copy.id;
      notifyListeners();
      await _library.upsert(project);
      return;
    }
  }

  Future<void> deleteSubtitle(String cueId) async {
    final project = _project;
    if (project == null) return;
    project.subtitleLayers = project.subtitleLayers
        .map((layer) => layer.locked ? layer : layer.copyWith(cues: layer.cues.where((cue) => cue.id != cueId).toList()))
        .toList();
    if (project.selectedSubtitleId == cueId) project.selectedSubtitleId = null;
    notifyListeners();
    await _library.upsert(project);
  }

  Future<void> splitSubtitle(String cueId) async {
    final project = _project;
    if (project == null) return;
    for (final layer in project.subtitleLayers) {
      final index = layer.cues.indexWhere((cue) => cue.id == cueId);
      if (index == -1 || layer.locked) continue;
      final cue = layer.cues[index];
      final midpoint = cue.startMs + cue.durationMs / 2;
      final words = cue.text.trim().split(RegExp(r'\s+'));
      final leftText = words.isEmpty ? cue.text : words.take((words.length / 2).ceil()).join(' ');
      final rightText = words.length < 2 ? cue.text : words.skip((words.length / 2).ceil()).join(' ');
      final first = cue.copyWith(
        text: leftText,
        endMs: midpoint,
        words: _generateWordTimings(leftText, cue.startMs, midpoint),
      );
      final second = cue.copyWith(
        id: _newId('subtitle'),
        text: rightText,
        startMs: midpoint,
        endMs: cue.endMs,
        words: _generateWordTimings(rightText, midpoint, cue.endMs),
      );
      final cues = [...layer.cues]
        ..removeAt(index)
        ..insertAll(index, [first, second]);
      _replaceLayer(project, layer.copyWith(cues: cues));
      project.selectedSubtitleId = second.id;
      notifyListeners();
      await _library.upsert(project);
      return;
    }
  }

  Future<void> mergeSelectedSubtitleWithNext() async {
    final project = _project;
    final id = project?.selectedSubtitleId;
    if (project == null || id == null) return;
    for (final layer in project.subtitleLayers) {
      final ordered = [...layer.cues]..sort((a, b) => a.startMs.compareTo(b.startMs));
      final index = ordered.indexWhere((cue) => cue.id == id);
      if (index == -1 || index >= ordered.length - 1 || layer.locked) continue;
      final a = ordered[index];
      final b = ordered[index + 1];
      final mergedText = '${a.text.trim()} ${b.text.trim()}'.trim();
      final merged = a.copyWith(
        text: mergedText,
        endMs: b.endMs,
        words: _generateWordTimings(mergedText, a.startMs, b.endMs),
      );
      final cues = layer.cues.where((cue) => cue.id != a.id && cue.id != b.id).toList()..add(merged);
      _replaceLayer(project, layer.copyWith(cues: cues));
      project.selectedSubtitleId = merged.id;
      notifyListeners();
      await _library.upsert(project);
      return;
    }
  }

  Future<void> updateSubtitleLayer(
    String layerId,
    SubtitleLayer Function(SubtitleLayer layer) updater,
  ) async {
    final project = _project;
    if (project == null) return;
    project.subtitleLayers = project.subtitleLayers.map((layer) {
      return layer.id == layerId ? updater(layer) : layer;
    }).toList();
    notifyListeners();
    await _library.upsert(project);
  }

  Future<void> saveSubtitleStyle(String cueId) async {
    final project = _project;
    final cue = selectedSubtitle;
    if (project == null || cue == null || cue.id != cueId) return;
    project.savedSubtitleStyles = [...project.savedSubtitleStyles, cue.style];
    notifyListeners();
    await _library.upsert(project);
  }

  Future<void> toggleFavoriteTemplate(String templateId) async {
    final project = _project;
    if (project == null) return;
    final favorites = [...project.favoriteSubtitleTemplateIds];
    favorites.contains(templateId) ? favorites.remove(templateId) : favorites.add(templateId);
    project.favoriteSubtitleTemplateIds = favorites;
    notifyListeners();
    await _library.upsert(project);
  }

  SubtitleLayer _ensureSubtitleLayer(Project project) {
    if (project.subtitleLayers.isNotEmpty) return project.subtitleLayers.first;
    final layer = SubtitleLayer(id: _newId('layer'), name: 'Subtitles');
    project.subtitleLayers = [layer];
    return layer;
  }

  void _replaceLayer(Project project, SubtitleLayer replacement) {
    project.subtitleLayers = project.subtitleLayers.map((layer) {
      return layer.id == replacement.id ? replacement : layer;
    }).toList();
    if (!project.subtitleLayers.any((layer) => layer.id == replacement.id)) {
      project.subtitleLayers = [...project.subtitleLayers, replacement];
    }
  }

  List<SubtitleWordTiming> _generateWordTimings(
    String text,
    double startMs,
    double endMs,
  ) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    final duration = (endMs - startMs).clamp(1.0, double.infinity).toDouble();
    final slice = duration / words.length;
    return List<SubtitleWordTiming>.generate(words.length, (index) {
      final wordStart = startMs + slice * index;
      return SubtitleWordTiming(
        word: words[index],
        startMs: wordStart,
        endMs: index == words.length - 1 ? endMs : wordStart + slice,
      );
    });
  }

  String _newId(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

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
