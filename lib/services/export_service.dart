import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../models/audio_analysis_data.dart';
import '../models/audio_source.dart';
import '../models/project.dart';
import '../models/visualizer_settings.dart';
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

/// Renders the final MP4 entirely on-device:
///
/// 1. Replays the exact same [VisualizerCanvasPainter] used in the live
///    preview, once per output frame, into an RGBA PNG sequence - this is
///    what keeps export pixel-accurate to what the user saw in preview.
/// 2. Uses the bundled, offline FFmpeg binary (`ffmpeg_kit_flutter_new`)
///    to turn that PNG sequence into a lossless alpha-channel overlay
///    clip, then composites it on top of the source video together with
///    the chosen audio track, encoding final H.264/AAC output.
///
/// No network access, no remote rendering service, no API key - all
/// processing happens in this process on the user's device.
class ExportService {
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
    final framesDir = Directory('${workDir.path}/frames');
    await framesDir.create(recursive: true);

    final totalFrames = (videoDuration.inMilliseconds / 1000 * fps)
        .ceil()
        .clamp(1, 1 << 30);

    try {
      await _renderFrames(
        framesDir: framesDir,
        totalFrames: totalFrames,
        fps: fps,
        outW: outW,
        outH: outH,
        settings: project.visualizerSettings,
        analysisData: analysisData,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );

      final overlayPath = '${workDir.path}/overlay.mov';
      await _assembleOverlayVideo(
        framesDir: framesDir,
        fps: fps,
        outputPath: overlayPath,
        cancelToken: cancelToken,
      );

      final outputsDir = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${outputsDir.path}/MihadAudioExports');
      if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
      final finalPath =
          '${exportsDir.path}/mihad_audio_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _composite(
        sourcePath: sourcePath,
        overlayPath: overlayPath,
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

  Future<void> _renderFrames({
    required Directory framesDir,
    required int totalFrames,
    required double fps,
    required int outW,
    required int outH,
    required VisualizerSettings settings,
    required AudioAnalysisData analysisData,
    required ExportCancelToken cancelToken,
    required void Function(ExportProgressUpdate update) onProgress,
  }) async {
    final delegate = painterFor(settings.template);
    final bounds = resolveVisualizerBounds(
      settings,
      outW.toDouble(),
      outH.toDouble(),
    );
    final boxLeft = bounds.left;
    final boxTop = bounds.top;
    final boxWidth = bounds.width;
    final boxHeight = bounds.height;

    for (var i = 0; i < totalFrames; i++) {
      if (cancelToken.isCancelled) throw ExportCancelledException();

      final timeMs = i / fps * 1000;
      final frameData = VisualizerFrameData(
        amplitude: analysisData.amplitudeAt(timeMs),
        bands: analysisData.bandsAt(timeMs),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      // Fully transparent background; only the visualizer box is drawn.
      canvas.save();
      canvas.translate(boxLeft, boxTop);
      canvas.clipRect(ui.Rect.fromLTWH(0, 0, boxWidth, boxHeight));
      delegate.paint(canvas, ui.Size(boxWidth, boxHeight), frameData, settings);
      canvas.restore();

      final picture = recorder.endRecording();
      final image = await picture.toImage(outW, outH);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();

      if (byteData != null) {
        final file = File(
          '${framesDir.path}/frame_${i.toString().padLeft(6, '0')}.png',
        );
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }

      if (i % 5 == 0) {
        onProgress(
          ExportProgressUpdate(ExportStage.renderingOverlay, i / totalFrames),
        );
        // Yield to the UI thread periodically so the app stays responsive.
        await Future<void>.delayed(Duration.zero);
      }
    }
    onProgress(const ExportProgressUpdate(ExportStage.renderingOverlay, 1));
  }

  Future<void> _assembleOverlayVideo({
    required Directory framesDir,
    required double fps,
    required String outputPath,
    required ExportCancelToken cancelToken,
  }) async {
    if (cancelToken.isCancelled) throw ExportCancelledException();
    final command =
        '-y -framerate ${fps.toStringAsFixed(2)} '
        '-i "${framesDir.path}/frame_%06d.png" '
        '-c:v qtrle -pix_fmt argb "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (!ReturnCode.isSuccess(rc)) {
      throw ExportException(
        'Failed to assemble the visualizer overlay. '
        '${await session.getFailStackTrace() ?? ''}',
      );
    }
  }

  Future<void> _composite({
    required String sourcePath,
    required String overlayPath,
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

    final buffer = StringBuffer();
    buffer.write('-y -i "$sourcePath" -i "$overlayPath" ');
    if (useSeparateAudio) {
      buffer.write('-stream_loop -1 -i "${audioSource.filePath}" ');
    }
    buffer.write(
      '-filter_complex "[0:v]scale=$outW:$outH:force_original_aspect_ratio=increase,'
      'crop=$outW:$outH,setsar=1[bg];[bg][1:v]overlay=0:0:format=auto[outv]" ',
    );
    buffer.write('-map "[outv]" ');
    if (useSeparateAudio) {
      buffer.write('-map 2:a -af "volume=${audioSource.volume}" ');
    } else {
      buffer.write('-map 0:a? ');
    }
    buffer.write(
      '-c:v libx264 -preset veryfast -crf 20 -r ${fps.toStringAsFixed(2)} '
      '-pix_fmt yuv420p -c:a aac -b:a 192k '
      '-t ${durationSeconds.toStringAsFixed(3)} -shortest "$outputPath"',
    );

    final totalMs = durationSeconds * 1000;
    final completer = await _runAsyncWithProgress(
      buffer.toString(),
      cancelToken: cancelToken,
      onStatistics: (stats) {
        final processedMs = stats.getTime();
        final progress = totalMs > 0
            ? (processedMs / totalMs).clamp(0.0, 1.0)
            : 0.0;
        onProgress(ExportProgressUpdate(ExportStage.compositing, progress));
      },
    );

    if (!completer.success) {
      throw ExportException(
        'Final video encoding failed. ${completer.failureLog ?? ''}',
      );
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
}

class _FfmpegRunResult {
  final bool success;
  final String? failureLog;
  _FfmpegRunResult({required this.success, this.failureLog});
}
