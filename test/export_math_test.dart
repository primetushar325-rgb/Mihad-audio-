import 'package:flutter_test/flutter_test.dart';
import 'package:mihad_audio/models/export_settings.dart';
import 'package:mihad_audio/models/visualizer_settings.dart';
import 'package:mihad_audio/services/export_math.dart';

void main() {
  group('resolveExportFps', () {
    test('fixed presets ignore source fps', () {
      expect(resolveExportFps(ExportFpsPreset.fps24, 59.94), 24);
      expect(resolveExportFps(ExportFpsPreset.fps30, 23.976), 30);
    });

    test('source preset uses the real source fps when valid', () {
      expect(resolveExportFps(ExportFpsPreset.source, 59.94), 59.94);
    });

    test(
      'source preset falls back to 30 when source fps is missing/invalid',
      () {
        expect(resolveExportFps(ExportFpsPreset.source, null), 30);
        expect(resolveExportFps(ExportFpsPreset.source, 0), 30);
      },
    );
  });

  group('resolveExportResolution', () {
    test('720p preset with 16:9 produces even 1280x720', () {
      final (w, h) = resolveExportResolution(
        preset: ExportResolutionPreset.res720p,
        aspect: ExportAspectRatio.ratio16x9,
        sourceWidth: 1920,
        sourceHeight: 1080,
      );
      expect(h, 720);
      expect(w, 1280);
      expect(w % 2, 0);
      expect(h % 2, 0);
    });

    test('1080p preset with 9:16 (portrait) swaps proportions correctly', () {
      final (w, h) = resolveExportResolution(
        preset: ExportResolutionPreset.res1080p,
        aspect: ExportAspectRatio.ratio9x16,
        sourceWidth: 1920,
        sourceHeight: 1080,
      );
      expect(h, 1080);
      expect(w, closeTo(1080 * 9 / 16, 1));
    });

    test('original preset uses the source height and its own aspect ratio', () {
      final (w, h) = resolveExportResolution(
        preset: ExportResolutionPreset.original,
        aspect: ExportAspectRatio.original,
        sourceWidth: 1001, // odd on purpose
        sourceHeight: 2001, // odd on purpose
      );
      expect(w % 2, 0);
      expect(h % 2, 0);
    });

    test('falls back to safe defaults when source dimensions are unknown', () {
      final (w, h) = resolveExportResolution(
        preset: ExportResolutionPreset.original,
        aspect: ExportAspectRatio.original,
        sourceWidth: null,
        sourceHeight: null,
      );
      expect(h, 720);
      expect(w, 1280);
    });
  });

  group('resolveVisualizerBounds', () {
    test('converts fractional settings into absolute canvas pixels', () {
      final settings = VisualizerSettings(
        posX: 0.1,
        posY: 0.2,
        width: 0.5,
        height: 0.25,
      );
      final bounds = resolveVisualizerBounds(settings, 1000, 800);

      expect(bounds.left, 100);
      expect(bounds.top, 160);
      expect(bounds.width, 500);
      expect(bounds.height, 200);
    });
  });
}
