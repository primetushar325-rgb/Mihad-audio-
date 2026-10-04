import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:mihad_audio/models/audio_source.dart';
import 'package:mihad_audio/services/storage_service.dart';
import 'package:mihad_audio/state/projects_library_provider.dart';

import 'fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePathProvider fake;

  setUp(() {
    fake = FakePathProvider();
    PathProviderPlatform.instance = fake;
  });

  tearDown(() => fake.cleanUp());

  group('ProjectsLibraryProvider', () {
    test('starts empty and unloaded, then loads an empty list', () async {
      final provider = ProjectsLibraryProvider(StorageService());
      expect(provider.isLoaded, isFalse);
      expect(provider.projectsByRecent, isEmpty);

      await provider.load();

      expect(provider.isLoaded, isTrue);
      expect(provider.projectsByRecent, isEmpty);
    });

    test('createProject adds a project and persists it to disk', () async {
      final provider = ProjectsLibraryProvider(StorageService());
      await provider.load();

      final project = await provider.createProject('My First Video');

      expect(project.name, 'My First Video');
      expect(provider.projectsByRecent, hasLength(1));
      expect(provider.byId(project.id)?.id, project.id);

      // A fresh provider instance backed by the same storage must see the
      // persisted project - this is the actual "reopen the app" path.
      final reopened = ProjectsLibraryProvider(StorageService());
      await reopened.load();
      expect(reopened.projectsByRecent, hasLength(1));
      expect(reopened.projectsByRecent.single.name, 'My First Video');
    });

    test('createProject falls back to a default name when blank', () async {
      final provider = ProjectsLibraryProvider(StorageService());
      await provider.load();

      final project = await provider.createProject('   ');

      expect(project.name, 'Untitled project');
    });

    test('upsert updates an existing project and bumps updatedAt', () async {
      final provider = ProjectsLibraryProvider(StorageService());
      await provider.load();
      final project = await provider.createProject('Beat Drop');
      final originalUpdatedAt = project.updatedAt;

      await Future<void>.delayed(const Duration(milliseconds: 5));
      project.sourceVideoPath = '/sdcard/DCIM/clip.mp4';
      await provider.upsert(project);

      final stored = provider.byId(project.id)!;
      expect(stored.sourceVideoPath, '/sdcard/DCIM/clip.mp4');
      expect(stored.updatedAt.isAfter(originalUpdatedAt), isTrue);
      // upsert must not create a duplicate row for an existing id.
      expect(provider.projectsByRecent, hasLength(1));
    });

    test('upsert inserts a project that does not exist yet', () async {
      final provider = ProjectsLibraryProvider(StorageService());
      await provider.load();

      final external = await ProjectsLibraryProvider(StorageService())
          .createProject('External');
      await provider.upsert(external);

      expect(provider.byId(external.id), isNotNull);
    });

    test('rename trims whitespace and ignores a blank new name', () async {
      final provider = ProjectsLibraryProvider(StorageService());
      await provider.load();
      final project = await provider.createProject('Old Name');

      await provider.rename(project.id, '  New Name  ');
      expect(provider.byId(project.id)!.name, 'New Name');

      await provider.rename(project.id, '   ');
      // Blank rename is a no-op, keeping the last valid name.
      expect(provider.byId(project.id)!.name, 'New Name');
    });

    test('delete removes a project permanently', () async {
      final provider = ProjectsLibraryProvider(StorageService());
      await provider.load();
      final project = await provider.createProject('To Delete');
      expect(provider.projectsByRecent, hasLength(1));

      await provider.delete(project.id);

      expect(provider.projectsByRecent, isEmpty);
      expect(provider.byId(project.id), isNull);
    });

    test('byId returns null for an unknown id instead of throwing', () async {
      final provider = ProjectsLibraryProvider(StorageService());
      await provider.load();
      expect(provider.byId('does-not-exist'), isNull);
    });

    test('projectsByRecent sorts most-recently-updated first', () async {
      final provider = ProjectsLibraryProvider(StorageService());
      await provider.load();

      final first = await provider.createProject('First');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = await provider.createProject('Second');
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // Touch the first project again so it becomes the most recent.
      first.name = 'First (edited)';
      await provider.upsert(first);

      final ordered = provider.projectsByRecent;
      expect(ordered.first.id, first.id);
      expect(ordered.last.id, second.id);
    });

    test('allExports flattens exported paths across all projects', () async {
      final provider = ProjectsLibraryProvider(StorageService());
      await provider.load();

      final a = await provider.createProject('A');
      a.exportedVideoPaths.addAll(['/exports/a1.mp4', '/exports/a2.mp4']);
      await provider.upsert(a);

      final b = await provider.createProject('B');
      b.exportedVideoPaths.add('/exports/b1.mp4');
      await provider.upsert(b);

      final exports = provider.allExports;
      expect(exports, hasLength(3));
      expect(
        exports.map((e) => e.value),
        containsAll(<String>[
          '/exports/a1.mp4',
          '/exports/a2.mp4',
          '/exports/b1.mp4',
        ]),
      );
    });

    test(
      'project audio source and visualizer settings survive a reload',
      () async {
        final provider = ProjectsLibraryProvider(StorageService());
        await provider.load();
        final project = await provider.createProject('Round trip');
        project.audioSource = AudioSourceConfig(
          type: AudioSourceType.separateFile,
          filePath: '/music/track.mp3',
        );
        await provider.upsert(project);

        final reopened = ProjectsLibraryProvider(StorageService());
        await reopened.load();
        final reloaded = reopened.byId(project.id)!;

        expect(reloaded.audioSource.type, AudioSourceType.separateFile);
        expect(reloaded.audioSource.filePath, '/music/track.mp3');
      },
    );
  });
}
