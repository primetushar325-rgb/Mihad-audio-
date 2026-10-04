import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:mihad_audio/models/app_settings.dart';
import 'package:mihad_audio/models/export_settings.dart';
import 'package:mihad_audio/services/storage_service.dart';
import 'package:mihad_audio/state/app_settings_provider.dart';

import 'fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePathProvider fake;

  setUp(() {
    fake = FakePathProvider();
    PathProviderPlatform.instance = fake;
  });

  tearDown(() => fake.cleanUp());

  group('AppSettingsProvider', () {
    test('starts unloaded with built-in defaults', () {
      final provider = AppSettingsProvider(StorageService());
      expect(provider.isLoaded, isFalse);
      expect(
        provider.settings.defaultResolution,
        ExportResolutionPreset.res720p,
      );
      expect(provider.settings.defaultFps, ExportFpsPreset.fps30);
      expect(provider.settings.previewQuality, PreviewQuality.medium);
    });

    test(
      'load() with no saved file keeps the defaults but flips isLoaded',
      () async {
        final provider = AppSettingsProvider(StorageService());
        await provider.load();
        expect(provider.isLoaded, isTrue);
        expect(
          provider.settings.defaultResolution,
          ExportResolutionPreset.res720p,
        );
      },
    );

    test(
      'update() persists changes that a fresh provider instance can read back',
      () async {
        final provider = AppSettingsProvider(StorageService());
        await provider.load();

        await provider.update(
          (s) => AppSettings(
            defaultResolution: ExportResolutionPreset.res1080p,
            defaultFps: ExportFpsPreset.fps24,
            defaultPrimaryColorValue: 0xFFFF0066,
            previewQuality: PreviewQuality.high,
          ),
        );

        expect(
          provider.settings.defaultResolution,
          ExportResolutionPreset.res1080p,
        );

        final reopened = AppSettingsProvider(StorageService());
        await reopened.load();
        expect(
          reopened.settings.defaultResolution,
          ExportResolutionPreset.res1080p,
        );
        expect(reopened.settings.defaultFps, ExportFpsPreset.fps24);
        expect(reopened.settings.defaultPrimaryColorValue, 0xFFFF0066);
        expect(reopened.settings.previewQuality, PreviewQuality.high);
      },
    );

    test(
      'AppSettings.fromJson falls back to defaults for unknown enum values',
      () {
        final settings = AppSettings.fromJson(<String, dynamic>{
          'defaultResolution': 'not-a-real-preset',
          'defaultFps': 'also-bogus',
          'previewQuality': 'nonsense',
        });

        expect(settings.defaultResolution, ExportResolutionPreset.res720p);
        expect(settings.defaultFps, ExportFpsPreset.fps30);
        expect(settings.previewQuality, PreviewQuality.medium);
        // Primary color still falls back to the brand default.
        expect(settings.defaultPrimaryColorValue, 0xFF00E5A8);
      },
    );

    test('AppSettings round-trips through toJson/fromJson', () {
      final original = AppSettings(
        defaultResolution: ExportResolutionPreset.original,
        defaultFps: ExportFpsPreset.source,
        defaultPrimaryColorValue: 0xFF112233,
        previewQuality: PreviewQuality.low,
      );

      final restored = AppSettings.fromJson(original.toJson());

      expect(restored.defaultResolution, original.defaultResolution);
      expect(restored.defaultFps, original.defaultFps);
      expect(
        restored.defaultPrimaryColorValue,
        original.defaultPrimaryColorValue,
      );
      expect(restored.previewQuality, original.previewQuality);
    });
  });
}
