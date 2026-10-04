import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/audio_analysis_data.dart';
import '../models/export_settings.dart';
import '../models/project.dart';
import '../services/export_service.dart';
import '../state/export_controller.dart';
import '../state/projects_library_provider.dart';

class ExportScreen extends StatelessWidget {
  final Project project;
  final Duration videoDuration;
  final int? sourceWidth;
  final int? sourceHeight;
  final double? sourceFps;
  final AudioAnalysisData analysisData;

  const ExportScreen({
    super.key,
    required this.project,
    required this.videoDuration,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.sourceFps,
    required this.analysisData,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExportController(),
      child: _ExportView(
        project: project,
        videoDuration: videoDuration,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        sourceFps: sourceFps,
        analysisData: analysisData,
      ),
    );
  }
}

class _ExportView extends StatelessWidget {
  final Project project;
  final Duration videoDuration;
  final int? sourceWidth;
  final int? sourceHeight;
  final double? sourceFps;
  final AudioAnalysisData analysisData;

  const _ExportView({
    required this.project,
    required this.videoDuration,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.sourceFps,
    required this.analysisData,
  });

  String _stageLabel(ExportStage stage) {
    switch (stage) {
      case ExportStage.renderingOverlay:
        return 'Rendering visualizer frames...';
      case ExportStage.compositing:
        return 'Encoding final video...';
      case ExportStage.savingToGallery:
        return 'Saving to device...';
      case ExportStage.done:
        return 'Done';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExportController>();
    final longVideoWarning = videoDuration.inMinutes >= 5;

    return Scaffold(
      appBar: AppBar(title: const Text('Export Video')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.state == ExportUiState.idle) ...[
              const Text(
                'Export settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Resolution'),
                      trailing: DropdownButton<ExportResolutionPreset>(
                        value: project.exportSettings.resolution,
                        dropdownColor: MihadColors.surfaceElevated,
                        underline: const SizedBox.shrink(),
                        items: ExportResolutionPreset.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          project.exportSettings.resolution = value;
                          context.read<ProjectsLibraryProvider>().upsert(
                            project,
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Frame rate'),
                      trailing: DropdownButton<ExportFpsPreset>(
                        value: project.exportSettings.fps,
                        dropdownColor: MihadColors.surfaceElevated,
                        underline: const SizedBox.shrink(),
                        items: ExportFpsPreset.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          project.exportSettings.fps = value;
                          context.read<ProjectsLibraryProvider>().upsert(
                            project,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (longVideoWarning) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MihadColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MihadColors.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: MihadColors.danger,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This video is 5+ minutes long. Rendering happens '
                          'frame-by-frame on this device, so export may take a '
                          'while and use noticeable battery/storage. Consider '
                          'testing with a short clip first.',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => controller.start(
                    project: project,
                    videoDuration: videoDuration,
                    sourceWidth: sourceWidth,
                    sourceHeight: sourceHeight,
                    sourceFps: sourceFps,
                    analysisData: analysisData,
                  ),
                  icon: const Icon(Icons.movie_filter_outlined),
                  label: const Text('Start Export'),
                ),
              ),
            ] else if (controller.state == ExportUiState.running) ...[
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(value: controller.progress),
                    const SizedBox(height: 20),
                    Text(_stageLabel(controller.stage)),
                    const SizedBox(height: 6),
                    Text(
                      '${(controller.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: MihadColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.cancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Export'),
                ),
              ),
            ] else if (controller.state == ExportUiState.success) ...[
              const Spacer(),
              const Icon(
                Icons.check_circle,
                color: MihadColors.accentPrimary,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Export complete!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                controller.outputPath ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  color: MihadColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ] else if (controller.state == ExportUiState.cancelled) ...[
              const Spacer(),
              const Icon(
                Icons.cancel,
                color: MihadColors.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text('Export cancelled'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.reset,
                  child: const Text('Back to export settings'),
                ),
              ),
            ] else if (controller.state == ExportUiState.error) ...[
              const Spacer(),
              const Icon(
                Icons.error_outline,
                color: MihadColors.danger,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage ?? 'Export failed.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.reset,
                  child: const Text('Try again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
