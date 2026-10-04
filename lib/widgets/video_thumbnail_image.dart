import 'dart:io';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/video_thumbnail_service.dart';

/// Shows a real thumbnail generated locally from the project's source
/// video (spec section 4: "Show a thumbnail ... of the imported video").
/// Falls back to a generic icon if thumbnail generation isn't supported
/// on this platform/build (e.g. running in a test harness), the source
/// file is missing, or it fails for any other reason - this is a
/// nice-to-have, never a blocker.
class VideoThumbnailImage extends StatelessWidget {
  final String videoPath;
  final double size;

  const VideoThumbnailImage({
    super.key,
    required this.videoPath,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: FutureBuilder<String?>(
          future: VideoThumbnailService.thumbnailFor(videoPath),
          builder: (context, snapshot) {
            final path = snapshot.data;
            if (path != null) {
              return Image.file(
                File(path),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              );
            }
            return _fallback();
          },
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(gradient: MihadColors.brandGradient),
      child: const Icon(Icons.movie_creation_outlined, color: Colors.black),
    );
  }
}
