import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/visualizer_settings.dart';
import '../models/visualizer_template.dart';
import '../visualizers/visualizer_canvas_painter.dart';
import '../visualizers/visualizer_painter_base.dart';

/// A template gallery tile with a small looping *demo* animation.
///
/// This demo pattern is a synthetic sweep used purely so the gallery has
/// something to show before any video/audio is loaded - it is clearly a
/// stand-in preview, not a claim that the thumbnail is reacting to real
/// audio. Once a template is selected inside the editor, its visuals are
/// always driven by the actual analyzed audio (see `EditorProvider`).
class TemplatePreviewTile extends StatefulWidget {
  final VisualizerTemplateType type;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const TemplatePreviewTile({
    super.key,
    required this.type,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  State<TemplatePreviewTile> createState() => _TemplatePreviewTileState();
}

class _TemplatePreviewTileState extends State<TemplatePreviewTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  VisualizerFrameData _syntheticFrame(double t) {
    const bandCount = 32;
    final bands = List<double>.generate(bandCount, (i) {
      final phase = t * 2 * math.pi + i * 0.4;
      return (0.5 + 0.5 * math.sin(phase)) * (0.4 + 0.6 * (1 - i / bandCount));
    });
    final amplitude = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 1.3);
    return VisualizerFrameData(amplitude: amplitude, bands: bands);
  }

  @override
  Widget build(BuildContext context) {
    final settings = VisualizerSettings(template: widget.type);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: MihadColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.selected
                ? MihadColors.accentPrimary
                : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: VisualizerCanvasPainter(
                          data: _syntheticFrame(_controller.value),
                          settings: settings.copyWith(
                            posX: 0,
                            posY: 0,
                            width: 1,
                            height: 1,
                          ),
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.selected) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: MihadColors.accentPrimary,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
