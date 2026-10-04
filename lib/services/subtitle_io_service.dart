import '../models/subtitle_catalog.dart';
import '../models/subtitle_models.dart';

class SubtitleIoService {
  List<SubtitleCue> parseSrt(String input, {String layerId = 'subtitles'}) {
    final blocks = input.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'));
    final cues = <SubtitleCue>[];
    for (final block in blocks) {
      final lines = block.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;
      final timeLineIndex = lines.indexWhere((line) => line.contains('-->'));
      if (timeLineIndex == -1) continue;
      final times = lines[timeLineIndex].split('-->');
      if (times.length != 2) continue;
      final start = _parseTime(times[0].trim());
      final end = _parseTime(times[1].trim());
      if (start == null || end == null || end <= start) continue;
      final text = lines.skip(timeLineIndex + 1).join('\n').trim();
      cues.add(_cue(layerId, text, start, end));
    }
    return cues;
  }

  List<SubtitleCue> parseVtt(String input, {String layerId = 'subtitles'}) {
    final cleaned = input.replaceFirst(RegExp(r'^WEBVTT[^\n]*\n+', multiLine: false), '');
    return parseSrt(cleaned, layerId: layerId);
  }

  List<SubtitleCue> parseTxt(String input, {String layerId = 'subtitles'}) {
    final lines = input.split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty).toList();
    var cursor = 0.0;
    return lines.map((line) {
      final duration = (line.trim().split(RegExp(r'\s+')).length * 420).clamp(1400, 5200).toDouble();
      final cue = _cue(layerId, line.trim(), cursor, cursor + duration);
      cursor += duration;
      return cue;
    }).toList();
  }

  String toSrt(List<SubtitleCue> cues) {
    final ordered = [...cues]..sort((a, b) => a.startMs.compareTo(b.startMs));
    final out = StringBuffer();
    for (var i = 0; i < ordered.length; i++) {
      final cue = ordered[i];
      out
        ..writeln(i + 1)
        ..writeln('${_formatTime(cue.startMs, comma: true)} --> ${_formatTime(cue.endMs, comma: true)}')
        ..writeln(cue.text)
        ..writeln();
    }
    return out.toString();
  }

  String toVtt(List<SubtitleCue> cues) {
    final ordered = [...cues]..sort((a, b) => a.startMs.compareTo(b.startMs));
    final out = StringBuffer('WEBVTT\n\n');
    for (final cue in ordered) {
      out
        ..writeln('${_formatTime(cue.startMs)} --> ${_formatTime(cue.endMs)}')
        ..writeln(cue.text)
        ..writeln();
    }
    return out.toString();
  }

  String toTxt(List<SubtitleCue> cues) {
    final ordered = [...cues]..sort((a, b) => a.startMs.compareTo(b.startMs));
    return ordered.map((cue) => cue.text).join('\n');
  }

  SubtitleCue _cue(String layerId, String text, double start, double end) {
    return SubtitleCue(
      id: newSubtitleId('subtitle'),
      layerId: layerId,
      text: text,
      startMs: start,
      endMs: end,
      words: _words(text, start, end),
      style: subtitleTemplateById('story_clean_white').style,
    );
  }

  List<SubtitleWordTiming> _words(String text, double start, double end) {
    final words = text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    final step = (end - start) / words.length;
    return List.generate(words.length, (index) {
      final s = start + step * index;
      return SubtitleWordTiming(
        word: words[index],
        startMs: s,
        endMs: index == words.length - 1 ? end : s + step,
      );
    });
  }

  double? _parseTime(String text) {
    final cleaned = text.replaceAll(',', '.');
    final parts = cleaned.split(':');
    if (parts.length < 3) return null;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = double.tryParse(parts.sublist(2).join(':')) ?? 0;
    return ((hours * 3600 + minutes * 60 + seconds) * 1000).toDouble();
  }

  String _formatTime(double ms, {bool comma = false}) {
    final totalMs = ms.round().clamp(0, 1 << 40).toInt();
    final hours = totalMs ~/ 3600000;
    final minutes = (totalMs % 3600000) ~/ 60000;
    final seconds = (totalMs % 60000) ~/ 1000;
    final millis = totalMs % 1000;
    final sep = comma ? ',' : '.';
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}$sep${millis.toString().padLeft(3, '0')}';
  }
}
