import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app/theme.dart';
import '../models/audio_analysis_data.dart';
import '../models/visualizer_template.dart';
import '../widgets/template_preview_tile.dart';

/// Full-screen template gallery. Used both as the editor's template
/// picker (returns the chosen [VisualizerTemplateType] via
/// `Navigator.pop`) and as a standalone "Template Gallery" entry point
/// from the Home screen.
class TemplateGalleryScreen extends StatelessWidget {
  final VisualizerTemplateType? selected;
  final AudioAnalysisData? analysisData;
  final VideoPlayerController? controller;

  const TemplateGalleryScreen({
    super.key,
    this.selected,
    this.analysisData,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MihadColors.background,
      appBar: AppBar(
        title: const Text('Visualizer Templates'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '${kVisualizerTemplates.length} styles',
                style: const TextStyle(
                  color: MihadColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      MihadColors.surfaceElevated,
                      MihadColors.surface.withValues(alpha: 0.65),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: MihadColors.accentPrimary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Premium vector visualizers. In the editor, previews react to your analyzed audio and export uses the same box values.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: MihadColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            sliver: SliverGrid.builder(
              itemCount: kVisualizerTemplates.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final info = kVisualizerTemplates[index];
                return TemplatePreviewTile(
                  type: info.type,
                  name: info.displayName,
                  category: info.category,
                  selected: info.type == selected,
                  analysisData: analysisData,
                  controller: controller,
                  onTap: () => Navigator.of(context).pop(info.type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
