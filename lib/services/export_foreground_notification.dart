import 'dart:io';

import 'package:flutter/services.dart';

/// Thin platform-channel wrapper around the Android foreground export
/// notification. The export still runs through the existing Dart
/// ExportController/ExportService; the foreground service keeps an ongoing
/// Android notification and raises process priority while export is active.
class ExportForegroundNotification {
  static const _channel = MethodChannel('mihad_audio/export_foreground');

  static Future<void> start() => _safeInvoke('startExport');

  static Future<void> update(double progress) => _safeInvoke('updateExport', {
    'progress': (progress.clamp(0.0, 1.0) * 100).round(),
  });

  static Future<void> complete() => _safeInvoke('finishExport', {
    'status': 'complete',
  });

  static Future<void> failed() => _safeInvoke('finishExport', {
    'status': 'failed',
  });

  static Future<void> cancelled() => _safeInvoke('finishExport', {
    'status': 'cancelled',
  });

  static Future<void> _safeInvoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } catch (_) {
      // Notification support must never make the export itself fail. Devices
      // without notification permission still keep the in-app progress UI.
    }
  }
}
