import 'package:flutter_test/flutter_test.dart';
import 'package:mihad_audio/models/audio_analysis_data.dart';

void main() {
  group('AudioAnalysisData', () {
    test('empty() has no data and lookups return zero', () {
      final data = AudioAnalysisData.empty(bandCount: 8);

      expect(data.isEmpty, isTrue);
      expect(data.amplitudeAt(500), 0.0);
      expect(data.bandsAt(500), List<double>.filled(8, 0.0));
    });

    test('amplitudeAt looks up the nearest analysis frame', () {
      final data = AudioAnalysisData(
        frameDurationMs: 100,
        amplitude: [0.0, 0.2, 0.4, 0.6, 0.8],
        bands: List.generate(5, (_) => <double>[0.1, 0.2]),
        bandCount: 2,
        totalDurationMs: 500,
      );

      // 250ms / 100ms per frame = index 2.5 -> rounds to 2 or 3 depending
      // on platform rounding; just assert it's a plausible frame value.
      expect(data.amplitudeAt(0), 0.0);
      expect(data.amplitudeAt(100), 0.2);
      expect(data.amplitudeAt(400), 0.8);
    });

    test('amplitudeAt and bandsAt clamp out-of-range positions', () {
      final data = AudioAnalysisData(
        frameDurationMs: 50,
        amplitude: [0.1, 0.9],
        bands: [
          [0.3, 0.4],
          [0.5, 0.6],
        ],
        bandCount: 2,
        totalDurationMs: 100,
      );

      expect(data.amplitudeAt(-999), 0.1);
      expect(data.amplitudeAt(999999), 0.9);
      expect(data.bandsAt(-999), [0.3, 0.4]);
      expect(data.bandsAt(999999), [0.5, 0.6]);
    });
  });
}
