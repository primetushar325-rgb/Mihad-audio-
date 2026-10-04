import 'dart:math' as math;

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
                  builder: (_) => TemplateGalleryScreen(
                    selected: settings.template,
                    analysisData: editor.analysisData,
                    controller: editor.videoController,
                  ),
                ),
              );
          if (selected != null) {
            editor.updateVisualizerSettings(
              (s) => s.applyTemplatePreset(selected),
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

    void update(VisualizerSettings Function(VisualizerSettings s) updater) {
      editor.updateVisualizerSettings(updater);
    }

    Widget slider(
      String label,
      double value,
      double min,
      double max,
      void Function(double) onChanged, {
      String? valueLabel,
      int? divisions,
    }) {
      final effectiveMax = max <= min ? min + 0.0001 : max;
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 13)),
                Text(
                  valueLabel ?? value.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 12,
                    color: MihadColors.textSecondary,
                  ),
                ),
              ],
            ),
            Slider(
              value: value.clamp(min, effectiveMax).toDouble(),
              min: min,
              max: effectiveMax,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ],
        ),
      );
    }

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Visualizer Controls',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    TextButton.icon(
                      onPressed: () => update((s) => s.resetAppearance()),
                      icon: const Icon(Icons.restart_alt, size: 17),
                      label: const Text('Reset'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        if (editor.videoController?.value.isPlaying ?? false) {
                          editor.pause();
                        } else {
                          editor.play();
                        }
                      },
                      icon: const Icon(Icons.play_circle_outline, size: 17),
                      label: const Text('Preview'),
                    ),
                  ],
                ),
              ],
            ),
            sectionLabel('Mode'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'waveform', label: Text('Waveform')),
                ButtonSegment(value: 'spectrum', label: Text('Spectrum')),
                ButtonSegment(value: 'cinematic', label: Text('Cinematic')),
              ],
              selected: {_modeForTemplate(settings.template)},
              onSelectionChanged: (set) {
                final template = switch (set.first) {
                  'spectrum' => VisualizerTemplateType.spectrumBars,
                  'cinematic' => VisualizerTemplateType.cinematicWave,
                  _ => VisualizerTemplateType.storyWave,
                };
                update((s) => s.applyTemplatePreset(template));
              },
            ),
            const SizedBox(height: 6),
            const Text(
              'Waveform uses real time-domain audio; Spectrum uses FFT frequency bands; Cinematic blends both.',
              style: TextStyle(fontSize: 11.5, color: MihadColors.textSecondary),
            ),
            sectionLabel('Color'),
            SegmentedButton<VisualizerColorMode>(
              segments: const [
                ButtonSegment(
                  value: VisualizerColorMode.single,
                  label: Text('Single'),
                ),
                ButtonSegment(
                  value: VisualizerColorMode.gradient,
                  label: Text('Gradient'),
                ),
                ButtonSegment(
                  value: VisualizerColorMode.rainbow,
                  label: Text('Rainbow'),
                ),
                ButtonSegment(
                  value: VisualizerColorMode.random,
                  label: Text('Random'),
                ),
              ],
              selected: {settings.colorMode},
              onSelectionChanged: (set) => update(
                (s) => s.copyWith(colorMode: set.first),
              ),
            ),
            const SizedBox(height: 12),
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
                        update((s) => s.copyWith(primaryColorValue: color));
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
                        update((s) => s.copyWith(secondaryColorValue: color));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _singleColorPresets.map((preset) {
                return ChoiceChip(
                  label: Text(preset.label),
                  selected: settings.colorMode == VisualizerColorMode.single &&
                      settings.primaryColorValue == preset.value,
                  avatar: CircleAvatar(backgroundColor: Color(preset.value)),
                  onSelected: (_) => update(
                    (s) => s.copyWith(
                      colorMode: VisualizerColorMode.single,
                      primaryColorValue: preset.value,
                      secondaryColorValue: preset.value,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._gradientPresets.map(
                  (preset) => _GradientPresetButton(
                    preset: preset,
                    selected: settings.colorMode == VisualizerColorMode.gradient &&
                        settings.primaryColorValue == preset.start &&
                        settings.secondaryColorValue == preset.end,
                    onTap: () => update(
                      (s) => s.copyWith(
                        colorMode: VisualizerColorMode.gradient,
                        primaryColorValue: preset.start,
                        secondaryColorValue: preset.end,
                      ),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final pair = _randomColorPair();
                    update(
                      (s) => s.copyWith(
                        colorMode: VisualizerColorMode.random,
                        primaryColorValue: pair.$1,
                        secondaryColorValue: pair.$2,
                      ),
                    );
                  },
                  icon: const Icon(Icons.casino_outlined, size: 18),
                  label: const Text('Random Color'),
                ),
              ],
            ),
            sectionLabel('Background'),
            _ColorSwatch(
              label: 'Background color',
              color: settings.backgroundColor,
              onTap: () async {
                final color = await showMihadColorPicker(
                  context,
                  settings.backgroundColorValue,
                );
                if (color != null) {
                  update((s) => s.copyWith(backgroundColorValue: color));
                }
              },
            ),
            slider(
              'Background opacity',
              settings.backgroundOpacity,
              0,
              1,
              (v) => update((s) => s.copyWith(backgroundOpacity: v)),
              valueLabel: '${(settings.backgroundOpacity * 100).round()}%',
              divisions: 100,
            ),
            slider(
              'Corner radius',
              settings.cornerRadius,
              0,
              1,
              (v) => update((s) => s.copyWith(cornerRadius: v)),
              valueLabel: '${(settings.cornerRadius * 100).round()}%',
              divisions: 100,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Border'),
              subtitle: const Text('Draw a rounded outline around the box'),
              value: settings.borderEnabled,
              onChanged: (v) => update((s) => s.copyWith(borderEnabled: v)),
            ),
            if (settings.borderEnabled) ...[
              _ColorSwatch(
                label: 'Border color',
                color: settings.borderColor,
                onTap: () async {
                  final color = await showMihadColorPicker(
                    context,
                    settings.borderColorValue,
                  );
                  if (color != null) {
                    update((s) => s.copyWith(borderColorValue: color));
                  }
                },
              ),
              slider(
                'Border opacity',
                settings.borderOpacity,
                0,
                1,
                (v) => update((s) => s.copyWith(borderOpacity: v)),
                valueLabel: '${(settings.borderOpacity * 100).round()}%',
                divisions: 100,
              ),
              slider(
                'Border width',
                settings.borderWidth,
                0.5,
                12,
                (v) => update((s) => s.copyWith(borderWidth: v)),
                valueLabel: '${settings.borderWidth.toStringAsFixed(1)} px',
              ),
            ],
            sectionLabel('Equalizer / Wave'),
            DropdownButtonFormField<VisualizerEffect>(
              initialValue: settings.visualizerEffect,
              decoration: const InputDecoration(
                labelText: 'Type',
                helperText: 'Different canvas algorithms: classic, soft, peak hold, stepped, fade, cinematic.',
              ),
              items: VisualizerEffect.values
                  .map(
                    (effect) => DropdownMenuItem(
                      value: effect,
                      child: Text(effect.label),
                    ),
                  )
                  .toList(),
              onChanged: (effect) {
                if (effect == null) return;
                update(
                  (s) => s.copyWith(
                    visualizerEffect: effect,
                    peakHoldEnabled: effect == VisualizerEffect.peakHold
                        ? true
                        : s.peakHoldEnabled,
                    barCount: effect == VisualizerEffect.cinematicPulse
                        ? s.barCount.clamp(20, 40).toInt()
                        : s.barCount,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            slider(
              'Opacity',
              settings.waveOpacity,
              0,
              1,
              (v) => update((s) => s.copyWith(waveOpacity: v)),
              valueLabel: '${(settings.waveOpacity * 100).round()}%',
              divisions: 100,
            ),
            slider(
              'Glow',
              settings.glowIntensity,
              0,
              1,
              (v) => update((s) => s.copyWith(glowIntensity: v)),
              valueLabel: '${(settings.glowIntensity * 100).round()}%',
              divisions: 100,
            ),
            slider(
              'Bar thickness',
              settings.barWidth,
              1,
              6,
              (v) => update((s) => s.copyWith(barWidth: v)),
              valueLabel: '${settings.barWidth.toStringAsFixed(1)} px',
              divisions: 50,
            ),
            slider(
              'Sensitivity',
              settings.sensitivity,
              0.2,
              2.0,
              (v) => update((s) => s.copyWith(sensitivity: v)),
              valueLabel: '${((settings.sensitivity / 2.0) * 100).round()}%',
              divisions: 90,
            ),
            slider(
              'Max height',
              settings.waveHeight,
              0.05,
              1,
              (v) => update((s) => s.copyWith(waveHeight: v)),
              valueLabel: '${(settings.waveHeight * 100).round()}%',
              divisions: 95,
            ),
            slider(
              'Impact sensitivity',
              settings.impactSensitivity,
              0,
              1,
              (v) => update((s) => s.copyWith(impactSensitivity: v)),
              valueLabel: '${(settings.impactSensitivity * 100).round()}%',
              divisions: 100,
            ),
            slider(
              'Attack',
              settings.attack,
              0,
              1,
              (v) => update((s) => s.copyWith(attack: v)),
              valueLabel: '${(settings.attack * 100).round()}%',
              divisions: 100,
            ),
            slider(
              'Release',
              settings.release,
              0,
              1,
              (v) => update((s) => s.copyWith(release: v)),
              valueLabel: '${(settings.release * 100).round()}%',
              divisions: 100,
            ),
            const SizedBox(height: 8),
            const Text(
              'Density',
              style: TextStyle(fontSize: 13, color: MihadColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SegmentedButton<VisualizerDensity>(
              segments: VisualizerDensity.values
                  .map(
                    (density) => ButtonSegment(
                      value: density,
                      label: Text(density.label),
                    ),
                  )
                  .toList(),
              selected: {settings.density},
              onSelectionChanged: (set) => update(
                (s) => s.copyWith(
                  density: set.first,
                  barCount: switch (set.first) {
                    VisualizerDensity.low => 28,
                    VisualizerDensity.medium => 48,
                    VisualizerDensity.high => 68,
                    VisualizerDensity.ultra => 96,
                  },
                ),
              ),
            ),
            slider(
              'Fine bar count',
              settings.barCount.toDouble(),
              24,
              100,
              (v) => update((s) => s.copyWith(barCount: v.round())),
              valueLabel: '${settings.barCount} bars',
              divisions: 76,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bar gap',
              style: TextStyle(fontSize: 13, color: MihadColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SegmentedButton<VisualizerBarGap>(
              segments: VisualizerBarGap.values
                  .map(
                    (gap) => ButtonSegment(
                      value: gap,
                      label: Text(gap.label),
                    ),
                  )
                  .toList(),
              selected: {settings.barGap},
              onSelectionChanged: (set) => update(
                (s) => s.copyWith(barGap: set.first),
              ),
            ),
            slider(
              'Smoothing',
              settings.smoothing,
              0,
              1,
              (v) => update((s) => s.copyWith(smoothing: v)),
              valueLabel: '${(settings.smoothing * 100).round()}%',
              divisions: 100,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mirror mode'),
              subtitle: const Text('Off by default: fixed bottom, top moves only'),
              value: settings.mirrored,
              onChanged: (v) => update((s) => s.copyWith(mirrored: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Peak hold markers'),
              subtitle: const Text('Shows small falling peak caps for music meters'),
              value: settings.peakHoldEnabled,
              onChanged: (v) => update((s) => s.copyWith(peakHoldEnabled: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Baseline / center line'),
              subtitle: const Text('Subtle fixed anchor line for the equalizer'),
              value: settings.centerLineEnabled,
              onChanged: (v) => update((s) => s.copyWith(centerLineEnabled: v)),
            ),

            sectionLabel('Alignment'),
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
                update(
                  (s) => s.copyWith(
                    alignment: alignment,
                    posX: posX.clamp(0.0, 1.0).toDouble(),
                  ),
                );
              },
            ),
            sectionLabel('Position'),
            slider(
              'Position X',
              settings.posX.clamp(0.0, 1.0).toDouble(),
              0,
              (1 - settings.width).clamp(0.0, 1.0).toDouble(),
              (v) => update((s) => s.copyWith(posX: v)),
              valueLabel: '${(settings.posX * 100).round()}%',
              divisions: 100,
            ),
            slider(
              'Position Y',
              settings.posY.clamp(0.0, 1.0).toDouble(),
              0,
              (1 - settings.height).clamp(0.0, 1.0).toDouble(),
              (v) => update((s) => s.copyWith(posY: v)),
              valueLabel: '${(settings.posY * 100).round()}%',
              divisions: 100,
            ),
            sectionLabel('Size'),
            slider(
              'Width',
              settings.width.clamp(0.05, 1.0).toDouble(),
              0.05,
              1,
              (v) => update(
                (s) => s.copyWith(
                  width: v,
                  posX: s.posX.clamp(0.0, 1 - v).toDouble(),
                ),
              ),
              valueLabel: '${(settings.width * 100).round()}%',
              divisions: 95,
            ),
            slider(
              'Height',
              settings.height.clamp(0.05, 1.0).toDouble(),
              0.05,
              1,
              (v) => update(
                (s) => s.copyWith(
                  height: v,
                  posY: s.posY.clamp(0.0, 1 - v).toDouble(),
                ),
              ),
              valueLabel: '${(settings.height * 100).round()}%',
              divisions: 95,
            ),
            sectionLabel('Export aspect ratio'),
            Wrap(
              spacing: 8,
              children: ExportAspectRatio.values.map((ratio) {
                return ChoiceChip(
                  label: Text(ratio.label),
                  selected: settings.aspectRatio == ratio,
                  onSelected: (_) => update(
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

String _modeForTemplate(VisualizerTemplateType template) {
  switch (template) {
    case VisualizerTemplateType.spectrumBars:
    case VisualizerTemplateType.equalizerBars:
    case VisualizerTemplateType.frequencyWave:
    case VisualizerTemplateType.rainbowWave:
    case VisualizerTemplateType.classicBars:
    case VisualizerTemplateType.roundedBars:
    case VisualizerTemplateType.thinBars:
    case VisualizerTemplateType.thickBars:
    case VisualizerTemplateType.gradientBars:
    case VisualizerTemplateType.bassPulse:
      return 'spectrum';
    case VisualizerTemplateType.cinematicWave:
    case VisualizerTemplateType.cinematicGlow:
    case VisualizerTemplateType.tripleWave:
    case VisualizerTemplateType.floatingBars:
      return 'cinematic';
    default:
      return 'waveform';
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: MihadColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NamedColorPreset {
  final String label;
  final int value;
  const _NamedColorPreset(this.label, this.value);
}

class _GradientPreset {
  final String label;
  final int start;
  final int end;
  const _GradientPreset(this.label, this.start, this.end);
}

const _singleColorPresets = [
  _NamedColorPreset('White', 0xFFFFFFFF),
  _NamedColorPreset('Black', 0xFF000000),
  _NamedColorPreset('Red', 0xFFFF3B30),
  _NamedColorPreset('Orange', 0xFFFF9500),
  _NamedColorPreset('Yellow', 0xFFFFCC00),
  _NamedColorPreset('Green', 0xFF34C759),
  _NamedColorPreset('Cyan', 0xFF00E5FF),
  _NamedColorPreset('Blue', 0xFF0A84FF),
  _NamedColorPreset('Purple', 0xFFBF5AF2),
  _NamedColorPreset('Pink', 0xFFFF2D55),
];

const _gradientPresets = [
  _GradientPreset('Pink-Purple', 0xFFFF2D55, 0xFFBF5AF2),
  _GradientPreset('Blue-Cyan', 0xFF0A84FF, 0xFF00E5FF),
  _GradientPreset('Red-Orange', 0xFFFF3B30, 0xFFFF9500),
  _GradientPreset('Yellow-Green', 0xFFFFCC00, 0xFF34C759),
  _GradientPreset('Rainbow', 0xFFFF2D55, 0xFF0A84FF),
];

class _GradientPresetButton extends StatelessWidget {
  final _GradientPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _GradientPresetButton({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? MihadColors.accentPrimary : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [Color(preset.start), Color(preset.end)],
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(preset.label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

(int, int) _randomColorPair() {
  final random = math.Random();
  int vivid() {
    final hue = random.nextDouble() * 360;
    final sat = 0.68 + random.nextDouble() * 0.25;
    final val = 0.82 + random.nextDouble() * 0.16;
    return _hsvColor(hue, sat, val);
  }

  final first = vivid();
  var second = vivid();
  var guard = 0;
  while ((first - second).abs() < 0x00202020 && guard < 8) {
    second = vivid();
    guard++;
  }
  return (first, second);
}

int _hsvColor(double hue, double saturation, double value) {
  final h = ((hue % 360) + 360) % 360;
  final c = value * saturation;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = value - c;
  double r = 0, g = 0, b = 0;
  if (h < 60) {
    r = c;
    g = x;
  } else if (h < 120) {
    r = x;
    g = c;
  } else if (h < 180) {
    g = c;
    b = x;
  } else if (h < 240) {
    g = x;
    b = c;
  } else if (h < 300) {
    r = x;
    b = c;
  } else {
    r = c;
    b = x;
  }
  final red = ((r + m) * 255).round().clamp(0, 255).toInt();
  final green = ((g + m) * 255).round().clamp(0, 255).toInt();
  final blue = ((b + m) * 255).round().clamp(0, 255).toInt();
  return (0xFF << 24) | (red << 16) | (green << 8) | blue;
}
