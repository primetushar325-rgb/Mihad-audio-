import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../models/audio_analysis_data.dart';
import '../models/audio_source.dart';
import '../models/project.dart';
import '../subtitles/subtitle_renderer.dart';
import '../visualizers/visualizer_painter_base.dart';
import '../visualizers/visualizer_registry.dart';
import 'export_math.dart';

class ExportCancelledException implements Exception {}

class ExportException implements Exception {
  final String message;
  ExportException(this.message);
  @override
  String toString() => message;
}

/// A simple mutable flag the UI can flip to request cancellation of an
/// in-progress export (spec: "Cancel export").
class ExportCancelToken {
  bool _cancelled = false;
  void cancel() => _cancelled = true;
  bool get isCancelled => _cancelled;
}

enum ExportStage { renderingOverlay, compositing, savingToGallery, done }

class ExportProgressUpdate {
  final ExportStage stage;
  final double progress; // 0.0 - 1.0 for the current stage
  const ExportProgressUpdate(this.stage, this.progress);
}

/// Renders the final MP4 entirely on-device.
///
/// Export 2.0 keeps the existing Flutter CustomPainter + FFmpeg
/// architecture but removes the slowest parts of the old pipeline:
///
/// * only the visualizer bounding box is rendered to PNG frames instead
///   of rendering transparent full-resolution output frames;
/// * those small RGBA PNG frames are fed directly into the final FFmpeg
///   overlay filter, avoiding the old PNG sequence -> QTRLE MOV -> H264
///   intermediate encode;
/// * the final encoder attempts Android hardware H.264 after a real
///   capability probe and falls back safely to libx264 when unavailable.
class ExportService {
  bool? _hardwareH264Available;

  Future<String> export({
    required Project project,
    required Duration videoDuration,
    required int? sourceWidth,
    required int? sourceHeight,
    required double? sourceFps,
    required AudioAnalysisData analysisData,
    required ExportCancelToken cancelToken,
    required void Function(ExportProgressUpdate update) onProgress,
  }) async {
    final sourcePath = project.sourceVideoPath;
    if (sourcePath == null || !await File(sourcePath).exists()) {
      throw ExportException('Source video is missing. Please reselect it.');
    }

    final fps = resolveExportFps(project.exportSettings.fps, sourceFps);
    final (outW, outH) = resolveExportResolution(
      preset: project.exportSettings.resolution,
      aspect: project.visualizerSettings.aspectRatio,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
    );

    final tempRoot = await getTemporaryDirectory();
    final workDir = Directory(
      '${tempRoot.path}/mihad_audio/export_${DateTime.now().millisecondsSinceEpoch}',
    );
    final framesDir = Directory('${workDir.path}/overlay_frames');
    await framesDir.create(recursive: true);

    final totalFrames = (videoDuration.inMilliseconds / 1000 * fps)
        .ceil()
        .clamp(1, 1 << 30)
        .toInt();

    try {
      final overlay = await _renderOverlayRegionFrames(
        framesDir: framesDir,
        totalFrames: totalFrames,
        fps: fps,
        outW: outW,
        outH: outH,
        project: project,
        analysisData: analysisData,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );

      final outputsDir = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${outputsDir.path}/MihadAudioExports');
      if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
      final finalPath =
          '${exportsDir.path}/mihad_audio_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _compositeDirectPngSequence(
        sourcePath: sourcePath,
        overlay: overlay,
        audioSource: project.audioSource,
        outW: outW,
        outH: outH,
        fps: fps,
        durationSeconds: videoDuration.inMilliseconds / 1000,
        outputPath: finalPath,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );

      onProgress(const ExportProgressUpdate(ExportStage.savingToGallery, 0));
      try {
        if (await Gal.requestAccess()) {
          await Gal.putVideo(finalPath, album: 'MIHAD AUDIO');
        }
      } catch (_) {
        // Saving to the system gallery is a convenience, not a hard
        // requirement - the file already exists at [finalPath] either way.
      }
      onProgress(const ExportProgressUpdate(ExportStage.done, 1));

      return finalPath;
    } on ExportCancelledException {
      rethrow;
    } finally {
      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
    }
  }

  Future<_OverlayRenderResult> _renderOverlayRegionFrames({
    required Directory framesDir,
    required int totalFrames,
    required double fps,
    required int outW,
    required int outH,
    required Project project,
    required AudioAnalysisData analysisData,
    required ExportCancelToken cancelToken,
    required void Function(ExportProgressUpdate update) onProgress,
  }) async {
    final settings = project.visualizerSettings;
    final hasSubtitles = project.subtitleLayers.any(
      (layer) => layer.visible && layer.cues.any((cue) => cue.visible),
    );
    final delegate = painterFor(settings.template);
    final bounds = hasSubtitles
        ? Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble())
        : resolveVisualizerBounds(
            settings,
            outW.toDouble(),
            outH.toDouble(),
          );
    final overlayLeft = bounds.left.round().clamp(0, outW - 1).toInt();
    final overlayTop = bounds.top.round().clamp(0, outH - 1).toInt();
    final overlayWidth = bounds.width
        .round()
        .clamp(1, outW - overlayLeft)
        .toInt();
    final overlayHeight = bounds.height
        .round()
        .clamp(1, outH - overlayTop)
        .toInt();
    final overlaySize = ui.Size(overlayWidth.toDouble(), overlayHeight.toDouble());
    final localSettings = settings.copyWith(posX: 0, posY: 0, width: 1, height: 1);
    final visualizerBounds = resolveVisualizerBounds(
      settings,
      outW.toDouble(),
      outH.toDouble(),
    );
    final visualizerSize = ui.Size(
      visualizerBounds.width.roundToDouble().clamp(1, outW.toDouble()).toDouble(),
      visualizerBounds.height.roundToDouble().clamp(1, outH.toDouble()).toDouble(),
    );
    var bytesWritten = 0;

    for (var i = 0; i < totalFrames; i++) {
      if (cancelToken.isCancelled) throw ExportCancelledException();

      final timeMs = i / fps * 1000;
      final frameData = visualizerFrameFromAnalysis(
        analysisData,
        timeMs,
        localSettings,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      if (hasSubtitles) {
        canvas.save();
        canvas.translate(visualizerBounds.left, visualizerBounds.top);
        paintVisualizerOverlayBox(
          canvas: canvas,
          size: visualizerSize,
          data: frameData,
          settings: localSettings,
          delegate: delegate,
        );
        canvas.restore();
        paintSubtitles(
          canvas: canvas,
          size: ui.Size(outW.toDouble(), outH.toDouble()),
          layers: project.subtitleLayers,
          positionMs: timeMs,
        );
      } else {
        paintVisualizerOverlayBox(
          canvas: canvas,
          size: overlaySize,
          data: frameData,
          settings: localSettings,
          delegate: delegate,
        );
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(overlayWidth, overlayHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();

      if (byteData != null) {
        final file = File(
          '${framesDir.path}/frame_${i.toString().padLeft(6, '0')}.png',
        );
        final bytes = byteData.buffer.asUint8List();
        await file.writeAsBytes(bytes, flush: false);
        bytesWritten += bytes.length;
      }

      if (i % 5 == 0 || i == totalFrames - 1) {
        onProgress(
          ExportProgressUpdate(ExportStage.renderingOverlay, i / totalFrames),
        );
        // Yield to the UI thread periodically so the app stays responsive.
        await Future<void>.delayed(Duration.zero);
      }
    }
    onProgress(const ExportProgressUpdate(ExportStage.renderingOverlay, 1));

    return _OverlayRenderResult(
      framesDir: framesDir,
      left: overlayLeft,
      top: overlayTop,
      width: overlayWidth,
      height: overlayHeight,
      totalFrames: totalFrames,
      bytesWritten: bytesWritten,
    );
  }

  Future<void> _compositeDirectPngSequence({
    required String sourcePath,
    required _OverlayRenderResult overlay,
    required AudioSourceConfig audioSource,
    required int outW,
    required int outH,
    required double fps,
    required double durationSeconds,
    required String outputPath,
    required ExportCancelToken cancelToken,
    required void Function(ExportProgressUpdate update) onProgress,
  }) async {
    if (cancelToken.isCancelled) throw ExportCancelledException();

    final useSeparateAudio =
        audioSource.type == AudioSourceType.separateFile &&
        audioSource.filePath != null &&
        await File(audioSource.filePath!).exists();

    final hardwareAvailable = await _detectHardwareH264();
    final encoders = hardwareAvailable
        ? const [_H264Encoder.hardware, _H264Encoder.software]
        : const [_H264Encoder.software];
    _FfmpegRunResult? lastResult;

    for (final encoder in encoders) {
      if (cancelToken.isCancelled) throw ExportCancelledException();
      onProgress(const ExportProgressUpdate(ExportStage.compositing, 0));
      final command = _buildCompositeCommand(
        sourcePath: sourcePath,
        overlay: overlay,
        audioSource: audioSource,
        useSeparateAudio: useSeparateAudio,
        outW: outW,
        outH: outH,
        fps: fps,
        durationSeconds: durationSeconds,
        outputPath: outputPath,
        encoder: encoder,
      );
      lastResult = await _runAsyncWithProgress(
        command,
        cancelToken: cancelToken,
        onStatistics: (stats) {
          final processedMs = stats.getTime();
          final totalMs = durationSeconds * 1000;
          final progress = totalMs > 0
              ? (processedMs / totalMs).clamp(0.0, 1.0).toDouble()
              : 0.0;
          onProgress(ExportProgressUpdate(ExportStage.compositing, progress));
        },
      );
      if (cancelToken.isCancelled) throw ExportCancelledException();
      if (lastResult.success) return;
      if (encoder == _H264Encoder.hardware) {
        // Capability probes can pass while a specific device/video size still
        // fails at encode time. Fall back to the existing safe software path.
        try {
          final partial = File(outputPath);
          if (await partial.exists()) await partial.delete();
        } catch (_) {}
      }
    }

    throw ExportException(
      'Final video encoding failed. ${lastResult?.failureLog ?? ''}',
    );
  }

  String _buildCompositeCommand({
    required String sourcePath,
    required _OverlayRenderResult overlay,
    required AudioSourceConfig audioSource,
    required bool useSeparateAudio,
    required int outW,
    required int outH,
    required double fps,
    required double durationSeconds,
    required String outputPath,
    required _H264Encoder encoder,
  }) {
    final buffer = StringBuffer();
    buffer.write('-y -i "${_escapePath(sourcePath)}" ');
    buffer.write(
      '-framerate ${fps.toStringAsFixed(2)} '
      '-i "${_escapePath(overlay.framesDir.path)}/frame_%06d.png" ',
    );
    if (useSeparateAudio) {
      buffer.write('-stream_loop -1 -i "${_escapePath(audioSource.filePath!)}" ');
    }

    final fpsText = fps.toStringAsFixed(2);
    buffer.write(
      '-filter_complex "[0:v]scale=$outW:$outH:force_original_aspect_ratio=increase,'
      'crop=$outW:$outH,setsar=1,fps=$fpsText[bg];'
      '[1:v]format=rgba[ov];'
      '[bg][ov]overlay=${overlay.left}:${overlay.top}:format=auto:shortest=1[outv]" ',
    );
    buffer.write('-map "[outv]" ');
    if (useSeparateAudio) {
      buffer.write('-map 2:a -af "volume=${audioSource.volume}" ');
    } else {
      buffer.write('-map 0:a? ');
    }

    buffer.write(_encoderArgs(encoder, outW: outW, outH: outH, fps: fps));
    buffer.write(
      ' -pix_fmt yuv420p -c:a aac -b:a 192k '
      '-t ${durationSeconds.toStringAsFixed(3)} -shortest '
      '"${_escapePath(outputPath)}"',
    );
    return buffer.toString();
  }

  String _encoderArgs(_H264Encoder encoder, {
    required int outW,
    required int outH,
    required double fps,
  }) {
    switch (encoder) {
      case _H264Encoder.hardware:
        final pixels = outW * outH;
        final mp = pixels / (1280 * 720);
        final bitrateMbps = math.max(10, (8 * mp * (fps / 30)).round());
        return '-c:v h264_mediacodec -b:v ${bitrateMbps}M -r ${fps.toStringAsFixed(2)}';
      case _H264Encoder.software:
        return '-c:v libx264 -preset veryfast -crf 20 -r ${fps.toStringAsFixed(2)}';
    }
  }

  Future<bool> _detectHardwareH264() async {
    if (!Platform.isAndroid) return false;
    final cached = _hardwareH264Available;
    if (cached != null) return cached;

    final tempRoot = await getTemporaryDirectory();
    final probePath =
        '${tempRoot.path}/mihad_audio_hw_probe_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final command =
        '-y -f lavfi -i color=c=black:s=16x16:r=1:d=0.1 '
        '-an -c:v h264_mediacodec -b:v 1M -t 0.1 '
        '"${_escapePath(probePath)}"';
    try {
      final session = await FFmpegKit.execute(command);
      final rc = await session.getReturnCode();
      final output = File(probePath);
      final exists = await output.exists();
      final length = exists ? await output.length() : 0;
      final ok = ReturnCode.isSuccess(rc) && exists && length > 0;
      _hardwareH264Available = ok;
      try {
        if (await output.exists()) await output.delete();
      } catch (_) {}
      return ok;
    } catch (_) {
      _hardwareH264Available = false;
      return false;
    }
  }

  Future<_FfmpegRunResult> _runAsyncWithProgress(
    String command, {
    required ExportCancelToken cancelToken,
    required void Function(Statistics stats) onStatistics,
  }) async {
    final resultCompleter = Completer<_FfmpegRunResult>();
    int? sessionId;

    final session = await FFmpegKit.executeAsync(
      command,
      (completedSession) async {
        final rc = await completedSession.getReturnCode();
        if (ReturnCode.isSuccess(rc)) {
          resultCompleter.complete(_FfmpegRunResult(success: true));
        } else {
          final log = await completedSession.getFailStackTrace();
          resultCompleter.complete(
            _FfmpegRunResult(success: false, failureLog: log),
          );
        }
      },
      null,
      onStatistics,
    );
    sessionId = session.getSessionId();

    // Poll for cancellation requests while the async FFmpeg session runs.
    while (!resultCompleter.isCompleted) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (cancelToken.isCancelled && sessionId != null) {
        await FFmpegKit.cancel(sessionId);
      }
    }
    return resultCompleter.future;
  }

  String _escapePath(String path) => path.replaceAll('"', '\\"');
}

enum _H264Encoder { hardware, software }

class _OverlayRenderResult {
  final Directory framesDir;
  final int left;
  final int top;
  final int width;
  final int height;
  final int totalFrames;
  final int bytesWritten;

  const _OverlayRenderResult({
    required this.framesDir,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.totalFrames,
    required this.bytesWritten,
  });
}

class _FfmpegRunResult {
  final bool success;
  final String? failureLog;
  _FfmpegRunResult({required this.success, this.failureLog});
}
