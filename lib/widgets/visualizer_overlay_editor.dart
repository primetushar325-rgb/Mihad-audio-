import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app/theme.dart';
import '../models/audio_analysis_data.dart';
import '../models/visualizer_settings.dart';
import '../services/export_math.dart';
import '../visualizers/visualizer_canvas_painter.dart';
import '../visualizers/visualizer_painter_base.dart';

/// Renders the visualizer overlay on top of the video preview and lets
/// the user drag it to reposition, and drag its corner handle to resize -
/// directly updating [settings] (as fractions of the canvas), which is
/// the exact same data structure used by the export renderer.
class VisualizerOverlayEditor extends StatefulWidget {
  final VideoPlayerController controller;
  final AudioAnalysisData analysisData;
  final VisualizerSettings settings;
  final ValueChanged<VisualizerSettings> onChanged;
  final bool editable;

  const VisualizerOverlayEditor({
    super.key,
    required this.controller,
    required this.analysisData,
    required this.settings,
    required this.onChanged,
    this.editable = true,
  });

  @override
  State<VisualizerOverlayEditor> createState() =>
      _VisualizerOverlayEditorState();
}

class _VisualizerOverlayEditorState extends State<VisualizerOverlayEditor> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasW = constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth;
        final canvasH = constraints.maxHeight <= 0 ? 1.0 : constraints.maxHeight;
        final s = widget.settings;
        final bounds = resolveVisualizerBounds(s, canvasW, canvasH);
        final left = bounds.left;
        final top = bounds.top;
        final width = bounds.width;
        final height = bounds.height;

        VisualizerSettings movedBy(Offset delta) {
          final newLeft = (left + delta.dx)
              .clamp(0.0, canvasW - width)
              .toDouble();
          final newTop = (top + delta.dy)
              .clamp(0.0, canvasH - height)
              .toDouble();
          return s.copyWith(posX: newLeft / canvasW, posY: newTop / canvasH);
        }

        VisualizerSettings resizedBy(Offset delta) {
          final minW = canvasW < 44
              ? canvasW
              : (canvasW * 0.08).clamp(44.0, canvasW).toDouble();
          final minH = canvasH < 34
              ? canvasH
              : (canvasH * 0.06).clamp(34.0, canvasH).toDouble();
          final maxW = (canvasW - left).clamp(1.0, canvasW).toDouble();
          final maxH = (canvasH - top).clamp(1.0, canvasH).toDouble();
          final minWidthForClamp = minW > maxW ? maxW : minW;
          final minHeightForClamp = minH > maxH ? maxH : minH;
          final newWidth = (width + delta.dx)
              .clamp(minWidthForClamp, maxW)
              .toDouble();
          final newHeight = (height + delta.dy)
              .clamp(minHeightForClamp, maxH)
              .toDouble();
          return s.copyWith(
            width: newWidth / canvasW,
            height: newHeight / canvasH,
          );
        }

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: widget.editable
                    ? (details) => widget.onChanged(movedBy(details.delta))
                    : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: widget.editable
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: MihadColors.accentPrimary.withValues(
                                    alpha: 0.70,
                                  ),
                                  width: 1,
                                ),
                              )
                            : const BoxDecoration(),
                        child: AnimatedBuilder(
                          animation: widget.controller,
                          builder: (context, _) {
                            final posMs = widget
                                .controller
                                .value
                                .position
                                .inMilliseconds
                                .toDouble();
                            final frame = VisualizerFrameData(
                              amplitude: widget.analysisData.amplitudeAt(posMs),
                              bands: widget.analysisData.bandsAt(posMs),
                            );
                            return CustomPaint(
                              painter: VisualizerCanvasPainter(
                                data: frame,
                                settings: s.copyWith(
                                  posX: 0,
                                  posY: 0,
                                  width: 1,
                                  height: 1,
                                ),
                              ),
                              size: Size(width, height),
                            );
                          },
                        ),
                      ),
                    ),
                    if (widget.editable) ...[
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _OverlayHandle(
                          icon: Icons.drag_indicator,
                          label: 'Move visualizer',
                          onPanUpdate: (delta) => widget.onChanged(movedBy(delta)),
                        ),
                      ),
                      Positioned(
                        right: -11,
                        bottom: -11,
                        child: _OverlayHandle(
                          icon: Icons.open_in_full,
                          label: 'Resize visualizer',
                          onPanUpdate: (delta) => widget.onChanged(resizedBy(delta)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverlayHandle extends StatelessWidget {
  final IconData icon;
  final String label;
  final ValueChanged<Offset> onPanUpdate;

  const _OverlayHandle({
    required this.icon,
    required this.label,
    required this.onPanUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onPanUpdate(details.delta),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: MihadColors.accentPrimary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: MihadColors.accentPrimary.withValues(alpha: 0.45),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(icon, size: 14, color: Colors.black),
        ),
      ),
    );
  }
}
