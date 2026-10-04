import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/media_information.dart';

/// Basic metadata about a local media file, read entirely on-device via
/// FFprobe (bundled native binary, no network access).
class MediaMetadata {
  final Duration duration;
  final int? width;
  final int? height;
  final double? fps;
  final bool hasAudioTrack;

  const MediaMetadata({
    required this.duration,
    this.width,
    this.height,
    this.fps,
    required this.hasAudioTrack,
  });

  double? get aspectRatio => (width != null && height != null && height! > 0)
      ? width! / height!
      : null;
}

class MediaProbeService {
  /// Probes [path] (a video or audio file) and returns duration,
  /// resolution and frame-rate information. Returns null if the file
  /// could not be read/understood (e.g. unsupported/corrupt media).
  Future<MediaMetadata?> probe(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final MediaInformation? info = session.getMediaInformation();
      if (info == null) return null;

      final durationStr = info.getDuration();
      final totalSeconds = double.tryParse(durationStr ?? '') ?? 0.0;

      int? width;
      int? height;
      double? fps;
      bool hasAudio = false;

      for (final stream in info.getStreams()) {
        final type = stream.getType();
        if (type == 'video' && width == null) {
          width = stream.getWidth();
          height = stream.getHeight();
          final rate =
              stream.getAverageFrameRate() ?? stream.getRealFrameRate();
          fps = _parseFrameRate(rate);
        } else if (type == 'audio') {
          hasAudio = true;
        }
      }

      return MediaMetadata(
        duration: Duration(milliseconds: (totalSeconds * 1000).round()),
        width: width,
        height: height,
        fps: fps,
        hasAudioTrack: hasAudio,
      );
    } catch (_) {
      return null;
    }
  }

  double? _parseFrameRate(String? raw) {
    if (raw == null) return null;
    if (raw.contains('/')) {
      final parts = raw.split('/');
      if (parts.length == 2) {
        final num1 = double.tryParse(parts[0]);
        final num2 = double.tryParse(parts[1]);
        if (num1 != null && num2 != null && num2 != 0) {
          return num1 / num2;
        }
      }
      return null;
    }
    return double.tryParse(raw);
  }
}
