import 'package:flutter_test/flutter_test.dart';

import 'package:mihad_audio/services/media_picker_service.dart';

void main() {
  group('MediaPickResult', () {
    test('.success carries the picked path and isSuccess is true', () {
      final result = MediaPickResult.success('/sdcard/DCIM/clip.mp4');

      expect(result.status, MediaPickStatus.success);
      expect(result.path, '/sdcard/DCIM/clip.mp4');
      expect(result.message, isNull);
      expect(result.isSuccess, isTrue);
    });

    test('.cancelled carries no path or message and isSuccess is false', () {
      final result = MediaPickResult.cancelled();

      expect(result.status, MediaPickStatus.cancelled);
      expect(result.path, isNull);
      expect(result.message, isNull);
      expect(result.isSuccess, isFalse);
    });

    test('.error carries a user-facing message and no path', () {
      final result = MediaPickResult.error('Permission denied.');

      expect(result.status, MediaPickStatus.error);
      expect(result.path, isNull);
      expect(result.message, 'Permission denied.');
      expect(result.isSuccess, isFalse);
    });
  });
}
