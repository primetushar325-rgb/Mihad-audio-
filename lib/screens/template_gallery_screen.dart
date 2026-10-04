import 'package:flutter/material.dart';

import '../models/visualizer_template.dart';
import '../widgets/template_preview_tile.dart';

/// Full-screen template gallery. Used both as the editor's template
/// picker (returns the chosen [VisualizerTemplateType] via
/// `Navigator.pop`) and as a standalone "Template Gallery" entry point
/// from the Home screen.
class TemplateGalleryScreen extends StatelessWidget {
  final VisualizerTemplateType? selected;

  const TemplateGalleryScreen({super.key, this.selected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visualizer Templates')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: kVisualizerTemplates.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final info = kVisualizerTemplates[index];
            return TemplatePreviewTile(
              type: info.type,
              name: info.displayName,
              selected: info.type == selected,
              onTap: () => Navigator.of(context).pop(info.type),
            );
          },
        ),
      ),
    );
  }
}
