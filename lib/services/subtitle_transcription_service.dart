import '../models/subtitle_models.dart';

class SubtitleTranscriptionResult {
  final bool available;
  final String message;
  final List<SubtitleCue> cues;

  const SubtitleTranscriptionResult({
    required this.available,
    required this.message,
    this.cues = const [],
  });
}

/// Free/local transcription abstraction. No paid SaaS, API key, credits or
/// watermark are used. A local/on-device recognizer can be plugged in later by
/// implementing this interface; unsupported devices receive a safe manual
/// fallback instead of a crash.
abstract class SubtitleTranscriptionEngine {
  String get id;
  String get label;
  bool get supportsBangla;
  Future<bool> isAvailable();
  Future<SubtitleTranscriptionResult> transcribe({
    required String mediaPath,
    required String layerId,
    String language = 'bn-BD',
  });
}

class ManualFallbackTranscriptionEngine implements SubtitleTranscriptionEngine {
  @override
  String get id => 'manual_fallback';

  @override
  String get label => 'Manual subtitle fallback';

  @override
  bool get supportsBangla => true;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<SubtitleTranscriptionResult> transcribe({
    required String mediaPath,
    required String layerId,
    String language = 'bn-BD',
  }) async {
    return const SubtitleTranscriptionResult(
      available: false,
      message: 'Automatic transcription is not available on this device. You can enter subtitles manually.',
    );
  }
}

class SubtitleTranscriptionService {
  final List<SubtitleTranscriptionEngine> engines;

  SubtitleTranscriptionService({List<SubtitleTranscriptionEngine>? engines})
      : engines = engines ?? [ManualFallbackTranscriptionEngine()];

  Future<SubtitleTranscriptionResult> transcribe({
    required String mediaPath,
    required String layerId,
    String language = 'bn-BD',
  }) async {
    for (final engine in engines) {
      if (!await engine.isAvailable()) continue;
      final result = await engine.transcribe(
        mediaPath: mediaPath,
        layerId: layerId,
        language: language,
      );
      if (result.available || result.cues.isNotEmpty) return result;
    }
    return const SubtitleTranscriptionResult(
      available: false,
      message: 'Automatic transcription is not available on this device. You can enter subtitles manually.',
    );
  }
}
