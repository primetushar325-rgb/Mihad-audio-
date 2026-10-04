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
        barWidth: 9.5,
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
      expect(restored.barWidth, original.barWidth);
      expect(restored.alignment, original.alignment);
      expect(restored.aspectRatio, original.aspectRatio);
    });

    test('fromJson falls back to sane defaults for malformed data', () {
      final restored = VisualizerSettings.fromJson({
        'template': 'not_a_real_template',
        'alignment': 'nope',
        'aspectRatio': 'nope',
      });

      expect(restored.template, VisualizerTemplateType.equalizerBars);
      expect(restored.colorMode, VisualizerColorMode.gradient);
      expect(restored.backgroundOpacity, 0.0);
      expect(restored.alignment, VisualizerAlignment.center);
      expect(restored.aspectRatio, ExportAspectRatio.ratio16x9);
    });

    test('copyWith only changes the specified fields', () {
      final original = VisualizerSettings();
      final changed = original.copyWith(opacity: 0.2, barWidth: 12);

      expect(changed.opacity, 0.2);
      expect(changed.barWidth, 12);
      expect(changed.template, original.template);
      expect(changed.posX, original.posX);
    });

    test('resetAppearance restores defaults but keeps template and aspect', () {
      final customized = VisualizerSettings(
        template: VisualizerTemplateType.pulseCircle,
        aspectRatio: ExportAspectRatio.ratio1x1,
        opacity: 0.1,
        glowIntensity: 0.9,
        barWidth: 18,
      );

      final reset = customized.resetAppearance();

      expect(reset.template, VisualizerTemplateType.pulseCircle);
      expect(reset.aspectRatio, ExportAspectRatio.ratio1x1);
      expect(reset.opacity, 1.0);
      expect(reset.barWidth, 6.0);
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
