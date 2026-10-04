import '../models/visualizer_template.dart';
import 'templates/premium_visualizer_painters.dart';
import 'visualizer_painter_base.dart';

/// Central lookup from a [VisualizerTemplateType] to its rendering
/// implementation. The original 10 template enum values stay registered,
/// and premium templates are added here without changing the app's painter
/// architecture.
final Map<VisualizerTemplateType, VisualizerPainterDelegate>
visualizerRegistry = {
  // Original 10, now rendered through the premium vector painters.
  VisualizerTemplateType.classicWaveform: PremiumWavePainter(
    shape: PremiumWaveShape.smooth,
  ),
  VisualizerTemplateType.equalizerBars: PremiumBarsPainter(
    barCount: 28,
    widthFactor: 0.58,
    anchor: PremiumBarsAnchor.bottom,
  ),
  VisualizerTemplateType.circularSpectrum: PremiumCirclePainter(
    shape: PremiumCircleShape.spectrum,
  ),
  VisualizerTemplateType.minimalLineWave: PremiumWavePainter(
    shape: PremiumWaveShape.thin,
    sampleCount: 44,
  ),
  VisualizerTemplateType.neonWave: PremiumWavePainter(
    shape: PremiumWaveShape.neon,
    sampleCount: 58,
  ),
  VisualizerTemplateType.dualWaveform: PremiumWavePainter(
    shape: PremiumWaveShape.double,
    sampleCount: 44,
  ),
  VisualizerTemplateType.dotSpectrum: PremiumCirclePainter(
    shape: PremiumCircleShape.dotSpectrum,
  ),
  VisualizerTemplateType.mirrorBars: PremiumBarsPainter(
    barCount: 30,
    widthFactor: 0.54,
    anchor: PremiumBarsAnchor.mirror,
  ),
  VisualizerTemplateType.pulseCircle: PremiumCirclePainter(
    shape: PremiumCircleShape.pulseCircle,
  ),
  VisualizerTemplateType.verticalFrequencyBars: PremiumBarsPainter(
    barCount: 22,
    widthFactor: 0.62,
    anchor: PremiumBarsAnchor.vertical,
  ),

  // Waveforms.
  VisualizerTemplateType.smoothWave: PremiumWavePainter(
    shape: PremiumWaveShape.smooth,
    sampleCount: 64,
  ),
  VisualizerTemplateType.thickWave: PremiumWavePainter(
    shape: PremiumWaveShape.thick,
    sampleCount: 54,
  ),
  VisualizerTemplateType.thinWave: PremiumWavePainter(
    shape: PremiumWaveShape.thin,
    sampleCount: 64,
  ),
  VisualizerTemplateType.doubleWave: PremiumWavePainter(
    shape: PremiumWaveShape.double,
    sampleCount: 48,
  ),
  VisualizerTemplateType.tripleWave: PremiumWavePainter(
    shape: PremiumWaveShape.triple,
    sampleCount: 42,
  ),
  VisualizerTemplateType.mirrorWave: PremiumWavePainter(
    shape: PremiumWaveShape.mirror,
    sampleCount: 58,
  ),
  VisualizerTemplateType.filledWave: PremiumWavePainter(
    shape: PremiumWaveShape.filled,
    sampleCount: 58,
  ),
  VisualizerTemplateType.glowWave: PremiumWavePainter(
    shape: PremiumWaveShape.glow,
    sampleCount: 62,
  ),
  VisualizerTemplateType.pulseWave: PremiumWavePainter(
    shape: PremiumWaveShape.pulse,
    sampleCount: 54,
  ),
  VisualizerTemplateType.frequencyWave: PremiumWavePainter(
    shape: PremiumWaveShape.frequency,
    sampleCount: 96,
  ),
  VisualizerTemplateType.rainbowWave: PremiumWavePainter(
    shape: PremiumWaveShape.rainbow,
    sampleCount: 72,
  ),
  VisualizerTemplateType.cinematicWave: PremiumWavePainter(
    shape: PremiumWaveShape.cinematic,
    sampleCount: 72,
  ),
  VisualizerTemplateType.voiceWave: PremiumWavePainter(
    shape: PremiumWaveShape.voice,
    sampleCount: 72,
  ),

  // Equalizers.
  VisualizerTemplateType.classicBars: PremiumBarsPainter(
    barCount: 30,
    widthFactor: 0.56,
  ),
  VisualizerTemplateType.roundedBars: PremiumBarsPainter(
    barCount: 32,
    widthFactor: 0.64,
  ),
  VisualizerTemplateType.thinBars: PremiumBarsPainter(
    barCount: 54,
    widthFactor: 0.32,
  ),
  VisualizerTemplateType.thickBars: PremiumBarsPainter(
    barCount: 18,
    widthFactor: 0.72,
  ),
  VisualizerTemplateType.floatingBars: PremiumBarsPainter(
    barCount: 30,
    widthFactor: 0.50,
    anchor: PremiumBarsAnchor.floating,
  ),
  VisualizerTemplateType.centerBars: PremiumBarsPainter(
    barCount: 34,
    widthFactor: 0.48,
    anchor: PremiumBarsAnchor.center,
  ),
  VisualizerTemplateType.bottomBars: PremiumBarsPainter(
    barCount: 36,
    widthFactor: 0.52,
    anchor: PremiumBarsAnchor.bottom,
  ),
  VisualizerTemplateType.topBars: PremiumBarsPainter(
    barCount: 36,
    widthFactor: 0.52,
    anchor: PremiumBarsAnchor.top,
  ),
  VisualizerTemplateType.gradientBars: PremiumBarsPainter(
    barCount: 34,
    widthFactor: 0.56,
    spectrumCaps: false,
  ),
  VisualizerTemplateType.spectrumBars: PremiumBarsPainter(
    barCount: 56,
    widthFactor: 0.36,
    spectrumCaps: true,
    rainbow: true,
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
  VisualizerTemplateType.minimalStory: PremiumStoryPainter(
    PremiumStoryShape.minimal,
  ),
  VisualizerTemplateType.darkWave: PremiumStoryPainter(PremiumStoryShape.dark),
  VisualizerTemplateType.horrorWave: PremiumStoryPainter(
    PremiumStoryShape.horror,
  ),
  VisualizerTemplateType.cinematicGlow: PremiumStoryPainter(
    PremiumStoryShape.cinematicGlow,
  ),
  VisualizerTemplateType.podcastWave: PremiumStoryPainter(
    PremiumStoryShape.podcast,
  ),
  VisualizerTemplateType.storyWave: PremiumStoryPainter(PremiumStoryShape.story),
  VisualizerTemplateType.centerPulse: PremiumStoryPainter(
    PremiumStoryShape.centerPulse,
  ),
  VisualizerTemplateType.bassPulse: PremiumStoryPainter(
    PremiumStoryShape.bassPulse,
  ),
};

VisualizerPainterDelegate painterFor(VisualizerTemplateType type) {
  return visualizerRegistry[type] ?? visualizerRegistry[VisualizerTemplateType.equalizerBars]!;
}
