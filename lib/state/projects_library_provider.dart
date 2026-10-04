import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../services/storage_service.dart';

/// Owns the full list of local MIHAD AUDIO projects (Home screen's
/// "Recent Projects" and "My Exports" sections) and persists every
/// change immediately through [StorageService].
class ProjectsLibraryProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  List<Project> _projects = [];
  bool _loaded = false;

  ProjectsLibraryProvider(this._storage);

  bool get isLoaded => _loaded;

  List<Project> get projectsByRecent {
    final list = [..._projects];
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// All exported video file paths across every project, most recent
  /// first, for the "My Exports" section.
  List<MapEntry<Project, String>> get allExports {
    final entries = <MapEntry<Project, String>>[];
    for (final p in _projects) {
      for (final path in p.exportedVideoPaths) {
        entries.add(MapEntry(p, path));
      }
    }
    return entries;
  }

  Future<void> load() async {
    _projects = await _storage.loadProjects();
    _loaded = true;
    notifyListeners();
  }

  Future<Project> createProject(String name) async {
    final project = Project(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'Untitled project' : name.trim(),
    );
    _projects.add(project);
    await _persist();
    return project;
  }

  Future<void> upsert(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    project.updatedAt = DateTime.now();
    if (index >= 0) {
      _projects[index] = project;
    } else {
      _projects.add(project);
    }
    await _persist();
  }

  Future<void> rename(String id, String newName) async {
    final project = _projects.firstWhere((p) => p.id == id);
    project.name = newName.trim().isEmpty ? project.name : newName.trim();
    project.updatedAt = DateTime.now();
    await _persist();
  }

  Future<void> delete(String id) async {
    _projects.removeWhere((p) => p.id == id);
    await _persist();
  }

  Project? byId(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist() async {
    notifyListeners();
    await _storage.saveProjects(_projects);
  }
}
