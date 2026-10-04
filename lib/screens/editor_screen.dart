import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../app/theme.dart';
import '../models/audio_source.dart';
import '../models/visualizer_settings.dart';
import '../models/visualizer_template.dart';
import '../services/media_picker_service.dart';
import '../state/editor_provider.dart';
import '../state/projects_library_provider.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/pick_feedback.dart';
import '../widgets/visualizer_overlay_editor.dart';
import 'export_screen.dart';
import 'template_gallery_screen.dart';

class EditorScreen extends StatelessWidget {
  final String projectId;
  const EditorScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditorProvider>(
      create: (context) {
        final provider = EditorProvider(
          context.read<ProjectsLibraryProvider>(),
        );
        final project = context.read<ProjectsLibraryProvider>().byId(projectId);
        if (project != null) {
          // ignore: discarded_futures
          provider.open(project);
        }
        return provider;
      },
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  final _picker = MediaPickerService();

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorProvider>();
    final project = editor.project;

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? 'Editor'),
        actions: [
          if (editor.state == EditorLoadState.ready)
            TextButton.icon(
              onPressed: () => _goToExport(context, editor),
              icon: const Icon(Icons.ios_share, size: 18),
              label: const Text('Export'),
            ),
        ],
      ),
      body: _buildBody(context, editor),
    );
  }

  Widget _buildBody(BuildContext context, EditorProvider editor) {
    switch (editor.state) {
      case EditorLoadState.idle:
      case EditorLoadState.loadingVideo:
        return const Center(child: CircularProgressIndicator());
      case EditorLoadState.analyzingAudio:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: editor.analysisProgress == 0
                      ? null
                      : editor.analysisProgress,
                ),
                const SizedBox(height: 18),
                const Text('Analyzing audio locally on this device...'),
                const SizedBox(height: 6),
                Text(
                  '${(editor.analysisProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: MihadColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      case EditorLoadState.error:
        return _ErrorReselect(editor: editor, picker: _picker);
      case EditorLoadState.ready:
        return _ReadyEditor(editor: editor, picker: _picker);
    }
  }

  Future<void> _goToExport(BuildContext context, EditorProvider editor) async {
    final project = editor.project!;
    final meta = await editor.probeCurrentVideo();
    final duration = editor.videoController?.value.duration ?? Duration.zero;
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExportScreen(
          project: project,
          videoDuration: meta?.duration ?? duration,
          sourceWidth: meta?.width,
          sourceHeight: meta?.height,
          sourceFps: meta?.fps,
          analysisData: editor.analysisData,
        ),
      ),
    );
  }
}

class _ErrorReselect extends StatelessWidget {
  final EditorProvider editor;
  final MediaPickerService picker;
  const _ErrorReselect({required this.editor, required this.picker});

  @override
  Widget build(BuildContext context) {
    final isAudioIssue =
        editor.project?.audioSource.type == AudioSourceType.separateFile &&
        (editor.errorMessage?.toLowerCase().contains('audio') ?? false);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: MihadColors.danger,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              editor.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: MihadColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                if (isAudioIssue) {
                  final path = await resolvePick(context, picker.pickAudio());
                  if (path != null) {
                    await editor.setAudioSource(
                      AudioSourceConfig(
                        type: AudioSourceType.separateFile,
                        filePath: path,
                      ),
                    );
                  }
                } else {
                  final path = await resolvePick(context, picker.pickVideo());
                  if (path != null) {
                    await editor.setSourceVideo(path);
                  }
                }
              },
              icon: const Icon(Icons.video_library_outlined),
              label: Text(
                isAudioIssue ? 'Reselect Audio File' : 'Reselect Video',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyEditor extends StatelessWidget {
  final EditorProvider editor;
  final MediaPickerService picker;
  const _ReadyEditor({required this.editor, required this.picker});

  @override
  Widget build(BuildContext context) {
    final controller = editor.videoController!;
    final settings = editor.project!.visualizerSettings;
    final ratio = settings.aspectRatio.value ?? editor.videoAspectRatio;

    return Column(
      children: [
        Container(
          color: Colors.black,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: AspectRatio(
              aspectRatio: ratio,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width == 0
                            ? 1
                            : controller.value.size.width,
                        height: controller.value.size.height == 0
                            ? 1
                            : controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
                    VisualizerOverlayEditor(
                      controller: controller,
                      analysisData: editor.analysisData,
                      settings: settings,
                      onChanged: (updated) =>
                          editor.updateVisualizerSettings((_) => updated),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _PlaybackBar(controller: controller, editor: editor),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TemplateSection(editor: editor),
              const SizedBox(height: 20),
              _AudioSection(editor: editor, picker: picker),
              const SizedBox(height: 20),
              _AppearanceSection(editor: editor),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaybackBar extends StatelessWidget {
  final VideoPlayerController controller;
  final EditorProvider editor;
  const _PlaybackBar({required this.controller, required this.editor});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;
        final position = value.position;
        final duration = value.duration;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                ),
                iconSize: 36,
                color: MihadColors.accentPrimary,
                onPressed: () {
                  if (value.isPlaying) {
                    editor.pause();
                  } else {
                    editor.play();
                  }
                },
              ),
              Text(
                _fmt(position),
                style: const TextStyle(
                  fontSize: 12,
                  color: MihadColors.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: duration.inMilliseconds == 0
                      ? 0
                      : position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble(),
                  max: duration.inMilliseconds == 0
                      ? 1
                      : duration.inMilliseconds.toDouble(),
                  onChanged: (v) =>
                      editor.seekTo(Duration(milliseconds: v.round())),
                ),
              ),
              Text(
                _fmt(duration),
                style: const TextStyle(
                  fontSize: 12,
                  color: MihadColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TemplateSection extends StatelessWidget {
  final EditorProvider editor;
  const _TemplateSection({required this.editor});

  @override
  Widget build(BuildContext context) {
    final settings = editor.project!.visualizerSettings;
    final info = visualizerTemplateInfo(settings.template);
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.auto_awesome,
          color: MihadColors.accentPrimary,
        ),
        title: const Text('Visualizer Template'),
        subtitle: Text(info.displayName),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final selected = await Navigator.of(context)
              .push<VisualizerTemplateType>(
                MaterialPageRoute(
                  builder: (_) =>
                      TemplateGalleryScreen(selected: settings.template),
                ),
              );
          if (selected != null) {
            editor.updateVisualizerSettings(
              (s) => s.copyWith(template: selected),
            );
          }
        },
      ),
    );
  }
}

class _AudioSection extends StatelessWidget {
  final EditorProvider editor;
  final MediaPickerService picker;
  const _AudioSection({required this.editor, required this.picker});

  @override
  Widget build(BuildContext context) {
    final audioSource = editor.project!.audioSource;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audio Source',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                audioSource.type == AudioSourceType.originalVideo
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: audioSource.type == AudioSourceType.originalVideo
                    ? MihadColors.accentPrimary
                    : MihadColors.textSecondary,
              ),
              title: const Text('Original video audio'),
              onTap: () => editor.setAudioSource(
                AudioSourceConfig(type: AudioSourceType.originalVideo),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                audioSource.type == AudioSourceType.separateFile
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: audioSource.type == AudioSourceType.separateFile
                    ? MihadColors.accentPrimary
                    : MihadColors.textSecondary,
              ),
              title: const Text('Separate audio file'),
              onTap: () async {
                final path = await resolvePick(context, picker.pickAudio());
                if (path != null) {
                  await editor.setAudioSource(
                    AudioSourceConfig(
                      type: AudioSourceType.separateFile,
                      filePath: path,
                    ),
                  );
                }
              },
            ),
            if (audioSource.type == AudioSourceType.separateFile) ...[
              if (audioSource.filePath != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    audioSource.filePath!.split('/').last,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MihadColors.textSecondary,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, size: 18),
                    Expanded(
                      child: Slider(
                        value: audioSource.volume,
                        onChanged: (v) => editor.setAudioVolume(v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  final EditorProvider editor;
  const _AppearanceSection({required this.editor});

  @override
  Widget build(BuildContext context) {
    final settings = editor.project!.visualizerSettings;

    Widget slider(
      String label,
      double value,
      double min,
      double max,
      void Function(double) onChanged,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appearance',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                TextButton(
                  onPressed: () => editor.updateVisualizerSettings(
                    (s) => s.resetAppearance(),
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _ColorSwatch(
                    label: 'Primary',
                    color: settings.primaryColor,
                    onTap: () async {
                      final color = await showMihadColorPicker(
                        context,
                        settings.primaryColorValue,
                      );
                      if (color != null) {
                        editor.updateVisualizerSettings(
                          (s) => s.copyWith(primaryColorValue: color),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ColorSwatch(
                    label: 'Secondary',
                    color: settings.secondaryColor,
                    onTap: () async {
                      final color = await showMihadColorPicker(
                        context,
                        settings.secondaryColorValue,
                      );
                      if (color != null) {
                        editor.updateVisualizerSettings(
                          (s) => s.copyWith(secondaryColorValue: color),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            slider(
              'Opacity',
              settings.opacity,
              0.1,
              1.0,
              (v) => editor.updateVisualizerSettings(
                (s) => s.copyWith(opacity: v),
              ),
            ),
            slider(
              'Glow intensity',
              settings.glowIntensity,
              0.0,
              1.0,
              (v) => editor.updateVisualizerSettings(
                (s) => s.copyWith(glowIntensity: v),
              ),
            ),
            slider(
              'Sensitivity',
              settings.sensitivity,
              0.3,
              2.5,
              (v) => editor.updateVisualizerSettings(
                (s) => s.copyWith(sensitivity: v),
              ),
            ),
            slider(
              'Bar / line thickness',
              settings.barWidth,
              1.0,
              20.0,
              (v) => editor.updateVisualizerSettings(
                (s) => s.copyWith(barWidth: v),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Horizontal alignment', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            SegmentedButton<VisualizerAlignment>(
              segments: const [
                ButtonSegment(
                  value: VisualizerAlignment.left,
                  label: Text('Left'),
                ),
                ButtonSegment(
                  value: VisualizerAlignment.center,
                  label: Text('Center'),
                ),
                ButtonSegment(
                  value: VisualizerAlignment.right,
                  label: Text('Right'),
                ),
              ],
              selected: {settings.alignment},
              onSelectionChanged: (set) {
                final alignment = set.first;
                final posX = switch (alignment) {
                  VisualizerAlignment.left => 0.03,
                  VisualizerAlignment.center => (1 - settings.width) / 2,
                  VisualizerAlignment.right => 0.97 - settings.width,
                };
                editor.updateVisualizerSettings(
                  (s) => s.copyWith(
                    alignment: alignment,
                    posX: posX.clamp(0.0, 1.0),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Export aspect ratio', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: ExportAspectRatio.values.map((ratio) {
                return ChoiceChip(
                  label: Text(ratio.label),
                  selected: settings.aspectRatio == ratio,
                  onSelected: (_) => editor.updateVisualizerSettings(
                    (s) => s.copyWith(aspectRatio: ratio),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ColorSwatch({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: MihadColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
