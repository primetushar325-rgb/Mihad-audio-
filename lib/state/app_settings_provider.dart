import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/storage_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  final StorageService _storage;
  AppSettings _settings = AppSettings();
  bool _loaded = false;

  AppSettingsProvider(this._storage);

  AppSettings get settings => _settings;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final json = await _storage.loadSettings();
    if (json.isNotEmpty) {
      _settings = AppSettings.fromJson(json);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings Function(AppSettings) updater) async {
    _settings = updater(_settings);
    notifyListeners();
    await _storage.saveSettings(_settings.toJson());
  }
}
