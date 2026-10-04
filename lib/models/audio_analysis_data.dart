/// Result of locally decoding + analyzing an audio track: a sequence of
/// fixed-size analysis frames, each holding an overall amplitude value
/// and a set of frequency-band energies. Produced entirely on-device by
/// `AudioAnalysisService` (PCM decode via FFmpeg + FFT via `fftea`) -
/// no network calls, no remote API.
class AudioAnalysisData {
  /// Duration represented by each analysis frame, in milliseconds.
  final double frameDurationMs;

  /// Overall normalized amplitude (0.0 - 1.0) per frame.
  final List<double> amplitude;

  /// Normalized (0.0 - 1.0) frequency-band energies per frame.
  /// Each inner list has [bandCount] entries, lowest frequency first.
  final List<List<double>> bands;

  final int bandCount;
  final double totalDurationMs;

  const AudioAnalysisData({
    required this.frameDurationMs,
    required this.amplitude,
    required this.bands,
    required this.bandCount,
    required this.totalDurationMs,
  });

  factory AudioAnalysisData.empty({int bandCount = 32}) => AudioAnalysisData(
    frameDurationMs: 1000 / 30,
    amplitude: const [],
    bands: const [],
    bandCount: bandCount,
    totalDurationMs: 0,
  );

  bool get isEmpty => amplitude.isEmpty;

  /// Returns the amplitude at [positionMs], clamped to the available
  /// range. Returns 0 if no analysis data is available (e.g. silence or
  /// analysis not finished yet).
  double amplitudeAt(double positionMs) {
    if (amplitude.isEmpty) return 0.0;
    final index = (positionMs / frameDurationMs).round();
    final clamped = index.clamp(0, amplitude.length - 1);
    return amplitude[clamped];
  }

  /// Returns the frequency-band snapshot at [positionMs]. Returns a
  /// zero-filled list if no analysis data is available.
  List<double> bandsAt(double positionMs) {
    if (bands.isEmpty) return List<double>.filled(bandCount, 0.0);
    final index = (positionMs / frameDurationMs).round();
    final clamped = index.clamp(0, bands.length - 1);
    return bands[clamped];
  }
}
