import 'package:flutter/material.dart';

import '../models/visualizer_settings.dart';
import 'visualizer_painter_base.dart';
import 'visualizer_registry.dart';

/// Generic [CustomPainter] used both by the live preview widget and (via
/// the same code path, guaranteeing WYSIWYG) a one-off still frame
/// renderer used during export. It simply delegates to the template
/// registered for [settings.template].
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
    if (settings.opacity <= 0.0) return;
    final delegate = painterFor(settings.template);
    canvas.saveLayer(Offset.zero & size, Paint());
    delegate.paint(canvas, size, data, settings);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VisualizerCanvasPainter oldDelegate) {
    return true;
  }
}
