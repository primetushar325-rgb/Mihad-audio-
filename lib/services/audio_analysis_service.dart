import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:fftea/fftea.dart';
import 'package:path_provider/path_provider.dart';

import '../models/audio_analysis_data.dart';

/// Exception thrown when a media file's audio track cannot be decoded or
/// analyzed locally (e.g. unsupported/corrupt codec).
class AudioAnalysisException implements Exception {
  final String message;
  AudioAnalysisException(this.message);
  @override
  String toString() => 'AudioAnalysisException: $message';
}

/// Decodes an audio track to raw PCM using the bundled, offline FFmpeg
/// binary and runs amplitude + time-domain waveform + FFT frequency-band
/// analysis entirely on the device (no network calls, no remote API). This
/// is the Flutter/mobile equivalent of using an AudioContext/AnalyserNode
/// with getByteTimeDomainData() and getByteFrequencyData() in a browser.
class AudioAnalysisService {
  static const int _sampleRate = 22050;
  static const int _fftWindowSize = 2048;
  static const int _waveformSampleCount = 96;
  static const double _silenceThreshold = 1e-4;

  /// Decodes [mediaPath]'s audio track and returns per-frame amplitude,
  /// waveform, impact and frequency-band data, where each frame represents
  /// [fps] frames per second of the eventual video timeline (so lookups are
  /// O(1) during playback/export).
  ///
  /// Throws [AudioAnalysisException] if the file has no usable audio
  /// track or could not be decoded.
  Future<AudioAnalysisData> analyze(
    String mediaPath, {
    double fps = 30,
    int bandCount = 32,
    void Function(double progress)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final pcmFile = File(
      '${tempDir.path}/mihad_pcm_${DateTime.now().microsecondsSinceEpoch}.pcm',
    );

    try {
      final session = await FFmpegKit.execute(
        '-y -i "$mediaPath" -vn -ac 1 -ar $_sampleRate -f s16le "${pcmFile.path}"',
      );
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getFailStackTrace();
        throw AudioAnalysisException(
          'No usable audio track could be decoded from this file. '
          '${logs ?? ''}',
        );
      }

      if (!await pcmFile.exists() || await pcmFile.length() < 4) {
        throw AudioAnalysisException(
          'The selected file does not appear to contain audio.',
        );
      }

      final bytes = await pcmFile.readAsBytes();
      final samples = _bytesToSamples(bytes);
      return _analyzeSamples(
        samples,
        fps: fps,
        bandCount: bandCount,
        onProgress: onProgress,
      );
    } finally {
      if (await pcmFile.exists()) {
        await pcmFile.delete();
      }
    }
  }

  Float64List _bytesToSamples(Uint8List bytes) {
    final byteData = ByteData.sublistView(bytes);
    final sampleCount = bytes.lengthInBytes ~/ 2;
    final samples = Float64List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      final int16 = byteData.getInt16(i * 2, Endian.little);
      samples[i] = int16 / 32768.0;
    }
    return samples;
  }

  AudioAnalysisData _analyzeSamples(
    Float64List samples, {
    required double fps,
    required int bandCount,
    void Function(double progress)? onProgress,
  }) {
    if (samples.isEmpty) {
      return AudioAnalysisData.empty(
        bandCount: bandCount,
        waveformSampleCount: _waveformSampleCount,
      );
    }

    final frameDurationMs = 1000.0 / fps;
    final hopSize = math.max(1, (_sampleRate * frameDurationMs / 1000).round());
    final frameCount = (samples.length / hopSize).ceil();

    final fft = FFT(_fftWindowSize);
    final window = _hannWindow(_fftWindowSize);

    final rawAmplitude = Float64List(frameCount);
    final rawWaveform = List<Float64List>.generate(
      frameCount,
      (_) => Float64List(_waveformSampleCount),
    );
    final rawBands = List<Float64List>.generate(
      frameCount,
      (_) => Float64List(bandCount),
    );

    final bandEdges = _logBandEdges(
      bandCount: bandCount,
      sampleRate: _sampleRate,
      minHz: 40,
      maxHz: _sampleRate / 2.2,
    );

    double globalPeakAmp = 0.0;
    double globalPeakWave = 0.0;
    double globalPeakBand = 0.0;

    for (var f = 0; f < frameCount; f++) {
      final hopStart = f * hopSize;

      // --- Amplitude (RMS of this hop's samples) ---
      double sumSquares = 0.0;
      final hopEnd = math.min(hopStart + hopSize, samples.length);
      for (var i = hopStart; i < hopEnd; i++) {
        sumSquares += samples[i] * samples[i];
      }
      final rms = hopEnd > hopStart
          ? math.sqrt(sumSquares / (hopEnd - hopStart))
          : 0.0;
      rawAmplitude[f] = rms;
      if (rms > globalPeakAmp) globalPeakAmp = rms;

      // --- Time-domain waveform/envelope bars centered on this frame. ---
      _fillWaveformFrame(
        samples: samples,
        frameStart: hopStart,
        frameEnd: hopEnd,
        output: rawWaveform[f],
      );
      for (final v in rawWaveform[f]) {
        if (v > globalPeakWave) globalPeakWave = v;
      }

      // --- Frequency bands (windowed FFT centered on this hop) ---
      final windowed = Float64List(_fftWindowSize);
      final windowStart = hopStart - (_fftWindowSize - hopSize) ~/ 2;
      for (var i = 0; i < _fftWindowSize; i++) {
        final sampleIndex = windowStart + i;
        if (sampleIndex >= 0 && sampleIndex < samples.length) {
          windowed[i] = samples[sampleIndex] * window[i];
        }
      }

      final spectrum = fft.realFft(windowed).discardConjugates().magnitudes();
      final bands = rawBands[f];
      for (var b = 0; b < bandCount; b++) {
        final startBin = bandEdges[b];
        final endBin = bandEdges[b + 1];
        double sum = 0.0;
        var count = 0;
        for (var bin = startBin; bin < endBin && bin < spectrum.length; bin++) {
          sum += spectrum[bin];
          count++;
        }
        final value = count > 0 ? sum / count : 0.0;
        bands[b] = value;
        if (value > globalPeakBand) globalPeakBand = value;
      }

      if (onProgress != null && f % 64 == 0) {
        onProgress(f / frameCount);
      }
    }

    final isSilent = globalPeakAmp < _silenceThreshold;

    // Normalize to 0..1 using perceptual (log) compression so quiet
    // passages are still visible and loud passages don't clip harshly.
    final amplitude = List<double>.filled(frameCount, 0.0);
    final impact = List<double>.filled(frameCount, 0.0);
    final waveform = List<List<double>>.generate(
      frameCount,
      (_) => List<double>.filled(_waveformSampleCount, 0.0),
    );
    final bands = List<List<double>>.generate(
      frameCount,
      (_) => List<double>.filled(bandCount, 0.0),
    );

    if (!isSilent) {
      const floorDb = -55.0;
      final peakAmpDb = math.max(_toDb(globalPeakAmp), floorDb + 1.0);
      final peakWaveDb = math.max(
        _toDb(math.max(globalPeakWave, globalPeakAmp)),
        floorDb + 1.0,
      );
      final peakBandDb = math.max(_toDb(globalPeakBand), floorDb + 1.0);

      var envelope = 0.0;
      var releasePeak = 0.0;
      final prevBand = List<double>.filled(bandCount, 0.0);
      final prevWave = List<double>.filled(_waveformSampleCount, 0.0);
      double previousNormAmp = 0.0;
      const bandSmoothing = 0.50;
      const waveSmoothing = 0.48;
      const attack = 0.88;
      const release = 0.24;
      const impactThreshold = 0.10;

      for (var f = 0; f < frameCount; f++) {
        final ampDb = _toDb(rawAmplitude[f]);
        final normAmp = ((ampDb - floorDb) / (peakAmpDb - floorDb))
            .clamp(0.0, 1.0)
            .toDouble();
        final coeff = normAmp >= envelope ? attack : release;
        envelope += (normAmp - envelope) * coeff;
        amplitude[f] = envelope.clamp(0.0, 1.0).toDouble();

        final jump = math.max(0.0, normAmp - previousNormAmp);
        final impactValue = ((jump - impactThreshold) / (1 - impactThreshold))
            .clamp(0.0, 1.0)
            .toDouble();
        releasePeak = math.max(impactValue, releasePeak * 0.72);
        impact[f] = releasePeak;
        previousNormAmp = normAmp;

        for (var w = 0; w < _waveformSampleCount; w++) {
          final waveDb = _toDb(rawWaveform[f][w]);
          final normWave = ((waveDb - floorDb) / (peakWaveDb - floorDb))
              .clamp(0.0, 1.0)
              .toDouble();
          final smoothedWave = waveSmoothing * normWave +
              (1 - waveSmoothing) * prevWave[w];
          waveform[f][w] = smoothedWave.clamp(0.0, 1.0).toDouble();
          prevWave[w] = smoothedWave;
        }

        for (var b = 0; b < bandCount; b++) {
          final bDb = _toDb(rawBands[f][b]);
          final normBand = ((bDb - floorDb) / (peakBandDb - floorDb))
              .clamp(0.0, 1.0)
              .toDouble();
          final smoothedBand =
              bandSmoothing * normBand + (1 - bandSmoothing) * prevBand[b];
          bands[f][b] = smoothedBand.clamp(0.0, 1.0).toDouble();
          prevBand[b] = smoothedBand;
        }
      }
    }

    onProgress?.call(1.0);

    return AudioAnalysisData(
      frameDurationMs: frameDurationMs,
      amplitude: amplitude,
      bands: bands,
      waveform: waveform,
      impact: impact,
      bandCount: bandCount,
      waveformSampleCount: _waveformSampleCount,
      totalDurationMs: samples.length / _sampleRate * 1000,
    );
  }

  void _fillWaveformFrame({
    required Float64List samples,
    required int frameStart,
    required int frameEnd,
    required Float64List output,
  }) {
    final span = math.max(1, frameEnd - frameStart);
    for (var w = 0; w < output.length; w++) {
      final start = frameStart + (span * w / output.length).floor();
      final end = frameStart + (span * (w + 1) / output.length).ceil();
      final safeStart = start.clamp(0, samples.length - 1).toInt();
      final safeEnd = end.clamp(safeStart + 1, samples.length).toInt();
      double peak = 0.0;
      double sumSquares = 0.0;
      for (var i = safeStart; i < safeEnd; i++) {
        final abs = samples[i].abs();
        if (abs > peak) peak = abs;
        sumSquares += abs * abs;
      }
      final rms = math.sqrt(sumSquares / math.max(1, safeEnd - safeStart));
      // Peak catches fast horror hits; RMS keeps narration stable.
      output[w] = peak * 0.55 + rms * 0.45;
    }
  }

  double _toDb(double linear) {
    final safe = linear <= 1e-9 ? 1e-9 : linear;
    return 20 * math.log(safe) / math.ln10;
  }

  Float64List _hannWindow(int size) {
    final w = Float64List(size);
    for (var i = 0; i < size; i++) {
      w[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (size - 1));
    }
    return w;
  }

  /// Returns [bandCount] + 1 FFT bin edges, log-spaced between [minHz] and
  /// [maxHz], so low frequencies (bass) get finer resolution than highs -
  /// matching how real equalizers group frequency bands.
  List<int> _logBandEdges({
    required int bandCount,
    required int sampleRate,
    required double minHz,
    required double maxHz,
  }) {
    final binHz = sampleRate / _fftWindowSize;
    final maxBin = _fftWindowSize ~/ 2;
    final edges = <int>[];
    final logMin = math.log(minHz);
    final logMax = math.log(maxHz);
    for (var i = 0; i <= bandCount; i++) {
      final t = i / bandCount;
      final hz = math.exp(logMin + (logMax - logMin) * t);
      final bin = (hz / binHz).round().clamp(0, maxBin).toInt();
      edges.add(bin);
    }
    // Ensure strictly increasing edges.
    for (var i = 1; i < edges.length; i++) {
      if (edges[i] <= edges[i - 1]) edges[i] = edges[i - 1] + 1;
    }
    return edges;
  }
}
