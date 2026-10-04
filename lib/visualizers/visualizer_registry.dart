import '../models/visualizer_template.dart';
import 'templates/premium_visualizer_painters.dart';
import 'visualizer_painter_base.dart';

/// Central lookup from a [VisualizerTemplateType] to its rendering
/// implementation. The default and primary templates render dense FFT
/// spectrum/equalizer bars (not oscilloscope lines). Voice Wave and Horror
/// Wave intentionally remain line-style specialty templates.
final Map<VisualizerTemplateType, VisualizerPainterDelegate>
visualizerRegistry = {
  // Original 10 identifiers kept for old projects, remapped to professional
  // spectrum/equalizer renderers where appropriate.
  VisualizerTemplateType.classicWaveform: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.classic,
    barCount: 52,
    widthFactor: 0.50,
  ),
  VisualizerTemplateType.equalizerBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.dense,
    barCount: 80,
  ),
  VisualizerTemplateType.circularSpectrum: PremiumCirclePainter(
    shape: PremiumCircleShape.spectrum,
    count: 80,
  ),
  VisualizerTemplateType.minimalLineWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.thin,
    barCount: 72,
    widthFactor: 0.24,
  ),
  VisualizerTemplateType.neonWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.neon,
    barCount: 80,
  ),
  VisualizerTemplateType.dualWaveform: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.mirrored,
    barCount: 72,
  ),
  VisualizerTemplateType.dotSpectrum: PremiumCirclePainter(
    shape: PremiumCircleShape.dotSpectrum,
  ),
  VisualizerTemplateType.mirrorBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.mirrored,
    barCount: 80,
  ),
  VisualizerTemplateType.pulseCircle: PremiumCirclePainter(
    shape: PremiumCircleShape.pulseCircle,
  ),
  VisualizerTemplateType.verticalFrequencyBars: PremiumBarsPainter(
    barCount: 36,
    widthFactor: 0.56,
    anchor: PremiumBarsAnchor.vertical,
  ),

  // Former waveform names now use frequency-driven spectrum algorithms so
  // the gallery no longer shows many copies of a thin zigzag line.
  VisualizerTemplateType.smoothWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.dense,
    barCount: 80,
  ),
  VisualizerTemplateType.thickWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.rounded,
    barCount: 56,
    widthFactor: 0.50,
  ),
  VisualizerTemplateType.thinWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.thin,
    barCount: 88,
    widthFactor: 0.22,
  ),
  VisualizerTemplateType.doubleWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.mirrored,
    barCount: 76,
  ),
  VisualizerTemplateType.tripleWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.cinematic,
    barCount: 84,
  ),
  VisualizerTemplateType.mirrorWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.mirrored,
    barCount: 80,
  ),
  VisualizerTemplateType.filledWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.bottom,
    barCount: 80,
    widthFactor: 0.44,
  ),
  VisualizerTemplateType.glowWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.neon,
    barCount: 80,
  ),
  VisualizerTemplateType.pulseWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.cinematic,
    barCount: 64,
  ),
  VisualizerTemplateType.frequencyWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.dense,
    barCount: 96,
  ),
  VisualizerTemplateType.rainbowWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.rainbow,
    barCount: 88,
  ),
  VisualizerTemplateType.cinematicWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.cinematic,
    barCount: 84,
  ),
  VisualizerTemplateType.voiceWave: PremiumWavePainter(
    shape: PremiumWaveShape.voice,
    sampleCount: 72,
  ),

  // Equalizers.
  VisualizerTemplateType.classicBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.classic,
    barCount: 48,
    widthFactor: 0.55,
  ),
  VisualizerTemplateType.roundedBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.rounded,
    barCount: 64,
    widthFactor: 0.48,
  ),
  VisualizerTemplateType.thinBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.thin,
    barCount: 96,
    widthFactor: 0.20,
  ),
  VisualizerTemplateType.thickBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.rounded,
    barCount: 40,
    widthFactor: 0.65,
  ),
  VisualizerTemplateType.floatingBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.mirrored,
    barCount: 72,
    widthFactor: 0.34,
  ),
  VisualizerTemplateType.centerBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.mirrored,
    barCount: 80,
  ),
  VisualizerTemplateType.bottomBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.bottom,
    barCount: 80,
    widthFactor: 0.42,
  ),
  VisualizerTemplateType.topBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.top,
    barCount: 80,
    widthFactor: 0.42,
  ),
  VisualizerTemplateType.gradientBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.dense,
    barCount: 88,
  ),
  VisualizerTemplateType.spectrumBars: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.dense,
    barCount: 88,
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
    style: PremiumSpectrumStyle.thin,
    barCount: 72,
  ),
  VisualizerTemplateType.darkWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.neon,
    barCount: 72,
  ),
  VisualizerTemplateType.horrorWave: PremiumStoryPainter(
    PremiumStoryShape.horror,
  ),
  VisualizerTemplateType.cinematicGlow: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.cinematic,
    barCount: 84,
  ),
  VisualizerTemplateType.podcastWave: PremiumStoryPainter(
    PremiumStoryShape.podcast,
  ),
  VisualizerTemplateType.storyWave: PremiumSpectrumPainter(
    style: PremiumSpectrumStyle.bottom,
    barCount: 72,
  ),
  VisualizerTemplateType.centerPulse: PremiumStoryPainter(
    PremiumStoryShape.centerPulse,
  ),
  VisualizerTemplateType.bassPulse: PremiumStoryPainter(
    PremiumStoryShape.bassPulse,
  ),
};

VisualizerPainterDelegate painterFor(VisualizerTemplateType type) {
  return visualizerRegistry[type] ??
      visualizerRegistry[VisualizerTemplateType.spectrumBars]!;
}
