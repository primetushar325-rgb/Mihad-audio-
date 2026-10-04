/// Identifies one of the built-in, offline, audio-reactive visualizer
/// templates. The enum order is kept stable for backwards-compatible project
/// JSON; the gallery list below controls the visible order.
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
  // Primary requested equalizer set, shown first.
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.storyWave,
    displayName: 'Story Equalizer',
    description: 'Default narration bars: thin fixed-bottom sticks from real time-domain audio.',
    category: 'Story / Horror',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.horrorWave,
    displayName: 'Horror Equalizer',
    description: 'Crimson cinematic sticks with stronger real impact spikes for horror SFX.',
    category: 'Story / Horror',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.cinematicWave,
    displayName: 'Cinematic Equalizer',
    description: 'Hybrid waveform plus frequency response with soft premium glow.',
    category: 'Story / Horror',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.thinBars,
    displayName: 'Thin Bars',
    description: 'Ultra-dense very thin fixed-baseline spectrum sticks.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.neonWave,
    displayName: 'Neon Bars',
    description: 'Voice-reactive vertical neon sticks, not a connected wave line.',
    category: 'Story / Horror',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.rainbowWave,
    displayName: 'Rainbow Bars',
    description: 'Smooth rainbow spectrum sticks across the full width.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.spectrumBars,
    displayName: 'Spectrum Bars',
    description: 'Music FFT mode: dense upward-only frequency bars.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.classicBars,
    displayName: 'Classic Equalizer',
    description: 'Traditional radio equalizer layout with independent vertical sticks.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.bassPulse,
    displayName: 'Bass Equalizer',
    description: 'Low-frequency weighted bars for bass drops and cinematic impacts.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.minimalStory,
    displayName: 'Minimal Equalizer',
    description: 'Subtle white fixed-baseline sticks for clean story videos.',
    category: 'Story / Horror',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.voiceWave,
    displayName: 'Voice Wave',
    description: 'Optional traditional speech waveform line driven by real time-domain audio.',
    category: 'Waveforms',
  ),

  // Backwards-compatible original/premium entries.
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.classicWaveform,
    displayName: 'Classic Voice Bars',
    description: 'Legacy waveform slot remapped to real vertical voice bars.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.equalizerBars,
    displayName: 'Equalizer Bars',
    description: 'Original equalizer slot using the new fixed-bottom bar renderer.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.circularSpectrum,
    displayName: 'Circular Spectrum',
    description: 'Frequency bars radiating from a circle.',
    category: 'Circular',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.minimalLineWave,
    displayName: 'Minimal Voice Bars',
    description: 'Former line-wave slot remapped to subtle thin vertical sticks.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.dualWaveform,
    displayName: 'Mirrored Voice Bars',
    description: 'Optional mirrored voice-reactive sticks around the center line.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.dotSpectrum,
    displayName: 'Dot Spectrum',
    description: 'Bouncing dot frequency spectrum.',
    category: 'Circular',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.mirrorBars,
    displayName: 'Mirrored Spectrum',
    description: 'Optional top/bottom mirrored frequency bars.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.pulseCircle,
    displayName: 'Pulse Circle',
    description: 'Amplitude-driven pulse circle.',
    category: 'Circular',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.verticalFrequencyBars,
    displayName: 'Side Frequency Bars',
    description: 'Horizontal rows driven by frequency bands.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.smoothWave,
    displayName: 'Dense Wave Bars',
    description: 'Dense time-domain waveform bars for dialogue and story audio.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.thickWave,
    displayName: 'Rounded Voice Bars',
    description: 'Rounder voice bars for bold narration overlays.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.thinWave,
    displayName: 'Thin Wave Bars',
    description: 'Fine, tightly spaced waveform sticks for quiet storytelling.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.doubleWave,
    displayName: 'Double Mirror Bars',
    description: 'Optional mirrored time-domain bars for vocals and beats.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.tripleWave,
    displayName: 'Cinematic Hybrid Bars',
    description: 'Hybrid waveform/frequency bars with a soft cinematic beam.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.mirrorWave,
    displayName: 'Mirror Wave Bars',
    description: 'Optional mirrored waveform-bar renderer.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.filledWave,
    displayName: 'Filled Bar Glow',
    description: 'Rounded equalizer-style bars with fuller glow.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.glowWave,
    displayName: 'Glow Bars',
    description: 'Luminous vertical sticks for story overlays.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.pulseWave,
    displayName: 'Impact Wave Bars',
    description: 'Time-domain bars with stronger detected hit accents.',
    category: 'Waveforms',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.frequencyWave,
    displayName: 'Frequency Bars',
    description: 'FFT bars shaped by individual frequency bands.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.roundedBars,
    displayName: 'Rounded Bars',
    description: 'Soft rounded frequency bars with glow and gradient color.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.thickBars,
    displayName: 'Impact Bars',
    description: 'Stronger bass/impact equalizer bars for sound effects.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.floatingBars,
    displayName: 'Cinematic Bars',
    description: 'Hybrid cinematic equalizer bars with subtle glow.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.centerBars,
    displayName: 'Center Mirror Bars',
    description: 'Optional mirrored center-spine spectrum bars.',
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
    description: 'Bars hanging from a fixed top anchor.',
    category: 'Equalizers',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.gradientBars,
    displayName: 'Gradient Bars',
    description: 'Gradient frequency sticks using the selected colors.',
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
    type: VisualizerTemplateType.darkWave,
    displayName: 'Dark Horror Bars',
    description: 'Dark crimson/purple horror-story equalizer sticks.',
    category: 'Story / Horror',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.cinematicGlow,
    displayName: 'Cinematic Glow Bars',
    description: 'Large glowing hybrid bars over a subtle horizontal beam.',
    category: 'Story / Horror',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.podcastWave,
    displayName: 'Podcast Voice Bars',
    description: 'Broadcast-style voice bars for narration and dialogue.',
    category: 'Story / Horror',
  ),
  VisualizerTemplateInfo(
    type: VisualizerTemplateType.centerPulse,
    displayName: 'Center Pulse',
    description: 'Center glow and pulse rays controlled by amplitude.',
    category: 'Cinematic / Story',
  ),
];

VisualizerTemplateInfo visualizerTemplateInfo(VisualizerTemplateType type) {
  return kVisualizerTemplates.firstWhere((t) => t.type == type);
}
