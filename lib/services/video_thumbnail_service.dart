import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

/// Generates real on-device video thumbnails using the same local FFmpeg
/// engine that powers export (`ffmpeg_kit_flutter_new`) - this avoids a
/// second, separately-maintained native thumbnail plugin and its own
/// Android build quirks. Nothing here ever leaves the device.
///
/// Thumbnails are cached under the app's temp directory, keyed by the
/// source video's path and last-modified time, so re-opening the same
/// project repeatedly doesn't re-decode the video every time.
class VideoThumbnailService {
  static final Map<String, Future<String?>> _inFlight = {};

  /// Returns a path to a locally-cached JPEG thumbnail for [videoPath],
  /// or `null` if generation isn't possible (missing file, unsupported
  /// format, FFmpeg failure, etc). Safe to call repeatedly/concurrently
  /// for the same video - concurrent calls share one in-flight request.
  static Future<String?> thumbnailFor(String videoPath) {
    return _inFlight.putIfAbsent(videoPath, () => _generate(videoPath));
  }

  static Future<String?> _generate(String videoPath) async {
    try {
      final source = File(videoPath);
      if (!await source.exists()) return null;

      final stat = await source.stat();
      final tempRoot = await getTemporaryDirectory();
      final cacheDir = Directory('${tempRoot.path}/mihad_audio/thumbnails');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final cacheKey =
          '${videoPath.hashCode}_${stat.modified.millisecondsSinceEpoch}';
      final outputPath = '${cacheDir.path}/$cacheKey.jpg';
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        return outputPath;
      }

      // Grab one frame near the start of the clip (falls back to the
      // very first frame via `-ss 0` if the video is shorter than 1s).
      final command =
          "-y -ss 00:00:01 -i '$videoPath' -frames:v 1 "
          "-vf \"scale=320:-1\" '$outputPath'";
      var session = await FFmpegKit.execute(command);
      var rc = await session.getReturnCode();
      if (!ReturnCode.isSuccess(rc) || !await outputFile.exists()) {
        // Retry at the very first frame for very short clips.
        final fallbackCommand =
            "-y -ss 00:00:00 -i '$videoPath' -frames:v 1 "
            "-vf \"scale=320:-1\" '$outputPath'";
        session = await FFmpegKit.execute(fallbackCommand);
        rc = await session.getReturnCode();
      }

      if (ReturnCode.isSuccess(rc) && await outputFile.exists()) {
        return outputPath;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      _inFlight.remove(videoPath);
    }
  }
}
