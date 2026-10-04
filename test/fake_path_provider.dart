import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// A minimal, in-memory [PathProviderPlatform] so app/state code that
/// reads/writes local project files can run under `flutter test` without
/// a real device. Every path resolves to a fresh temp directory, isolated
/// per instance so tests don't leak state into each other.
class FakePathProvider extends PathProviderPlatform {
  final Directory root;

  FakePathProvider()
    : root = Directory.systemTemp.createTempSync('mihad_test_');

  @override
  Future<String?> getTemporaryPath() async => root.path;

  @override
  Future<String?> getApplicationSupportPath() async => root.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => root.path;

  @override
  Future<String?> getApplicationCachePath() async => root.path;

  @override
  Future<String?> getLibraryPath() async => root.path;

  void cleanUp() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
