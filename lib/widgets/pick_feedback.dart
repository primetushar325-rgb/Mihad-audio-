import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/media_picker_service.dart';

/// Shared helper for every screen that calls [MediaPickerService]: shows a
/// clear SnackBar if the picker itself failed (permission denial,
/// unsupported media, no picker app available), does nothing if the user
/// simply cancelled, and returns the picked path on success.
///
/// Centralizing this means every "pick a video/audio" button in the app
/// behaves consistently rather than silently doing nothing on failure.
Future<String?> resolvePick(
  BuildContext context,
  Future<MediaPickResult> pickFuture,
) async {
  final result = await pickFuture;
  if (!context.mounted) return result.path;

  if (result.status == MediaPickStatus.error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Could not open the file picker.'),
        backgroundColor: MihadColors.danger,
      ),
    );
    return null;
  }
  return result.path;
}
