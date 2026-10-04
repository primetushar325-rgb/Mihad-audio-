import 'package:file_picker/file_picker.dart';

enum MediaPickStatus { success, cancelled, error }

/// Outcome of a pick attempt. Using an explicit result (rather than just
/// a nullable `String?`) lets the UI tell the difference between "the
/// user cancelled the picker" (do nothing) and "the picker itself failed"
/// (e.g. permission denied by the OS, or no picker app available) so it
/// can show a clear message instead of silently doing nothing (spec:
/// "Handle permission denial and unsupported media gracefully").
class MediaPickResult {
  final MediaPickStatus status;
  final String? path;
  final String? message;

  const MediaPickResult._(this.status, this.path, this.message);

  factory MediaPickResult.success(String path) =>
      MediaPickResult._(MediaPickStatus.success, path, null);
  factory MediaPickResult.cancelled() =>
      const MediaPickResult._(MediaPickStatus.cancelled, null, null);
  factory MediaPickResult.error(String message) =>
      MediaPickResult._(MediaPickStatus.error, null, message);

  bool get isSuccess => status == MediaPickStatus.success;
}

/// Wraps the system file/gallery picker (Android's Storage Access
/// Framework via `file_picker`). No files are uploaded anywhere; the
/// returned path stays on-device and is simply referenced by the project.
class MediaPickerService {
  /// Opens the system picker restricted to video files.
  Future<MediaPickResult> pickVideo() => _pick(FileType.video, 'video');

  /// Opens the system picker restricted to audio files.
  Future<MediaPickResult> pickAudio() => _pick(FileType.audio, 'audio');

  Future<MediaPickResult> _pick(FileType type, String kindLabel) async {
    try {
      final file = await FilePicker.pickFile(type: type);
      if (file?.path == null) {
        return MediaPickResult.cancelled();
      }
      return MediaPickResult.success(file!.path!);
    } catch (e) {
      return MediaPickResult.error(
        'Could not open the $kindLabel picker. This can happen if file '
        'access was denied or no file manager app is available on this '
        'device. ($e)',
      );
    }
  }
}
