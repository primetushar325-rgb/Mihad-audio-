import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mihad_audio/models/project.dart';
import 'package:mihad_audio/models/subtitle_catalog.dart';
import 'package:mihad_audio/models/subtitle_models.dart';
import 'package:mihad_audio/services/subtitle_io_service.dart';
import 'package:mihad_audio/subtitles/subtitle_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('subtitle catalog has many distinct free templates and Bangla fonts', () {
    expect(kSubtitleTemplates.length, greaterThanOrEqualTo(40));
    expect(kSubtitleTemplates.map((t) => t.id).toSet().length, kSubtitleTemplates.length);
    expect(kSubtitleFonts.where((font) => font.supportsBangla).length, greaterThanOrEqualTo(8));
    expect(kSubtitleTemplates.any((t) => t.id == 'horror_pro'), isTrue);
    expect(kSubtitleTemplates.any((t) => t.category == 'KARAOKE'), isTrue);
  });

  test('subtitle project data round-trips through Project JSON', () {
    final cue = SubtitleCue(
      id: 'cue1',
      layerId: 'layer1',
      text: 'আজ রাতে তুমি একা বাইরে যেও না',
      startMs: 100,
      endMs: 2100,
      words: const [
        SubtitleWordTiming(word: 'আজ', startMs: 100, endMs: 300),
      ],
      style: subtitleTemplateById('horror_pro').style,
    );
    final project = Project(
      id: 'p1',
      name: 'Subtitles',
      subtitleLayers: [SubtitleLayer(id: 'layer1', name: 'Bangla', cues: [cue])],
      selectedSubtitleId: cue.id,
      favoriteSubtitleTemplateIds: const ['horror_pro'],
      favoriteFontFamilies: const ['Noto Sans Bengali'],
      savedSubtitleStyles: [cue.style],
    );

    final restored = Project.fromJson(project.toJson());

    expect(restored.subtitleLayers.single.cues.single.text, cue.text);
    expect(restored.selectedSubtitleId, cue.id);
    expect(restored.favoriteSubtitleTemplateIds, contains('horror_pro'));
    expect(restored.favoriteFontFamilies, contains('Noto Sans Bengali'));
    expect(restored.savedSubtitleStyles.single.templateId, 'horror_pro');
  });

  test('SRT and VTT import/export preserve timings and Bangla text', () {
    final io = SubtitleIoService();
    final cues = io.parseSrt('''
1
00:00:01,000 --> 00:00:03,500
এই গল্পটা শুরু হয়েছিল মধ্যরাতে...

2
00:00:04,000 --> 00:00:05,200
Do not go outside!
''');

    expect(cues, hasLength(2));
    expect(cues.first.text, contains('মধ্যরাতে'));
    expect(cues.first.words, isNotEmpty);

    final srt = io.toSrt(cues);
    final vtt = io.toVtt(cues);
    expect(srt, contains('00:00:01,000'));
    expect(vtt, startsWith('WEBVTT'));
    expect(io.parseVtt(vtt), hasLength(2));
  });

  test('subtitle renderer paints without throwing', () {
    final layer = SubtitleLayer(
      id: 'layer1',
      name: 'Layer',
      cues: [
        SubtitleCue(
          id: 'cue1',
          layerId: 'layer1',
          text: 'বাংলা লেখা English 123',
          startMs: 0,
          endMs: 3000,
          words: const [
            SubtitleWordTiming(word: 'বাংলা', startMs: 0, endMs: 500),
            SubtitleWordTiming(word: 'লেখা', startMs: 500, endMs: 1000),
          ],
          style: subtitleTemplateById('blue_neon').style,
        ),
      ],
    );

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    expect(
      () => paintSubtitles(
        canvas: canvas,
        size: const ui.Size(1080, 1920),
        layers: [layer],
        positionMs: 650,
      ),
      returnsNormally,
    );
    recorder.endRecording().dispose();
  });
}
