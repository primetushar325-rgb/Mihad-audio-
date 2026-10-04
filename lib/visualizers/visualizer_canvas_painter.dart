import 'package:flutter/material.dart';

import '../models/visualizer_settings.dart';
import 'visualizer_painter_base.dart';
import 'visualizer_registry.dart';

/// Generic [CustomPainter] used by live preview and template thumbnails.
/// The same `paintVisualizerOverlayBox` helper is also called by export,
/// preserving WYSIWYG rounded-box/background/border rendering.
class VisualizerCanvasPainter extends CustomPainter {
  final VisualizerFrameData data;
  final VisualizerSettings settings;

  VisualizerCanvasPainter({
    required this.data,
    required this.settings,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final delegate = painterFor(settings.template);
    paintVisualizerOverlayBox(
      canvas: canvas,
      size: size,
      data: data,
      settings: settings,
      delegate: delegate,
    );
  }

  @override
  bool shouldRepaint(covariant VisualizerCanvasPainter oldDelegate) {
    return true;
  }
}
