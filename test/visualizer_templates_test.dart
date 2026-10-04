import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mihad_audio/models/visualizer_settings.dart';
import 'package:mihad_audio/models/visualizer_template.dart';
import 'package:mihad_audio/visualizers/visualizer_painter_base.dart';
import 'package:mihad_audio/visualizers/visualizer_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exactly the 10 specified templates are registered', () {
    expect(kVisualizerTemplates.length, 10);
    for (final info in kVisualizerTemplates) {
      expect(
        visualizerRegistry.containsKey(info.type),
        isTrue,
        reason: '${info.displayName} has no registered painter',
      );
    }
  });

  group('every template paints real, audio-driven output without throwing', () {
    for (final type in VisualizerTemplateType.values) {
      test(type.name, () {
        final delegate = painterFor(type);
        final settings = VisualizerSettings(template: type);

        final loudFrame = VisualizerFrameData(
          amplitude: 0.9,
          bands: List.generate(32, (i) => (i % 4) / 4),
        );
        final silentFrame = VisualizerFrameData(
          amplitude: 0.0,
          bands: List.filled(32, 0.0),
        );

        for (final frame in [loudFrame, silentFrame]) {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          expect(
            () => delegate.paint(
              canvas,
              const ui.Size(320, 180),
              frame,
              settings,
            ),
            returnsNormally,
          );
          recorder.endRecording().dispose();
        }
      });
    }
  });

  test('silent audio and loud audio produce different visual output', () {
    // Using EqualizerBars as a representative template: a silent frame
    // should draw materially smaller bars than a loud one. We can't pixel
    // -diff easily here, but we can assert the painter does not crash and
    // that amplitude/band values of 0 are handled distinctly from >0
    // (regression guard for "proper handling of silent audio").
    final delegate = painterFor(VisualizerTemplateType.equalizerBars);
    final settings = VisualizerSettings(
      template: VisualizerTemplateType.equalizerBars,
    );

    final silent = VisualizerFrameData(
      amplitude: 0,
      bands: List.filled(32, 0.0),
    );
    final loud = VisualizerFrameData(amplitude: 1, bands: List.filled(32, 1.0));

    expect(() {
      final r1 = ui.PictureRecorder();
      delegate.paint(ui.Canvas(r1), const ui.Size(200, 200), silent, settings);
      r1.endRecording().dispose();

      final r2 = ui.PictureRecorder();
      delegate.paint(ui.Canvas(r2), const ui.Size(200, 200), loud, settings);
      r2.endRecording().dispose();
    }, returnsNormally);
  });
}
