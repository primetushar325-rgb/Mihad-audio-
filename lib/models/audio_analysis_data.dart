/// Result of locally decoding + analyzing an audio track: a sequence of
/// fixed-size analysis frames, each holding an overall amplitude value,
/// time-domain waveform samples, detected impacts and frequency-band
/// energies. Produced entirely on-device by `AudioAnalysisService`
/// (PCM decode via FFmpeg + FFT via `fftea`) - no network calls, no
/// remote API.
class AudioAnalysisData {
  /// Duration represented by each analysis frame, in milliseconds.
  final double frameDurationMs;

  /// Overall normalized amplitude/envelope (0.0 - 1.0) per frame.
  final List<double> amplitude;

  /// Normalized (0.0 - 1.0) frequency-band energies per frame.
  /// Each inner list has [bandCount] entries, lowest frequency first.
  final List<List<double>> bands;

  /// Normalized time-domain waveform/envelope samples per frame. These are
  /// derived from the decoded PCM samples, not from synthetic animation, and
  /// are used by Story/Horror/Voice waveform modes.
  final List<List<double>> waveform;

  /// Optional sudden-change strength per frame (0.0 - 1.0). A high value
  /// means the real audio jumped quickly from quieter to louder content,
  /// useful for horror impacts, screams and whoosh hits.
  final List<double> impact;

  final int bandCount;
  final int waveformSampleCount;
  final double totalDurationMs;

  const AudioAnalysisData({
    required this.frameDurationMs,
    required this.amplitude,
    required this.bands,
    this.waveform = const [],
    this.impact = const [],
    required this.bandCount,
    this.waveformSampleCount = 96,
    required this.totalDurationMs,
  });

  factory AudioAnalysisData.empty({
    int bandCount = 32,
    int waveformSampleCount = 96,
  }) =>
      AudioAnalysisData(
        frameDurationMs: 1000 / 30,
        amplitude: const [],
        bands: const [],
        waveform: const [],
        impact: const [],
        bandCount: bandCount,
        waveformSampleCount: waveformSampleCount,
        totalDurationMs: 0,
      );

  bool get isEmpty => amplitude.isEmpty;

  int _indexFor(double positionMs) {
    if (amplitude.isEmpty) return 0;
    final index = (positionMs / frameDurationMs).round();
    return index.clamp(0, amplitude.length - 1).toInt();
  }

  /// Returns the amplitude at [positionMs], clamped to the available
  /// range. Returns 0 if no analysis data is available (e.g. silence or
  /// analysis not finished yet).
  double amplitudeAt(double positionMs) {
    if (amplitude.isEmpty) return 0.0;
    return amplitude[_indexFor(positionMs)];
  }

  /// Returns a short attack/release envelope ending at [positionMs]. This is
  /// calculated from real analysis frames and gives renderers a fast rise for
  /// impacts plus a smooth falloff for cinematic/horror visuals.
  double envelopeAt(
    double positionMs, {
    double attack = 0.85,
    double release = 0.58,
  }) {
    if (amplitude.isEmpty) return 0.0;
    final index = _indexFor(positionMs);
    final lookback = (1000 / frameDurationMs).round().clamp(8, 48).toInt();
    final start = (index - lookback).clamp(0, amplitude.length - 1).toInt();

    var envelope = amplitude[start];
    final attackCoeff = (0.35 + attack.clamp(0.0, 1.0) * 0.64).clamp(0.0, 1.0).toDouble();
    // Larger release means a slower, more cinematic falloff.
    final releaseCoeff = (0.05 + (1 - release.clamp(0.0, 1.0)) * 0.45)
        .clamp(0.02, 0.70)
        .toDouble();
    for (var i = start + 1; i <= index; i++) {
      final target = amplitude[i];
      final coeff = target >= envelope ? attackCoeff : releaseCoeff;
      envelope += (target - envelope) * coeff;
    }
    return envelope.clamp(0.0, 1.0).toDouble();
  }

  /// Returns the frequency-band snapshot at [positionMs]. Returns a
  /// zero-filled list if no analysis data is available.
  List<double> bandsAt(double positionMs) {
    if (bands.isEmpty) return List<double>.filled(bandCount, 0.0);
    final index = _indexFor(positionMs).clamp(0, bands.length - 1).toInt();
    return bands[index];
  }

  /// Returns the time-domain waveform/envelope snapshot at [positionMs].
  /// Returns a zero-filled list if no waveform data is available.
  List<double> waveformAt(double positionMs) {
    if (waveform.isEmpty) {
      return List<double>.filled(waveformSampleCount, 0.0);
    }
    final index = _indexFor(positionMs).clamp(0, waveform.length - 1).toInt();
    return waveform[index];
  }

  /// Returns recent peak-held frequency values ending at [positionMs]. This
  /// is deterministic and derived from real analysis frames, so preview and
  /// export show the same falling peak markers without maintaining a separate
  /// animation state.
  List<double> peakBandsAt(double positionMs, {int lookbackFrames = 14}) {
    return _peakListAt(bands, bandCount, positionMs, lookbackFrames);
  }

  /// Returns recent peak-held time-domain values ending at [positionMs].
  List<double> peakWaveformAt(double positionMs, {int lookbackFrames = 14}) {
    return _peakListAt(
      waveform,
      waveformSampleCount,
      positionMs,
      lookbackFrames,
    );
  }

  List<double> _peakListAt(
    List<List<double>> frames,
    int valueCount,
    double positionMs,
    int lookbackFrames,
  ) {
    if (frames.isEmpty) return List<double>.filled(valueCount, 0.0);
    final index = _indexFor(positionMs).clamp(0, frames.length - 1).toInt();
    final start = (index - lookbackFrames).clamp(0, frames.length - 1).toInt();
    final output = List<double>.filled(valueCount, 0.0);
    for (var f = start; f <= index; f++) {
      final age = index - f;
      final ageRatio = (age / (lookbackFrames + 1))
          .clamp(0.0, 1.0)
          .toDouble();
      final decay = 1.0 - ageRatio * 0.55;
      final values = frames[f];
      final limit = values.length < valueCount ? values.length : valueCount;
      for (var i = 0; i < limit; i++) {
        final v = (values[i] * decay).clamp(0.0, 1.0).toDouble();
        if (v > output[i]) output[i] = v;
      }
    }
    return output;
  }

  /// Returns the sudden-impact strength at [positionMs], scaled by a
  /// 0.0-1.0 user sensitivity value.
  double impactAt(double positionMs, {double sensitivity = 0.65}) {
    if (impact.isEmpty) return 0.0;
    final index = _indexFor(positionMs).clamp(0, impact.length - 1).toInt();
    final scale = (0.35 + sensitivity.clamp(0.0, 1.0) * 1.15).toDouble();
    return (impact[index] * scale).clamp(0.0, 1.0).toDouble();
  }
}
