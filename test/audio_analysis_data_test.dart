import 'package:flutter_test/flutter_test.dart';
import 'package:mihad_audio/models/audio_analysis_data.dart';

void main() {
  group('AudioAnalysisData', () {
    test('empty() has no data and lookups return zero', () {
      final data = AudioAnalysisData.empty(bandCount: 8, waveformSampleCount: 12);

      expect(data.isEmpty, isTrue);
      expect(data.amplitudeAt(500), 0.0);
      expect(data.envelopeAt(500), 0.0);
      expect(data.impactAt(500), 0.0);
      expect(data.bandsAt(500), List<double>.filled(8, 0.0));
      expect(data.waveformAt(500), List<double>.filled(12, 0.0));
    });

    test('amplitudeAt looks up the nearest analysis frame', () {
      final data = AudioAnalysisData(
        frameDurationMs: 100,
        amplitude: [0.0, 0.2, 0.4, 0.6, 0.8],
        bands: List.generate(5, (_) => <double>[0.1, 0.2]),
        waveform: List.generate(5, (_) => <double>[0.3, 0.4, 0.5]),
        impact: [0, 0.1, 0.2, 0.3, 0.4],
        bandCount: 2,
        waveformSampleCount: 3,
        totalDurationMs: 500,
      );

      expect(data.amplitudeAt(0), 0.0);
      expect(data.amplitudeAt(100), 0.2);
      expect(data.amplitudeAt(400), 0.8);
      expect(data.waveformAt(100), [0.3, 0.4, 0.5]);
      expect(data.impactAt(400), greaterThan(0.0));
    });

    test('amplitudeAt and bandsAt clamp out-of-range positions', () {
      final data = AudioAnalysisData(
        frameDurationMs: 50,
        amplitude: [0.1, 0.9],
        bands: [
          [0.3, 0.4],
          [0.5, 0.6],
        ],
        waveform: [
          [0.1, 0.2, 0.3],
          [0.7, 0.8, 0.9],
        ],
        impact: [0.0, 1.0],
        bandCount: 2,
        waveformSampleCount: 3,
        totalDurationMs: 100,
      );

      expect(data.amplitudeAt(-999), 0.1);
      expect(data.amplitudeAt(999999), 0.9);
      expect(data.bandsAt(-999), [0.3, 0.4]);
      expect(data.bandsAt(999999), [0.5, 0.6]);
      expect(data.waveformAt(-999), [0.1, 0.2, 0.3]);
      expect(data.waveformAt(999999), [0.7, 0.8, 0.9]);
    });

    test('envelope rises fast and releases smoothly from real frame data', () {
      final data = AudioAnalysisData(
        frameDurationMs: 100,
        amplitude: [0.0, 0.1, 1.0, 0.2, 0.1],
        bands: List.generate(5, (_) => <double>[0.1, 0.2]),
        bandCount: 2,
        totalDurationMs: 500,
      );

      expect(data.envelopeAt(200, attack: 0.9, release: 0.6), greaterThan(0.7));
      expect(data.envelopeAt(300, attack: 0.9, release: 0.8), greaterThan(0.2));
    });
  });
}
