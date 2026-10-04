import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../app/theme.dart';

/// Shows a real thumbnail generated locally from the project's source
/// video (spec section 4: "Show a thumbnail ... of the imported video").
/// Falls back to a generic icon if thumbnail generation isn't supported
/// on this platform/build (e.g. running in a test harness) or fails for
/// any other reason - this is a nice-to-have, never a blocker.
class VideoThumbnailImage extends StatelessWidget {
  final String videoPath;
  final double size;

  const VideoThumbnailImage({
    super.key,
    required this.videoPath,
    this.size = 52,
  });

  Future<Uint8List?> _generate() async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 60,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: FutureBuilder<Uint8List?>(
          future: _generate(),
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes != null) {
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: size,
                height: size,
              );
            }
            return Container(
              decoration: const BoxDecoration(
                gradient: MihadColors.brandGradient,
              ),
              child: const Icon(
                Icons.movie_creation_outlined,
                color: Colors.black,
              ),
            );
          },
        ),
      ),
    );
  }
}
