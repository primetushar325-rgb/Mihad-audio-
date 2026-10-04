import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app/theme.dart';
import '../models/subtitle_models.dart';
import '../subtitles/subtitle_renderer.dart';

class SubtitleOverlayEditor extends StatelessWidget {
  final VideoPlayerController controller;
  final List<SubtitleLayer> layers;
  final String? selectedCueId;
  final ValueChanged<String?> onSelect;
  final ValueChanged<SubtitleCue> onCueChanged;
  final bool editable;

  const SubtitleOverlayEditor({
    super.key,
    required this.controller,
    required this.layers,
    required this.selectedCueId,
    required this.onSelect,
    required this.onCueChanged,
    this.editable = true,
  });

  SubtitleCue? get _selectedCue {
    final id = selectedCueId;
    if (id == null) return null;
    for (final layer in layers) {
      if (!layer.visible || layer.locked) continue;
      for (final cue in layer.cues) {
        if (cue.id == id && !cue.locked) return cue;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cue = _selectedCue;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth;
        final h = constraints.maxHeight <= 0 ? 1.0 : constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SubtitlePreviewPainter(
                    controller: controller,
                    layers: layers,
                    selectedCueId: selectedCueId,
                    showSelection: editable,
                  ),
                ),
              ),
            ),
            if (editable && cue != null)
              Positioned(
                left: cue.posX * w,
                top: cue.posY * h,
                width: cue.width * w,
                height: cue.height * h,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => onSelect(cue.id),
                  onPanUpdate: (details) {
                    final nextX = (cue.posX + details.delta.dx / w)
                        .clamp(0.0, 1.0 - cue.width)
                        .toDouble();
                    final nextY = (cue.posY + details.delta.dy / h)
                        .clamp(0.0, 1.0 - cue.height)
                        .toDouble();
                    onCueChanged(cue.copyWith(posX: nextX, posY: nextY));
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: MihadColors.accentSecondary.withValues(alpha: 0.78),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: MihadColors.accentSecondary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'TEXT',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SubtitlePreviewPainter extends CustomPainter {
  final VideoPlayerController controller;
  final List<SubtitleLayer> layers;
  final String? selectedCueId;
  final bool showSelection;

  _SubtitlePreviewPainter({
    required this.controller,
    required this.layers,
    required this.selectedCueId,
    required this.showSelection,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    paintSubtitles(
      canvas: canvas,
      size: size,
      layers: layers,
      positionMs: controller.value.position.inMilliseconds.toDouble(),
      selectedCueId: selectedCueId,
      showSelection: showSelection,
    );
  }

  @override
  bool shouldRepaint(covariant _SubtitlePreviewPainter oldDelegate) {
    return oldDelegate.layers != layers ||
        oldDelegate.selectedCueId != selectedCueId ||
        oldDelegate.showSelection != showSelection ||
        oldDelegate.controller != controller;
  }
}
