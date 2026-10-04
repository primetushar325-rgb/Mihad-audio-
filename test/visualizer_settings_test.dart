import 'package:flutter_test/flutter_test.dart';
import 'package:mihad_audio/models/visualizer_settings.dart';
import 'package:mihad_audio/models/visualizer_template.dart';

void main() {
  group('VisualizerSettings', () {
    test('toJson/fromJson round-trips every field', () {
      final original = VisualizerSettings(
        template: VisualizerTemplateType.neonWave,
        posX: 0.12,
        posY: 0.34,
        width: 0.5,
        height: 0.22,
        primaryColorValue: 0xFF112233,
        secondaryColorValue: 0xFF445566,
        colorMode: VisualizerColorMode.random,
        backgroundColorValue: 0xFF010203,
        backgroundOpacity: 0.66,
        cornerRadius: 0.42,
        borderEnabled: true,
        borderColorValue: 0xFF778899,
        borderOpacity: 0.44,
        borderWidth: 3.5,
        opacity: 0.77,
        glowIntensity: 0.5,
        sensitivity: 1.4,
        barCount: 72,
        density: VisualizerDensity.ultra,
        smoothing: 0.62,
        waveHeight: 0.83,
        impactSensitivity: 0.74,
        attack: 0.91,
        release: 0.49,
        mirrored: true,
        centerLineEnabled: false,
        barWidth: 3.5,
        alignment: VisualizerAlignment.right,
        aspectRatio: ExportAspectRatio.ratio9x16,
      );

      final restored = VisualizerSettings.fromJson(original.toJson());

      expect(restored.template, original.template);
      expect(restored.posX, original.posX);
      expect(restored.posY, original.posY);
      expect(restored.width, original.width);
      expect(restored.height, original.height);
      expect(restored.primaryColorValue, original.primaryColorValue);
      expect(restored.secondaryColorValue, original.secondaryColorValue);
      expect(restored.colorMode, original.colorMode);
      expect(restored.backgroundColorValue, original.backgroundColorValue);
      expect(restored.backgroundOpacity, original.backgroundOpacity);
      expect(restored.cornerRadius, original.cornerRadius);
      expect(restored.borderEnabled, original.borderEnabled);
      expect(restored.borderColorValue, original.borderColorValue);
      expect(restored.borderOpacity, original.borderOpacity);
      expect(restored.borderWidth, original.borderWidth);
      expect(restored.opacity, original.opacity);
      expect(restored.waveOpacity, original.waveOpacity);
      expect(restored.glowIntensity, original.glowIntensity);
      expect(restored.sensitivity, original.sensitivity);
      expect(restored.barCount, original.barCount);
      expect(restored.density, original.density);
      expect(restored.smoothing, original.smoothing);
      expect(restored.waveHeight, original.waveHeight);
      expect(restored.impactSensitivity, original.impactSensitivity);
      expect(restored.attack, original.attack);
      expect(restored.release, original.release);
      expect(restored.mirrored, original.mirrored);
      expect(restored.centerLineEnabled, original.centerLineEnabled);
      expect(restored.barWidth, original.barWidth);
      expect(restored.alignment, original.alignment);
      expect(restored.aspectRatio, original.aspectRatio);
    });

    test('fromJson falls back to story equalizer defaults for malformed data', () {
      final restored = VisualizerSettings.fromJson({
        'template': 'not_a_real_template',
        'alignment': 'nope',
        'aspectRatio': 'nope',
      });

      expect(restored.template, VisualizerTemplateType.storyWave);
      expect(restored.colorMode, VisualizerColorMode.gradient);
      expect(restored.backgroundOpacity, 0.0);
      expect(restored.density, VisualizerDensity.high);
      expect(restored.mirrored, isFalse);
      expect(restored.centerLineEnabled, isTrue);
      expect(restored.alignment, VisualizerAlignment.center);
      expect(restored.aspectRatio, ExportAspectRatio.ratio16x9);
    });

    test('copyWith only changes the specified fields', () {
      final original = VisualizerSettings();
      final changed = original.copyWith(opacity: 0.2, barWidth: 3);

      expect(changed.opacity, 0.2);
      expect(changed.barWidth, 3);
      expect(changed.template, original.template);
      expect(changed.posX, original.posX);
    });

    test('resetAppearance restores the default story equalizer', () {
      final customized = VisualizerSettings(
        template: VisualizerTemplateType.pulseCircle,
        aspectRatio: ExportAspectRatio.ratio1x1,
        opacity: 0.1,
        glowIntensity: 0.9,
        barWidth: 5,
        mirrored: true,
      );

      final reset = customized.resetAppearance();

      expect(reset.template, VisualizerTemplateType.storyWave);
      expect(reset.aspectRatio, ExportAspectRatio.ratio16x9);
      expect(reset.opacity, 1.0);
      expect(reset.barWidth, 1.6);
      expect(reset.mirrored, isFalse);
    });

    test('horror preset configures upward-only crimson impact bars', () {
      final preset = VisualizerSettings().applyTemplatePreset(
        VisualizerTemplateType.horrorWave,
      );

      expect(preset.template, VisualizerTemplateType.horrorWave);
      expect(preset.primaryColorValue, 0xFFE11D48);
      expect(preset.secondaryColorValue, 0xFF3B0764);
      expect(preset.impactSensitivity, greaterThanOrEqualTo(0.65));
      expect(preset.mirrored, isFalse);
      expect(preset.centerLineEnabled, isTrue);
    });
  });

  group('ExportAspectRatio', () {
    test('value returns the correct ratio for fixed aspects', () {
      expect(ExportAspectRatio.ratio16x9.value, closeTo(16 / 9, 0.0001));
      expect(ExportAspectRatio.ratio9x16.value, closeTo(9 / 16, 0.0001));
      expect(ExportAspectRatio.ratio1x1.value, 1.0);
      expect(ExportAspectRatio.original.value, isNull);
    });
  });
}
