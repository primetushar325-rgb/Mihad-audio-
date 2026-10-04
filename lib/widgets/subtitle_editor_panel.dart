import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/subtitle_catalog.dart';
import '../models/subtitle_models.dart';
import '../services/subtitle_io_service.dart';
import '../state/editor_provider.dart';
import '../widgets/color_picker_sheet.dart';

class SubtitleEditorPanel extends StatelessWidget {
  final EditorProvider editor;
  const SubtitleEditorPanel({super.key, required this.editor});

  @override
  Widget build(BuildContext context) {
    final layers = editor.subtitleLayers;
    final selected = editor.selectedSubtitle;
    final cues = layers.expand((layer) => layer.cues).toList()
      ..sort((a, b) => a.startMs.compareTo(b.startMs));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Subtitles & Motion Text',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
                IconButton(
                  tooltip: 'Add Subtitle',
                  onPressed: () => editor.addManualSubtitle(),
                  icon: const Icon(Icons.add_comment_outlined),
                ),
                IconButton(
                  tooltip: 'Auto Subtitle',
                  onPressed: () async {
                    final message = await editor.requestAutoSubtitleFallback();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    }
                  },
                  icon: const Icon(Icons.auto_awesome),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Free/offline subtitle tools. Auto transcription falls back to manual captions when no local recognizer is available.',
              style: TextStyle(fontSize: 11.5, color: MihadColors.textSecondary),
            ),
            const SizedBox(height: 10),
            if (layers.isNotEmpty) _LayerControls(editor: editor, layer: layers.first),
            const SizedBox(height: 8),
            _SubtitleTimeline(editor: editor, cues: cues),
            const SizedBox(height: 12),
            if (selected == null)
              const Text(
                'Select a subtitle block or tap Add Subtitle to start.',
                style: TextStyle(color: MihadColors.textSecondary),
              )
            else
              _SelectedSubtitleEditor(editor: editor, cue: selected),
          ],
        ),
      ),
    );
  }
}

class _LayerControls extends StatelessWidget {
  final EditorProvider editor;
  final SubtitleLayer layer;
  const _LayerControls({required this.editor, required this.layer});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterChip(
          label: Text(layer.visible ? 'Layer visible' : 'Layer hidden'),
          selected: layer.visible,
          onSelected: (_) => editor.updateSubtitleLayer(layer.id, (l) => l.copyWith(visible: !l.visible)),
        ),
        FilterChip(
          label: Text(layer.locked ? 'Layer locked' : 'Layer unlocked'),
          selected: layer.locked,
          onSelected: (_) => editor.updateSubtitleLayer(layer.id, (l) => l.copyWith(locked: !l.locked)),
        ),
        OutlinedButton.icon(
          onPressed: () => _showRenameLayer(context, editor, layer),
          icon: const Icon(Icons.drive_file_rename_outline, size: 16),
          label: Text(layer.name),
        ),
      ],
    );
  }

  Future<void> _showRenameLayer(BuildContext context, EditorProvider editor, SubtitleLayer layer) async {
    final controller = TextEditingController(text: layer.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename subtitle layer'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await editor.updateSubtitleLayer(layer.id, (l) => l.copyWith(name: name));
    }
  }
}

class _SubtitleTimeline extends StatelessWidget {
  final EditorProvider editor;
  final List<SubtitleCue> cues;
  const _SubtitleTimeline({required this.editor, required this.cues});

  @override
  Widget build(BuildContext context) {
    final durationMs = editor.videoController?.value.duration.inMilliseconds.toDouble() ?? 1;
    if (cues.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MihadColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('Subtitle timeline is empty.', style: TextStyle(color: MihadColors.textSecondary)),
      );
    }
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cues.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cue = cues[index];
          final selected = cue.id == editor.selectedSubtitleId;
          final width = (cue.durationMs / durationMs * 420).clamp(96.0, 210.0).toDouble();
          return GestureDetector(
            onTap: () => editor.selectSubtitle(cue.id),
            onHorizontalDragUpdate: (details) {
              final deltaMs = details.delta.dx * 18;
              final nextStart = (cue.startMs + deltaMs).clamp(0.0, durationMs).toDouble();
              final nextEnd = (nextStart + cue.durationMs).clamp(nextStart + 100, durationMs + cue.durationMs).toDouble();
              editor.updateSubtitleCue(cue.id, (c) => c.copyWith(startMs: nextStart, endMs: nextEnd));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: width,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: selected ? MihadColors.accentPrimary.withValues(alpha: 0.22) : MihadColors.surfaceElevated,
                border: Border.all(color: selected ? MihadColors.accentPrimary : Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cue.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${_fmt(cue.startMs)} — ${_fmt(cue.endMs)}', style: const TextStyle(fontSize: 10.5, color: MihadColors.textSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmt(double ms) {
    final d = Duration(milliseconds: ms.round());
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _SelectedSubtitleEditor extends StatelessWidget {
  final EditorProvider editor;
  final SubtitleCue cue;
  const _SelectedSubtitleEditor({required this.editor, required this.cue});

  @override
  Widget build(BuildContext context) {
    final durationMs = editor.videoController?.value.duration.inMilliseconds.toDouble() ?? cue.endMs;
    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(onPressed: () => editor.duplicateSubtitle(cue.id), icon: const Icon(Icons.copy, size: 16), label: const Text('Duplicate')),
              OutlinedButton.icon(onPressed: () => editor.splitSubtitle(cue.id), icon: const Icon(Icons.call_split, size: 16), label: const Text('Split')),
              OutlinedButton.icon(onPressed: editor.mergeSelectedSubtitleWithNext, icon: const Icon(Icons.merge_type, size: 16), label: const Text('Merge next')),
              OutlinedButton.icon(onPressed: () => editor.deleteSubtitle(cue.id), icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Delete')),
              OutlinedButton.icon(onPressed: () => editor.saveSubtitleStyle(cue.id), icon: const Icon(Icons.save_alt, size: 16), label: const Text('Save Style')),
              OutlinedButton.icon(onPressed: () => _showImportText(context), icon: const Icon(Icons.file_upload_outlined, size: 16), label: const Text('Import')),
              OutlinedButton.icon(onPressed: () => _showExportText(context), icon: const Icon(Icons.file_download_outlined, size: 16), label: const Text('SRT/VTT')),
            ],
          ),
          const SizedBox(height: 10),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'TEXT'),
              Tab(text: 'TEMPLATES'),
              Tab(text: 'FONTS'),
              Tab(text: 'STYLE'),
              Tab(text: 'EFFECTS'),
            ],
          ),
          SizedBox(
            height: 430,
            child: TabBarView(
              children: [
                _TextTab(editor: editor, cue: cue, durationMs: durationMs),
                _TemplatesTab(editor: editor, cue: cue),
                _FontsTab(editor: editor, cue: cue),
                _StyleTab(editor: editor, cue: cue),
                _EffectsTab(editor: editor, cue: cue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportText(BuildContext context) async {
    final controller = TextEditingController();
    var format = 'srt';
    final imported = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Import subtitles'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: format,
                  decoration: const InputDecoration(labelText: 'Format'),
                  items: const [
                    DropdownMenuItem(value: 'srt', child: Text('SRT')),
                    DropdownMenuItem(value: 'vtt', child: Text('VTT')),
                    DropdownMenuItem(value: 'txt', child: Text('TXT lines')),
                  ],
                  onChanged: (value) => setState(() => format = value ?? 'srt'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Paste subtitle text',
                    hintText: '00:00:01,000 --> 00:00:03,000\nএই গল্পটা শুরু হয়েছিল মধ্যরাতে...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final count = await editor.importSubtitlesFromText(text: controller.text, format: format);
                if (context.mounted) Navigator.pop(context, count);
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
    if (context.mounted && imported != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(imported == 0 ? 'No valid subtitle cues found.' : 'Imported $imported subtitle cues.')),
      );
    }
  }

  void _showExportText(BuildContext context) {
    final all = editor.subtitleLayers.expand((layer) => layer.cues).toList();
    final io = SubtitleIoService();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subtitle export text'),
        content: SingleChildScrollView(
          child: SelectableText('SRT:\n${io.toSrt(all)}\nVTT:\n${io.toVtt(all)}'),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}

class _TextTab extends StatelessWidget {
  final EditorProvider editor;
  final SubtitleCue cue;
  final double durationMs;
  const _TextTab({required this.editor, required this.cue, required this.durationMs});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        TextFormField(
          key: ValueKey(cue.id),
          initialValue: cue.text,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Subtitle text', helperText: 'Bangla conjuncts and manual line breaks are supported.'),
          onChanged: (v) => editor.updateSubtitleCue(cue.id, (c) => c.copyWith(text: v)),
        ),
        _slider('Start', cue.startMs, 0, durationMs, (v) => editor.updateSubtitleCue(cue.id, (c) => c.copyWith(startMs: v.clamp(0, c.endMs - 100).toDouble())), valueLabel: _time(cue.startMs)),
        _slider('End', cue.endMs, 0, durationMs + 5000, (v) => editor.updateSubtitleCue(cue.id, (c) => c.copyWith(endMs: v.clamp(c.startMs + 100, durationMs + 5000).toDouble())), valueLabel: _time(cue.endMs)),
        _slider('Position X', cue.posX, 0, 1 - cue.width, (v) => editor.updateSubtitleCue(cue.id, (c) => c.copyWith(posX: v)), valueLabel: '${(cue.posX * 100).round()}%'),
        _slider('Position Y', cue.posY, 0, 1 - cue.height, (v) => editor.updateSubtitleCue(cue.id, (c) => c.copyWith(posY: v)), valueLabel: '${(cue.posY * 100).round()}%'),
        _slider('Scale', cue.scale, 0.5, 2.2, (v) => editor.updateSubtitleCue(cue.id, (c) => c.copyWith(scale: v)), valueLabel: '${(cue.scale * 100).round()}%'),
        _slider('Rotation', cue.rotation, -25, 25, (v) => editor.updateSubtitleCue(cue.id, (c) => c.copyWith(rotation: v)), valueLabel: '${cue.rotation.toStringAsFixed(1)}°'),
      ],
    );
  }
}

class _TemplatesTab extends StatelessWidget {
  final EditorProvider editor;
  final SubtitleCue cue;
  const _TemplatesTab({required this.editor, required this.cue});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: kSubtitleTemplates.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 210, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.15),
      itemBuilder: (context, index) {
        final template = kSubtitleTemplates[index];
        final selected = cue.style.templateId == template.id;
        return InkWell(
          onTap: () => editor.applySubtitleTemplate(cue.id, template.id),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MihadColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? MihadColors.accentPrimary : Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('এই গল্পটা শুরু হয়েছিল মধ্যরাতে...', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: template.style.fontFamily, fontWeight: FontWeight.w700, color: Color(template.style.colorValue), shadows: [Shadow(color: template.style.glowColor, blurRadius: template.style.glowIntensity * 18)])),
                const Spacer(),
                Text(template.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                Text(template.category, style: const TextStyle(fontSize: 10.5, color: MihadColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FontsTab extends StatefulWidget {
  final EditorProvider editor;
  final SubtitleCue cue;
  const _FontsTab({required this.editor, required this.cue});

  @override
  State<_FontsTab> createState() => _FontsTabState();
}

class _FontsTabState extends State<_FontsTab> {
  String query = '';
  String filter = 'BANGLA';

  @override
  Widget build(BuildContext context) {
    final fonts = kSubtitleFonts.where((font) {
      final q = query.toLowerCase();
      final matchQuery = q.isEmpty || font.displayName.toLowerCase().contains(q) || font.categories.any((c) => c.toLowerCase().contains(q));
      final matchFilter = filter == 'ALL' || font.categories.contains(filter);
      return matchQuery && matchFilter;
    }).toList();
    return Column(
      children: [
        TextField(decoration: const InputDecoration(labelText: 'Search fonts...'), onChanged: (v) => setState(() => query = v)),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['ALL', 'BANGLA', 'ENGLISH', 'HORROR', 'CINEMATIC', 'GAMING', 'HANDWRITTEN', 'BOLD', 'MINIMAL']
                .map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(label: Text(cat), selected: filter == cat, onSelected: (_) => setState(() => filter = cat)),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: fonts.length,
            itemBuilder: (context, index) {
              final font = fonts[index];
              return ListTile(
                title: Text(font.displayName, style: TextStyle(fontFamily: font.family, fontWeight: FontWeight.w700)),
                subtitle: Text('বাংলা লেখা English Text 123456', style: TextStyle(fontFamily: font.family)),
                trailing: widget.cue.style.fontFamily == font.family ? const Icon(Icons.check_circle, color: MihadColors.accentPrimary) : null,
                onTap: () => widget.editor.updateSubtitleCue(widget.cue.id, (c) => c.copyWith(style: c.style.copyWith(fontFamily: font.family))),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StyleTab extends StatelessWidget {
  final EditorProvider editor;
  final SubtitleCue cue;
  const _StyleTab({required this.editor, required this.cue});

  @override
  Widget build(BuildContext context) {
    final s = cue.style;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        _slider('Font size', s.fontSize, 18, 92, (v) => _style((st) => st.copyWith(fontSize: v)), valueLabel: s.fontSize.toStringAsFixed(0)),
        _colorButton(context, 'Text color', s.color, (v) => _style((st) => st.copyWith(colorValue: v))),
        SwitchListTile(value: s.gradientEnabled, onChanged: (v) => _style((st) => st.copyWith(gradientEnabled: v)), title: const Text('Gradient text')),
        _colorButton(context, 'Gradient start', Color(s.gradientStartValue), (v) => _style((st) => st.copyWith(gradientStartValue: v))),
        _colorButton(context, 'Gradient end', Color(s.gradientEndValue), (v) => _style((st) => st.copyWith(gradientEndValue: v))),
        SwitchListTile(value: s.strokeEnabled, onChanged: (v) => _style((st) => st.copyWith(strokeEnabled: v)), title: const Text('Stroke')),
        _slider('Stroke width', s.strokeWidth, 0, 20, (v) => _style((st) => st.copyWith(strokeWidth: v)), valueLabel: '${s.strokeWidth.toStringAsFixed(1)} px'),
        _colorButton(context, 'Stroke color', s.strokeColor, (v) => _style((st) => st.copyWith(strokeColorValue: v))),
        SwitchListTile(value: s.shadowEnabled, onChanged: (v) => _style((st) => st.copyWith(shadowEnabled: v)), title: const Text('Shadow')),
        _slider('Shadow blur', s.shadowBlur, 0, 50, (v) => _style((st) => st.copyWith(shadowBlur: v)), valueLabel: s.shadowBlur.toStringAsFixed(0)),
        _slider('Shadow distance', s.shadowDistance, 0, 40, (v) => _style((st) => st.copyWith(shadowDistance: v)), valueLabel: s.shadowDistance.toStringAsFixed(0)),
        DropdownButtonFormField<SubtitleBackgroundType>(
          initialValue: s.backgroundType,
          decoration: const InputDecoration(labelText: 'Background'),
          items: SubtitleBackgroundType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
          onChanged: (v) => v == null ? null : _style((st) => st.copyWith(backgroundType: v, backgroundOpacity: v == SubtitleBackgroundType.none ? 0 : 0.48)),
        ),
        _slider('Background opacity', s.backgroundOpacity, 0, 1, (v) => _style((st) => st.copyWith(backgroundOpacity: v)), valueLabel: '${(s.backgroundOpacity * 100).round()}%'),
      ],
    );
  }

  void _style(SubtitleTextStyleConfig Function(SubtitleTextStyleConfig s) update) {
    editor.updateSubtitleCue(cue.id, (c) => c.copyWith(style: update(c.style)));
  }
}

class _EffectsTab extends StatelessWidget {
  final EditorProvider editor;
  final SubtitleCue cue;
  const _EffectsTab({required this.editor, required this.cue});

  @override
  Widget build(BuildContext context) {
    final s = cue.style;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        SwitchListTile(value: s.glowEnabled, onChanged: (v) => _style((st) => st.copyWith(glowEnabled: v)), title: const Text('Glow')),
        _colorButton(context, 'Glow color', s.glowColor, (v) => _style((st) => st.copyWith(glowColorValue: v))),
        _colorButton(context, 'Glow core color', s.glowCoreColor, (v) => _style((st) => st.copyWith(glowCoreColorValue: v))),
        _slider('Glow intensity', s.glowIntensity, 0, 1, (v) => _style((st) => st.copyWith(glowIntensity: v)), valueLabel: '${(s.glowIntensity * 100).round()}%'),
        _slider('Glow radius', s.glowRadius, 0, 1, (v) => _style((st) => st.copyWith(glowRadius: v)), valueLabel: '${(s.glowRadius * 100).round()}%'),
        _slider('Glow spread', s.glowSpread, 0, 1, (v) => _style((st) => st.copyWith(glowSpread: v)), valueLabel: '${(s.glowSpread * 100).round()}%'),
        DropdownButtonFormField<SubtitleGlowQuality>(
          initialValue: s.glowQuality,
          decoration: const InputDecoration(labelText: 'Glow quality'),
          items: SubtitleGlowQuality.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
          onChanged: (v) => v == null ? null : _style((st) => st.copyWith(glowQuality: v)),
        ),
        DropdownButtonFormField<SubtitleHighlightMode>(
          initialValue: s.highlightMode,
          decoration: const InputDecoration(labelText: 'Word highlight'),
          items: SubtitleHighlightMode.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
          onChanged: (v) => v == null ? null : _style((st) => st.copyWith(highlightMode: v)),
        ),
        _colorButton(context, 'Highlight color', s.highlightColor, (v) => _style((st) => st.copyWith(highlightColorValue: v))),
        _slider('Highlight scale', s.highlightScale, 1, 1.8, (v) => _style((st) => st.copyWith(highlightScale: v)), valueLabel: '${(s.highlightScale * 100).round()}%'),
        DropdownButtonFormField<SubtitleAnimationType>(
          initialValue: s.inAnimation,
          decoration: const InputDecoration(labelText: 'In animation'),
          items: SubtitleAnimationType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
          onChanged: (v) => v == null ? null : _style((st) => st.copyWith(inAnimation: v)),
        ),
        DropdownButtonFormField<SubtitleLoopAnimation>(
          initialValue: s.loopAnimation,
          decoration: const InputDecoration(labelText: 'Loop / active animation'),
          items: SubtitleLoopAnimation.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
          onChanged: (v) => v == null ? null : _style((st) => st.copyWith(loopAnimation: v)),
        ),
        DropdownButtonFormField<SubtitlePerformanceQuality>(
          initialValue: s.performanceQuality,
          decoration: const InputDecoration(labelText: 'Performance quality'),
          items: SubtitlePerformanceQuality.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
          onChanged: (v) => v == null ? null : _style((st) => st.copyWith(performanceQuality: v)),
        ),
      ],
    );
  }

  void _style(SubtitleTextStyleConfig Function(SubtitleTextStyleConfig s) update) {
    editor.updateSubtitleCue(cue.id, (c) => c.copyWith(style: update(c.style)));
  }
}

Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged, {String? valueLabel}) {
  final effectiveMax = max <= min ? min + 1 : max;
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 13)), Text(valueLabel ?? value.toStringAsFixed(2), style: const TextStyle(fontSize: 12, color: MihadColors.textSecondary))]),
        Slider(value: value.clamp(min, effectiveMax).toDouble(), min: min, max: effectiveMax, onChanged: onChanged),
      ],
    ),
  );
}

Widget _colorButton(BuildContext context, String label, Color color, ValueChanged<int> onPicked) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: CircleAvatar(backgroundColor: color),
    onTap: () async {
      final picked = await showMihadColorPicker(context, color.toARGB32());
      if (picked != null) onPicked(picked);
    },
  );
}

String _time(double ms) {
  final d = Duration(milliseconds: ms.round());
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final cs = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
  return '$m:$s.$cs';
}
