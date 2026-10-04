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
/// the exact same data structure used by the export renderer. This is
/// what guarantees the preview position/size matches the final export
/// (spec section 7).
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
        final canvasW = constraints.maxWidth;
        final canvasH = constraints.maxHeight;
        final s = widget.settings;
        final bounds = resolveVisualizerBounds(s, canvasW, canvasH);
        final left = bounds.left;
        final top = bounds.top;
        final width = bounds.width;
        final height = bounds.height;

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
                    ? (details) {
                        final newLeft = (left + details.delta.dx).clamp(
                          0.0,
                          canvasW - width,
                        );
                        final newTop = (top + details.delta.dy).clamp(
                          0.0,
                          canvasH - height,
                        );
                        widget.onChanged(
                          s.copyWith(
                            posX: newLeft / canvasW,
                            posY: newTop / canvasH,
                          ),
                        );
                      }
                    : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: widget.editable
                          ? BoxDecoration(
                              border: Border.all(
                                color: MihadColors.accentPrimary.withValues(
                                  alpha: 0.6,
                                ),
                                width: 1,
                              ),
                            )
                          : null,
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
                    if (widget.editable)
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            final newWidth = (width + details.delta.dx).clamp(
                              40.0,
                              canvasW - left,
                            );
                            final newHeight = (height + details.delta.dy).clamp(
                              30.0,
                              canvasH - top,
                            );
                            widget.onChanged(
                              s.copyWith(
                                width: newWidth / canvasW,
                                height: newHeight / canvasH,
                              ),
                            );
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: MihadColors.accentPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.open_in_full,
                              size: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
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
