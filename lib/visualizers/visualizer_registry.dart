import '../models/visualizer_template.dart';
import 'visualizer_painter_base.dart';
import 'templates/circular_spectrum_painter.dart';
import 'templates/classic_waveform_painter.dart';
import 'templates/dot_spectrum_painter.dart';
import 'templates/dual_waveform_painter.dart';
import 'templates/equalizer_bars_painter.dart';
import 'templates/minimal_line_wave_painter.dart';
import 'templates/mirror_bars_painter.dart';
import 'templates/neon_wave_painter.dart';
import 'templates/pulse_circle_painter.dart';
import 'templates/vertical_frequency_bars_painter.dart';

/// Central lookup from a [VisualizerTemplateType] to its rendering
/// implementation. Add new templates here.
final Map<VisualizerTemplateType, VisualizerPainterDelegate>
visualizerRegistry = {
  VisualizerTemplateType.classicWaveform: ClassicWaveformPainter(),
  VisualizerTemplateType.equalizerBars: EqualizerBarsPainter(),
  VisualizerTemplateType.circularSpectrum: CircularSpectrumPainter(),
  VisualizerTemplateType.minimalLineWave: MinimalLineWavePainter(),
  VisualizerTemplateType.neonWave: NeonWavePainter(),
  VisualizerTemplateType.dualWaveform: DualWaveformPainter(),
  VisualizerTemplateType.dotSpectrum: DotSpectrumPainter(),
  VisualizerTemplateType.mirrorBars: MirrorBarsPainter(),
  VisualizerTemplateType.pulseCircle: PulseCirclePainter(),
  VisualizerTemplateType.verticalFrequencyBars: VerticalFrequencyBarsPainter(),
};

VisualizerPainterDelegate painterFor(VisualizerTemplateType type) {
  return visualizerRegistry[type] ?? EqualizerBarsPainter();
}
