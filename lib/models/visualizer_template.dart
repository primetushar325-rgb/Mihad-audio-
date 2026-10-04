/// Identifies one of the built-in, offline, audio-reactive visualizer
/// templates. The enum order defines the order shown in the template
/// gallery. The original 10 entries remain intact for backwards-compatible
/// project JSON; new entries extend the gallery without invalidating old
/// saved template names.
enum VisualizerTemplateType {
  // Original 10 templates.
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

  // Premium waveform templates.
  smoothWave,
  thickWave,
  thinWave,
  doubleWave,
  tripleWave,
  mirrorWave,
  filledWave,
  glowWave,
  pulseWave,
  frequencyWave,
  rainbowWave,
  cinematicWave,
  voiceWave,

  // Premium equalizer templates.
  classicBars,
  roundedBars,
  thinBars,
  thickBars,
  floatingBars,
  centerBars,
  bottomBars,
  topBars,
  gradientBars,
  spectrumBars,

  // Premium circular templates.
  radialSpectrum,
  doubleRing,
  pulseRing,
  dotRing,
  audioRing,

  // Cinematic/story templates.
  minimalStory,
  darkWave,
  horrorWave,
  cinematicGlow,
  podcastWave,
  storyWave,
  centerPulse,
  bassPulse,
}

/// Static metadata describing a visualizer template for display in the
/// gallery. The actual rendering logic lives in
/// `lib/visualizers/templates/*` and is looked up through
/// `visualizer_registry.dart`.
class VisualizerTemplateInfo {
  final VisualizerTemplateType type;
  final String displayName;
  final String description;
  final String category;

  const VisualizerTemplateInfo({
    required this.type,
    required this.displayName,
    required this.description,
    required this.category,
  });
}

const List<VisualizerTemplateInfo> kVisualizerTemplates = [
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.classicWaveform,
    displayName: 'Classic Waveform',
    description: 'Original smooth oscilloscope-style waveform line.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.equalizerBars,
    displayName: 'Equalizer Bars',
    description: 'Original classic vertical frequency bar equalizer.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.circularSpectrum,
    displayName: 'Circular Spectrum',
    description: 'Original frequency bars radiating from a circle.',
    category: 'Circular',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.minimalLineWave,
    displayName: 'Minimal Line Wave',
    description: 'Original understated single-line waveform.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.neonWave,
    displayName: 'Neon Wave',
    description: 'Original neon waveform with a brighter premium glow.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.dualWaveform,
    displayName: 'Dual Waveform',
    description: 'Original two-color mirrored waveform.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.dotSpectrum,
    displayName: 'Dot Spectrum',
    description: 'Original bouncing dot frequency spectrum.',
    category: 'Circular',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.mirrorBars,
    displayName: 'Mirror Bars',
    description: 'Original bars mirrored around the center line.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.pulseCircle,
    displayName: 'Pulse Circle',
    description: 'Original amplitude-driven pulse circle.',
    category: 'Circular',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.verticalFrequencyBars,
    displayName: 'Vertical Frequency Bars',
    description: 'Original horizontal rows driven by frequency bands.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.smoothWave,
    displayName: 'Smooth Wave',
    description: 'Fluid curved waveform with soft highlights.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.thickWave,
    displayName: 'Thick Wave',
    description: 'Bold waveform stroke for high-contrast edits.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.thinWave,
    displayName: 'Thin Wave',
    description: 'Fine waveform for clean minimal videos.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.doubleWave,
    displayName: 'Double Wave',
    description: 'Two layered waves reacting to the same audio snapshot.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.tripleWave,
    displayName: 'Triple Wave',
    description: 'Three stacked audio-reactive wave lanes.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.mirrorWave,
    displayName: 'Mirror Wave',
    description: 'Symmetric top/bottom waveform for vocals and beats.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.filledWave,
    displayName: 'Filled Wave',
    description: 'Gradient-filled waveform silhouette.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.glowWave,
    displayName: 'Glow Wave',
    description: 'Large soft luminous wave for story overlays.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.pulseWave,
    displayName: 'Pulse Wave',
    description: 'Wave thickness and energy pulse with amplitude.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.frequencyWave,
    displayName: 'Frequency Wave',
    description: 'Dense wave samples shaped by individual frequency bands.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.rainbowWave,
    displayName: 'Rainbow Wave',
    description: 'Multicolor spectrum wave built with vector gradients.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.cinematicWave,
    displayName: 'Cinematic Wave',
    description: 'Wide cinematic audio trace with glow and center beam.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.voiceWave,
    displayName: 'Voice Wave',
    description: 'Speech-focused waveform with precise vertical peaks.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.classicBars,
    displayName: 'Classic Bars',
    description: 'Premium version of the classic bottom equalizer.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.roundedBars,
    displayName: 'Rounded Bars',
    description: 'Soft rounded bars with glow and gradient color.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.thinBars,
    displayName: 'Thin Bars',
    description: 'High-count thin frequency bars.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.thickBars,
    displayName: 'Thick Bars',
    description: 'Chunky equalizer bars for bass-heavy tracks.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.floatingBars,
    displayName: 'Floating Bars',
    description: 'Bars floating around the vertical center.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.centerBars,
    displayName: 'Center Bars',
    description: 'Bars expanding from a central spine.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.bottomBars,
    displayName: 'Bottom Bars',
    description: 'Grounded lower-third equalizer layout.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.topBars,
    displayName: 'Top Bars',
    description: 'Bars hanging from the top edge.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.gradientBars,
    displayName: 'Gradient Bars',
    description: 'Each bar is filled by the selected gradient mode.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.spectrumBars,
    displayName: 'Spectrum Bars',
    description: 'Dense spectrum analyzer with peak caps.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.radialSpectrum,
    displayName: 'Radial Spectrum',
    description: 'High-density radial bars around the center.',
    category: 'Circular',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.doubleRing,
    displayName: 'Double Ring',
    description: 'Two audio-reactive circular rings.',
    category: 'Circular',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.pulseRing,
    displayName: 'Pulse Ring',
    description: 'Breathing amplitude ring with inner glow.',
    category: 'Circular',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.dotRing,
    displayName: 'Dot Ring',
    description: 'Circular constellation of frequency dots.',
    category: 'Circular',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.audioRing,
    displayName: 'Audio Ring',
    description: 'Modern podcast-style audio ring.',
    category: 'Circular',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.minimalStory,
    displayName: 'Minimal Story',
    description: 'Clean social story waveform with a subtle base line.',
    category: 'Cinematic / Story',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.darkWave,
    displayName: 'Dark Wave',
    description: 'Moody low-light wave with deep glow.',
    category: 'Cinematic / Story',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.horrorWave,
    displayName: 'Horror Wave',
    description: 'Sharp jagged audio wave for suspense edits.',
    category: 'Cinematic / Story',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.cinematicGlow,
    displayName: 'Cinematic Glow',
    description: 'Large glowing center pulse over a horizontal beam.',
    category: 'Cinematic / Story',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.podcastWave,
    displayName: 'Podcast Wave',
    description: 'Broadcast-style voice bars and center badge.',
    category: 'Cinematic / Story',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.storyWave,
    displayName: 'Story Wave',
    description: 'Rounded lower-third waveform built for reels/stories.',
    category: 'Cinematic / Story',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.centerPulse,
    displayName: 'Center Pulse',
    description: 'Center glow and pulse rays controlled by amplitude.',
    category: 'Cinematic / Story',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.bassPulse,
    displayName: 'Bass Pulse',
    description: 'Low-frequency pulse blocks for beat drops.',
    category: 'Cinematic / Story',
  ),
];

VisualizerTemplateInfo visualizerTemplateInfo(VisualizerTemplateType type) {
  return kVisualizerTemplates.firstWhere((t) => t.type == type);
}
