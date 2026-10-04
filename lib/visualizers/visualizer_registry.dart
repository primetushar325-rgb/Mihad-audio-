import '../models/visualizer_template.dart';
import 'templates/premium_visualizer_painters.dart';
import 'visualizer_painter_base.dart';

/// Central lookup from a [VisualizerTemplateType] to its rendering
/// implementation.
///
/// The primary Story/Horror visualizers are fixed-bottom vertical-stick
/// equalizers driven by real time-domain waveform/envelope data. Music
/// templates use independent FFT/frequency bars. Voice Wave is the only
/// intentional connected waveform-line specialty template.
final Map<VisualizerTemplateType, VisualizerPainterDelegate>
visualizerRegistry = {
  // Original 10 identifiers kept for old projects, remapped away from the
  // wrong default green wire/zigzag look.
  VisualizerTemplateType.classicWaveform: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.classic,
    source: PremiumSpectrumSource.waveform,
    barCount: 72,
    widthFactor: 0.26,
  ),
  VisualizerTemplateType.equalizerBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.spectrum,
    source: PremiumSpectrumSource.spectrum,
    barCount: 96,
  ),
  VisualizerTemplateType.circularSpectrum: PremiumCirclePainter(
    shape: PremiumCircleShape.spectrum,
    count: 80,
  ),
  VisualizerTemplateType.minimalLineWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.minimal,
    source: PremiumSpectrumSource.waveform,
    barCount: 72,
    widthFactor: 0.18,
  ),
  VisualizerTemplateType.neonWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.neon,
    source: PremiumSpectrumSource.waveform,
    barCount: 92,
    widthFactor: 0.24,
  ),
  VisualizerTemplateType.dualWaveform: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.mirrored,
    source: PremiumSpectrumSource.waveform,
    barCount: 88,
  ),
  VisualizerTemplateType.dotSpectrum: PremiumCirclePainter(
    shape: PremiumCircleShape.dotSpectrum,
  ),
  VisualizerTemplateType.mirrorBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.mirrored,
    source: PremiumSpectrumSource.spectrum,
    barCount: 96,
  ),
  VisualizerTemplateType.pulseCircle: PremiumCirclePainter(
    shape: PremiumCircleShape.pulseCircle,
  ),
  VisualizerTemplateType.verticalFrequencyBars: PremiumBarsPainter(
    barCount: 36,
    widthFactor: 0.56,
    anchor: PremiumBarsAnchor.vertical,
  ),

  // Premium waveform/story names now render as independent vertical sticks
  // using real time-domain waveform data unless explicitly Voice Wave.
  VisualizerTemplateType.smoothWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.story,
    source: PremiumSpectrumSource.waveform,
    barCount: 88,
  ),
  VisualizerTemplateType.thickWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.rounded,
    source: PremiumSpectrumSource.waveform,
    barCount: 64,
    widthFactor: 0.38,
  ),
  VisualizerTemplateType.thinWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.thin,
    source: PremiumSpectrumSource.waveform,
    barCount: 100,
    widthFactor: 0.18,
  ),
  VisualizerTemplateType.doubleWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.mirrored,
    source: PremiumSpectrumSource.waveform,
    barCount: 88,
  ),
  VisualizerTemplateType.tripleWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.cinematic,
    source: PremiumSpectrumSource.cinematic,
    barCount: 96,
  ),
  VisualizerTemplateType.mirrorWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.mirrored,
    source: PremiumSpectrumSource.waveform,
    barCount: 92,
  ),
  VisualizerTemplateType.filledWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.rounded,
    source: PremiumSpectrumSource.waveform,
    barCount: 80,
    widthFactor: 0.34,
  ),
  VisualizerTemplateType.glowWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.neon,
    source: PremiumSpectrumSource.waveform,
    barCount: 92,
  ),
  VisualizerTemplateType.pulseWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.impact,
    source: PremiumSpectrumSource.waveform,
    barCount: 92,
  ),
  VisualizerTemplateType.frequencyWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.spectrum,
    source: PremiumSpectrumSource.spectrum,
    barCount: 104,
  ),
  VisualizerTemplateType.rainbowWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.rainbow,
    source: PremiumSpectrumSource.spectrum,
    barCount: 104,
  ),
  VisualizerTemplateType.cinematicWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.cinematic,
    source: PremiumSpectrumSource.cinematic,
    barCount: 96,
  ),
  VisualizerTemplateType.voiceWave: PremiumWavePainter(
    shape: PremiumWaveShape.voice,
    sampleCount: 72,
  ),

  // Equalizers.
  VisualizerTemplateType.classicBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.classic,
    source: PremiumSpectrumSource.spectrum,
    barCount: 72,
    widthFactor: 0.32,
  ),
  VisualizerTemplateType.roundedBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.rounded,
    source: PremiumSpectrumSource.spectrum,
    barCount: 88,
    widthFactor: 0.34,
  ),
  VisualizerTemplateType.thinBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.thin,
    source: PremiumSpectrumSource.spectrum,
    barCount: 112,
    widthFactor: 0.17,
  ),
  VisualizerTemplateType.thickBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.bass,
    source: PremiumSpectrumSource.spectrum,
    barCount: 64,
    widthFactor: 0.42,
  ),
  VisualizerTemplateType.floatingBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.cinematic,
    source: PremiumSpectrumSource.cinematic,
    barCount: 88,
  ),
  VisualizerTemplateType.centerBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.mirrored,
    source: PremiumSpectrumSource.spectrum,
    barCount: 96,
  ),
  VisualizerTemplateType.bottomBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.bottom,
    source: PremiumSpectrumSource.spectrum,
    barCount: 96,
    widthFactor: 0.28,
  ),
  VisualizerTemplateType.topBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.top,
    source: PremiumSpectrumSource.spectrum,
    barCount: 96,
    widthFactor: 0.28,
  ),
  VisualizerTemplateType.gradientBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.spectrum,
    source: PremiumSpectrumSource.spectrum,
    barCount: 100,
  ),
  VisualizerTemplateType.spectrumBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.spectrum,
    source: PremiumSpectrumSource.spectrum,
    barCount: 100,
  ),

  // Circular.
  VisualizerTemplateType.radialSpectrum: PremiumCirclePainter(
    shape: PremiumCircleShape.radial,
    count: 96,
  ),
  VisualizerTemplateType.doubleRing: PremiumCirclePainter(
    shape: PremiumCircleShape.doubleRing,
  ),
  VisualizerTemplateType.pulseRing: PremiumCirclePainter(
    shape: PremiumCircleShape.pulseRing,
  ),
  VisualizerTemplateType.dotRing: PremiumCirclePainter(
    shape: PremiumCircleShape.dotRing,
    count: 72,
  ),
  VisualizerTemplateType.audioRing: PremiumCirclePainter(
    shape: PremiumCircleShape.audioRing,
    count: 72,
  ),

  // Cinematic/story.
  VisualizerTemplateType.minimalStory: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.minimal,
    source: PremiumSpectrumSource.waveform,
    barCount: 72,
    widthFactor: 0.16,
  ),
  VisualizerTemplateType.darkWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.horror,
    source: PremiumSpectrumSource.waveform,
    barCount: 96,
    widthFactor: 0.20,
  ),
  VisualizerTemplateType.horrorWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.horror,
    source: PremiumSpectrumSource.waveform,
    barCount: 96,
    widthFactor: 0.20,
  ),
  VisualizerTemplateType.cinematicGlow: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.cinematic,
    source: PremiumSpectrumSource.cinematic,
    barCount: 96,
  ),
  VisualizerTemplateType.podcastWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.story,
    source: PremiumSpectrumSource.waveform,
    barCount: 84,
    widthFactor: 0.24,
  ),
  VisualizerTemplateType.storyWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.story,
    source: PremiumSpectrumSource.waveform,
    barCount: 88,
    widthFactor: 0.22,
  ),
  VisualizerTemplateType.centerPulse: PremiumStoryPainter(
    PremiumStoryShape.centerPulse,
  ),
  VisualizerTemplateType.bassPulse: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.bass,
    source: PremiumSpectrumSource.spectrum,
    barCount: 72,
    widthFactor: 0.36,
  ),
};

VisualizerPainterDelegate painterFor(VisualizerTemplateType type) {
  return visualizerRegistry[type] ?? visualizerRegistry[VisualizerTemplateType.storyWave]!;
}
