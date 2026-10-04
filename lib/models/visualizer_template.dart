/// Identifies one of the built-in, offline, audio-reactive visualizer
/// templates. The enum order defines the order shown in the template
/// gallery.
enum VisualizerTemplateType {
  classicWaveform,
  equalizerBars,
  circularSpectrum,
  minimalLineWave,
  neonWave,
  dualWaveform,
  dotSpectrum,
  mirrorBars,
  pulseCircle,
  verticalFrequencyBars,
}

/// Static metadata describing a visualizer template for display in the
/// gallery. The actual rendering logic lives in
/// `lib/visualizers/templates/*` and is looked up through
/// `visualizer_registry.dart`.
class VisualizerTemplateInfo {
  final VisualizerTemplateType type;
  final String displayName;
  final String description;

  const VisualizerTemplateInfo({
    required this.type,
    required this.displayName,
    required this.description,
  });
}

const List<VisualizerTemplateInfo> kVisualizerTemplates = [
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.classicWaveform,
    displayName: 'Classic Waveform',
    description: 'Smooth oscilloscope-style waveform line.',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.equalizerBars,
    displayName: 'Equalizer Bars',
    description: 'Classic vertical frequency bar equalizer.',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.circularSpectrum,
    displayName: 'Circular Spectrum',
    description: 'Frequency bars radiating from a circle.',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.minimalLineWave,
    displayName: 'Minimal Line Wave',
    description: 'A thin, minimal single-line waveform.',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.neonWave,
    displayName: 'Neon Wave',
    description: 'Glowing neon-style animated waveform.',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.dualWaveform,
    displayName: 'Dual Waveform',
    description: 'Two mirrored waveforms in different colors.',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.dotSpectrum,
    displayName: 'Dot Spectrum',
    description: 'Bouncing dots representing frequency bands.',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.mirrorBars,
    displayName: 'Mirror Bars',
    description: 'Bars mirrored above and below a center line.',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.pulseCircle,
    displayName: 'Pulse Circle',
    description: 'A glowing circle that pulses with amplitude.',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.verticalFrequencyBars,
    displayName: 'Vertical Frequency Bars',
    description: 'Frequency bars arranged in a vertical column.',
  ),
];

VisualizerTemplateInfo visualizerTemplateInfo(VisualizerTemplateType type) {
  return kVisualizerTemplates.firstWhere((t) => t.type == type);
}
