import '../models/export_settings.dart';
import '../models/visualizer_settings.dart';

/// Pure, side-effect-free calculations used by [ExportService]. Pulled
/// into their own file so the export resolution/fps/position math can be
/// unit-tested without touching FFmpeg, the file system, or Flutter's
/// rendering pipeline.
/// Resolves the user's chosen frame-rate preset to a concrete fps value.
double resolveExportFps(ExportFpsPreset preset, double? sourceFps) {
  switch (preset) {
    case ExportFpsPreset.fps24:
      return 24;
    case ExportFpsPreset.fps30:
      return 30;
    case ExportFpsPreset.source:
      return (sourceFps != null && sourceFps > 1) ? sourceFps : 30;
  }
}

/// Resolves the final output (width, height) in pixels for the chosen
/// resolution preset and aspect ratio, guaranteeing even dimensions
/// (required by yuv420p H.264 encoding).
(int, int) resolveExportResolution({
  required ExportResolutionPreset preset,
  required ExportAspectRatio aspect,
  required int? sourceWidth,
  required int? sourceHeight,
}) {
  final double ratio =
      aspect.value ??
      ((sourceWidth != null && sourceHeight != null && sourceHeight > 0)
          ? sourceWidth / sourceHeight
          : 16 / 9);

  int targetHeight;
  switch (preset) {
    case ExportResolutionPreset.res720p:
      targetHeight = 720;
      break;
    case ExportResolutionPreset.res1080p:
      targetHeight = 1080;
      break;
    case ExportResolutionPreset.original:
      targetHeight = (sourceHeight != null && sourceHeight > 0)
          ? sourceHeight
          : 720;
      break;
  }

  int targetWidth = (targetHeight * ratio).round();
  targetWidth -= targetWidth % 2;
  targetHeight -= targetHeight % 2;
  return (targetWidth, targetHeight);
}

/// Converts a [VisualizerSettings]'s fractional position/size into
/// absolute pixel bounds for a canvas of [canvasWidth] x [canvasHeight].
/// The same function is used to position the overlay in the live preview
/// and to place the painter's clip rect during export, which is what
/// guarantees what-you-see-is-what-you-export (spec section 7).
({double left, double top, double width, double height})
resolveVisualizerBounds(
  VisualizerSettings settings,
  double canvasWidth,
  double canvasHeight,
) {
  final safeCanvasWidth = canvasWidth <= 0 ? 1.0 : canvasWidth;
  final safeCanvasHeight = canvasHeight <= 0 ? 1.0 : canvasHeight;
  final widthFraction = settings.width.clamp(0.02, 1.0).toDouble();
  final heightFraction = settings.height.clamp(0.02, 1.0).toDouble();
  final width = (widthFraction * safeCanvasWidth)
      .clamp(1.0, safeCanvasWidth)
      .toDouble();
  final height = (heightFraction * safeCanvasHeight)
      .clamp(1.0, safeCanvasHeight)
      .toDouble();
  final left = (settings.posX * safeCanvasWidth)
      .clamp(0.0, safeCanvasWidth - width)
      .toDouble();
  final top = (settings.posY * safeCanvasHeight)
      .clamp(0.0, safeCanvasHeight - height)
      .toDouble();
  return (left: left, top: top, width: width, height: height);
}
