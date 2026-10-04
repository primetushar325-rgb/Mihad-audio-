import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/project.dart';

/// Persists all MIHAD AUDIO data (projects, export history, app settings)
/// as plain local JSON files under the app's own documents directory.
///
/// This is intentionally dependency-light (no bundled database engine):
/// everything here is just `dart:io` file reads/writes, which keeps the
/// storage format transparent, debuggable, and trivially "offline by
/// construction" - nothing here can call the network.
class StorageService {
  static const _projectsFileName = 'projects.json';
  static const _settingsFileName = 'app_settings.json';

  Future<Directory> _appDir() async {
    final dir = await getApplicationSupportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _projectsFile() async {
    final dir = await _appDir();
    return File('${dir.path}/$_projectsFileName');
  }

  Future<File> _settingsFile() async {
    final dir = await _appDir();
    return File('${dir.path}/$_settingsFileName');
  }

  Future<List<Project>> loadProjects() async {
    try {
      final file = await _projectsFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Project.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // Corrupted or unreadable project store: fail safe with an empty
      // list rather than crashing the app.
      return [];
    }
  }

  Future<void> saveProjects(List<Project> projects) async {
    final file = await _projectsFile();
    final data = jsonEncode(projects.map((p) => p.toJson()).toList());
    await file.writeAsString(data, flush: true);
  }

  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return {};
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return {};
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode(settings), flush: true);
  }

  /// Returns the total size, in bytes, of MIHAD AUDIO's own temporary
  /// working directory (render frames, intermediate PCM/overlay files).
  Future<int> temporaryStorageUsageBytes() async {
    final dir = await getTemporaryDirectory();
    final mihadTemp = Directory('${dir.path}/mihad_audio');
    if (!await mihadTemp.exists()) return 0;
    var total = 0;
    await for (final entity in mihadTemp.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Deletes all of MIHAD AUDIO's temporary working files (render frames,
  /// decoded PCM, intermediate overlay videos). Safe to call at any time
  /// when no export is in progress.
  Future<void> clearTemporaryFiles() async {
    final dir = await getTemporaryDirectory();
    final mihadTemp = Directory('${dir.path}/mihad_audio');
    if (await mihadTemp.exists()) {
      await mihadTemp.delete(recursive: true);
    }
  }
}
