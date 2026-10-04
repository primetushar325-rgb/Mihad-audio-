import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app/theme.dart';
import '../models/audio_analysis_data.dart';
import '../models/visualizer_settings.dart';
import '../models/visualizer_template.dart';
import '../visualizers/visualizer_canvas_painter.dart';
import '../visualizers/visualizer_painter_base.dart';

/// Premium template gallery tile. When opened from the editor, the tile
/// previews use the current [AudioAnalysisData] and video position. When
/// opened standalone from Home before media exists, a single static local
/// sample is used only to make the vector style visible; it does not loop
/// independently of audio.
class TemplatePreviewTile extends StatefulWidget {
  final VisualizerTemplateType type;
  final String name;
  final String category;
  final bool selected;
  final AudioAnalysisData? analysisData;
  final VideoPlayerController? controller;
  final VoidCallback onTap;

  const TemplatePreviewTile({
    super.key,
    required this.type,
    required this.name,
    required this.category,
    required this.selected,
    required this.onTap,
    this.analysisData,
    this.controller,
  });

  @override
  State<TemplatePreviewTile> createState() => _TemplatePreviewTileState();
}

class _TemplatePreviewTileState extends State<TemplatePreviewTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _demoController;

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..value = 0.37;
  }

  @override
  void dispose() {
    _demoController.dispose();
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

  VisualizerFrameData _frame() {
    final analysis = widget.analysisData;
    final controller = widget.controller;
    if (analysis != null && controller != null && !analysis.isEmpty) {
      final posMs = controller.value.position.inMilliseconds.toDouble();
      return VisualizerFrameData(
        amplitude: analysis.amplitudeAt(posMs),
        bands: analysis.bandsAt(posMs),
      );
    }
    return _syntheticFrame(_demoController.value);
  }

  @override
  Widget build(BuildContext context) {
    final hasLiveAudio = widget.analysisData != null &&
        widget.controller != null &&
        !(widget.analysisData?.isEmpty ?? true);
    final settings = VisualizerSettings(
      template: widget.type,
      posX: 0,
      posY: 0,
      width: 1,
      height: 1,
      backgroundOpacity: 0.52,
      cornerRadius: 0.18,
      glowIntensity: 0.45,
      barWidth: 5.5,
    );
    final listenable = hasLiveAudio ? widget.controller! : _demoController;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: MihadColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.selected
                ? MihadColors.accentPrimary
                : Colors.white.withValues(alpha: 0.05),
            width: widget.selected ? 2 : 1,
          ),
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: MihadColors.accentPrimary.withValues(alpha: 0.22),
                    blurRadius: 22,
                    spreadRadius: -4,
                  ),
                ]
              : const [],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF05070D), Color(0xFF111827)],
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: listenable,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: VisualizerCanvasPainter(
                          data: _frame(),
                          settings: settings,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                if (widget.selected) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 15,
                    color: MihadColors.accentPrimary,
                  ),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              hasLiveAudio ? 'Live audio preview' : widget.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: MihadColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
