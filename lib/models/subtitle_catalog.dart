import 'subtitle_models.dart';

class SubtitleFontInfo {
  final String family;
  final String displayName;
  final List<String> categories;
  final bool supportsBangla;
  final String licenseNote;

  const SubtitleFontInfo({
    required this.family,
    required this.displayName,
    required this.categories,
    required this.supportsBangla,
    this.licenseNote = 'Use a properly licensed system/app font when bundling.',
  });
}

class SubtitleTemplateInfo {
  final String id;
  final String name;
  final String category;
  final String description;
  final SubtitleTextStyleConfig style;
  final SubtitleVerticalPosition position;
  final List<String> recommendedFonts;

  const SubtitleTemplateInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.style,
    this.position = SubtitleVerticalPosition.lower,
    this.recommendedFonts = const [],
  });
}

const List<SubtitleFontInfo> kSubtitleFonts = [
  SubtitleFontInfo(family: 'Noto Sans Bengali', displayName: 'Noto Sans Bengali', categories: ['BANGLA', 'STORY', 'CLEAN', 'MODERN'], supportsBangla: true, licenseNote: 'Open-source Noto font family.'),
  SubtitleFontInfo(family: 'Noto Serif Bengali', displayName: 'Noto Serif Bengali', categories: ['BANGLA', 'HORROR', 'CINEMATIC', 'DOCUMENTARY'], supportsBangla: true, licenseNote: 'Open-source Noto font family.'),
  SubtitleFontInfo(family: 'Hind Siliguri', displayName: 'Hind Siliguri', categories: ['BANGLA', 'STORY', 'CLEAN'], supportsBangla: true, licenseNote: 'Open-source font; bundle only with license file.'),
  SubtitleFontInfo(family: 'Anek Bangla', displayName: 'Anek Bangla', categories: ['BANGLA', 'MODERN', 'BOLD'], supportsBangla: true),
  SubtitleFontInfo(family: 'Baloo Da 2', displayName: 'Baloo Da 2', categories: ['BANGLA', 'COMIC', 'BOLD'], supportsBangla: true),
  SubtitleFontInfo(family: 'Atma', displayName: 'Atma', categories: ['BANGLA', 'HANDWRITTEN', 'STORY'], supportsBangla: true),
  SubtitleFontInfo(family: 'Galada', displayName: 'Galada', categories: ['BANGLA', 'HANDWRITTEN', 'EMOTIONAL'], supportsBangla: true),
  SubtitleFontInfo(family: 'Mina', displayName: 'Mina', categories: ['BANGLA', 'CLEAN', 'NEWS'], supportsBangla: true),
  SubtitleFontInfo(family: 'Tiro Bangla', displayName: 'Tiro Bangla', categories: ['BANGLA', 'SERIF', 'HORROR', 'CINEMATIC'], supportsBangla: true),
  SubtitleFontInfo(family: 'Roboto', displayName: 'Roboto', categories: ['ENGLISH', 'CLEAN', 'MODERN'], supportsBangla: false),
  SubtitleFontInfo(family: 'Roboto Condensed', displayName: 'Roboto Condensed', categories: ['ENGLISH', 'NEWS', 'BOLD'], supportsBangla: false),
  SubtitleFontInfo(family: 'Noto Sans', displayName: 'Noto Sans', categories: ['ENGLISH', 'CLEAN', 'DOCUMENTARY'], supportsBangla: false),
  SubtitleFontInfo(family: 'Noto Serif', displayName: 'Noto Serif', categories: ['ENGLISH', 'CINEMATIC', 'LUXURY'], supportsBangla: false),
  SubtitleFontInfo(family: 'Serif', displayName: 'System Serif', categories: ['ENGLISH', 'HORROR', 'CINEMATIC'], supportsBangla: false),
  SubtitleFontInfo(family: 'Sans', displayName: 'System Sans', categories: ['ENGLISH', 'MODERN', 'MINIMAL'], supportsBangla: false),
  SubtitleFontInfo(family: 'Monospace', displayName: 'System Mono', categories: ['ENGLISH', 'GAMING', 'RETRO'], supportsBangla: false),
];

SubtitleTextStyleConfig subtitleStyle({
  String templateId = 'custom',
  String font = 'Noto Sans Bengali',
  int weight = 700,
  double size = 44,
  int color = 0xFFFFFFFF,
  int stroke = 0xFF000000,
  double strokeWidth = 3.5,
  int glow = 0x6638BDF8,
  double glowIntensity = 0.22,
  int highlight = 0xFFFFD54F,
  SubtitleAnimationType inAnim = SubtitleAnimationType.fade,
  SubtitleAnimationType outAnim = SubtitleAnimationType.fade,
  SubtitleLoopAnimation loop = SubtitleLoopAnimation.none,
  SubtitleHighlightMode highlightMode = SubtitleHighlightMode.color,
  SubtitleBackgroundType background = SubtitleBackgroundType.none,
  int backgroundColor = 0xCC000000,
  double backgroundOpacity = 0,
  bool gradient = false,
  int gradientStart = 0xFFFFFFFF,
  int gradientEnd = 0xFFFFD54F,
  SubtitleGlowQuality glowQuality = SubtitleGlowQuality.medium,
}) {
  return SubtitleTextStyleConfig(
    templateId: templateId,
    fontFamily: font,
    fontWeight: weight,
    fontSize: size,
    colorValue: color,
    strokeColorValue: stroke,
    strokeWidth: strokeWidth,
    glowColorValue: glow,
    glowIntensity: glowIntensity,
    glowRadius: glowIntensity,
    glowOpacity: (0.28 + glowIntensity).clamp(0.0, 1.0).toDouble(),
    highlightColorValue: highlight,
    inAnimation: inAnim,
    outAnimation: outAnim,
    loopAnimation: loop,
    highlightMode: highlightMode,
    backgroundType: background,
    backgroundColorValue: backgroundColor,
    backgroundOpacity: backgroundOpacity,
    gradientEnabled: gradient,
    gradientStartValue: gradientStart,
    gradientEndValue: gradientEnd,
    glowQuality: glowQuality,
  );
}

const _banglaStoryFonts = ['Hind Siliguri', 'Noto Sans Bengali', 'Noto Serif Bengali'];
const _horrorFonts = ['Noto Serif Bengali', 'Tiro Bangla', 'Noto Serif', 'Serif'];
const _musicFonts = ['Noto Sans Bengali', 'Baloo Da 2', 'Roboto Condensed'];

final List<SubtitleTemplateInfo> kSubtitleTemplates = [
  SubtitleTemplateInfo(id: 'story_clean_white', name: 'Story White', category: 'STORY', description: 'Readable lower caption for Bangla narration.', recommendedFonts: _banglaStoryFonts, style: subtitleStyle(templateId: 'story_clean_white', font: 'Hind Siliguri', size: 44, glowIntensity: 0.18)),
  SubtitleTemplateInfo(id: 'story_yellow', name: 'Story Yellow', category: 'STORY', description: 'Warm yellow viral story subtitle.', recommendedFonts: _banglaStoryFonts, style: subtitleStyle(templateId: 'story_yellow', font: 'Hind Siliguri', color: 0xFFFFE066, highlight: 0xFFFFFFFF, glow: 0x55FFD54F, glowIntensity: 0.20)),
  SubtitleTemplateInfo(id: 'story_cinematic', name: 'Story Cinematic', category: 'STORY', description: 'Elegant cinematic Bangla serif.', recommendedFonts: _banglaStoryFonts, style: subtitleStyle(templateId: 'story_cinematic', font: 'Noto Serif Bengali', size: 42, glow: 0x5538BDF8, glowIntensity: 0.26, inAnim: SubtitleAnimationType.slideUp)),
  SubtitleTemplateInfo(id: 'story_dark', name: 'Story Dark', category: 'STORY', description: 'White text over rounded dark pill.', recommendedFonts: _banglaStoryFonts, style: subtitleStyle(templateId: 'story_dark', background: SubtitleBackgroundType.pill, backgroundOpacity: 0.55, glowIntensity: 0.12)),
  SubtitleTemplateInfo(id: 'story_emotional', name: 'Story Emotional', category: 'EMOTIONAL', description: 'Soft serif with blue glow.', recommendedFonts: ['Noto Serif Bengali', 'Galada'], style: subtitleStyle(templateId: 'story_emotional', font: 'Noto Serif Bengali', color: 0xFFFFF7ED, glow: 0x664F46E5, glowIntensity: 0.30, loop: SubtitleLoopAnimation.breathing)),
  SubtitleTemplateInfo(id: 'story_narration', name: 'Story Narration', category: 'DOCUMENTARY', description: 'Clean documentary lower third.', recommendedFonts: ['Mina', 'Noto Sans Bengali'], style: subtitleStyle(templateId: 'story_narration', font: 'Mina', size: 40, strokeWidth: 2.6, background: SubtitleBackgroundType.transparentBox, backgroundOpacity: 0.32)),
  SubtitleTemplateInfo(id: 'story_horror', name: 'Story Horror', category: 'HORROR', description: 'Dark story caption with red accent.', recommendedFonts: _horrorFonts, style: subtitleStyle(templateId: 'story_horror', font: 'Noto Serif Bengali', color: 0xFFFFFFFF, strokeWidth: 4.2, glow: 0x99B91C1C, glowIntensity: 0.38, highlight: 0xFFFF1F3D, loop: SubtitleLoopAnimation.neonFlicker)),
  SubtitleTemplateInfo(id: 'story_mystery', name: 'Story Mystery', category: 'HORROR', description: 'Mystery purple blue glow.', recommendedFonts: _horrorFonts, style: subtitleStyle(templateId: 'story_mystery', font: 'Tiro Bangla', color: 0xFFE0E7FF, glow: 0x884C1D95, glowIntensity: 0.34, inAnim: SubtitleAnimationType.blur)),
  SubtitleTemplateInfo(id: 'story_suspense', name: 'Story Suspense', category: 'HORROR', description: 'Slow fade suspense text.', recommendedFonts: _horrorFonts, style: subtitleStyle(templateId: 'story_suspense', font: 'Noto Serif Bengali', color: 0xFFF8FAFC, glow: 0x77111127, glowIntensity: 0.32, inAnim: SubtitleAnimationType.fade, loop: SubtitleLoopAnimation.breathing)),
  SubtitleTemplateInfo(id: 'story_flashback', name: 'Story Flashback', category: 'DRAMA', description: 'Warm serif flashback look.', recommendedFonts: ['Noto Serif Bengali', 'Atma'], style: subtitleStyle(templateId: 'story_flashback', font: 'Atma', color: 0xFFFFF1C2, glow: 0x55F59E0B, glowIntensity: 0.22, inAnim: SubtitleAnimationType.slowZoom)),
  SubtitleTemplateInfo(id: 'horror_pro', name: 'Horror Pro', category: 'HORROR', description: 'Professional crimson horror preset.', recommendedFonts: _horrorFonts, style: subtitleStyle(templateId: 'horror_pro', font: 'Noto Serif Bengali', color: 0xFFFFFFFF, stroke: 0xFF050505, strokeWidth: 4.8, glow: 0xAA7F1D1D, glowIntensity: 0.46, highlight: 0xFFFF1744, inAnim: SubtitleAnimationType.fade, loop: SubtitleLoopAnimation.neonFlicker)),
  SubtitleTemplateInfo(id: 'blood_red_glow', name: 'Blood Red Glow', category: 'GLOW', description: 'Layered red glow for horror keywords.', recommendedFonts: _horrorFonts, style: subtitleStyle(templateId: 'blood_red_glow', font: 'Tiro Bangla', color: 0xFFFFF1F2, glow: 0xCCDC2626, glowIntensity: 0.55, highlight: 0xFFFF0000)),
  SubtitleTemplateInfo(id: 'dark_red_horror', name: 'Dark Red Horror Glow', category: 'HORROR', description: 'Dark red atmospheric glow.', recommendedFonts: _horrorFonts, style: subtitleStyle(templateId: 'dark_red_horror', font: 'Noto Serif Bengali', color: 0xFFF3F4F6, glow: 0xAA450A0A, glowIntensity: 0.48, loop: SubtitleLoopAnimation.heartbeat)),
  SubtitleTemplateInfo(id: 'ghost_fade', name: 'Ghost Fade', category: 'HORROR', description: 'Pale ghostly fade for whispers.', recommendedFonts: _horrorFonts, style: subtitleStyle(templateId: 'ghost_fade', font: 'Noto Serif Bengali', color: 0xFFE5E7EB, strokeWidth: 2.4, glow: 0x77CBD5E1, glowIntensity: 0.30, inAnim: SubtitleAnimationType.blur, outAnim: SubtitleAnimationType.blur)),
  SubtitleTemplateInfo(id: 'glitch_horror', name: 'Glitch Horror', category: 'HORROR', description: 'Creepy flicker without random movement.', recommendedFonts: _horrorFonts, style: subtitleStyle(templateId: 'glitch_horror', font: 'Tiro Bangla', color: 0xFFFFFFFF, glow: 0x99EF4444, glowIntensity: 0.42, loop: SubtitleLoopAnimation.neonFlicker)),
  SubtitleTemplateInfo(id: 'big_bold', name: 'Big Bold', category: 'VIRAL', description: 'Big centered shorts caption.', recommendedFonts: ['Baloo Da 2', 'Noto Sans Bengali'], style: subtitleStyle(templateId: 'big_bold', font: 'Baloo Da 2', weight: 900, size: 58, strokeWidth: 5.2, glowIntensity: 0.12, inAnim: SubtitleAnimationType.pop, highlightMode: SubtitleHighlightMode.pop)),
  SubtitleTemplateInfo(id: 'punch_caption', name: 'Punch Caption', category: 'VIRAL', description: 'Punchy word-pop caption.', recommendedFonts: ['Baloo Da 2', 'Roboto Condensed'], style: subtitleStyle(templateId: 'punch_caption', font: 'Baloo Da 2', weight: 900, color: 0xFFFFFFFF, highlight: 0xFFFFD400, strokeWidth: 5.0, inAnim: SubtitleAnimationType.wordPop, highlightMode: SubtitleHighlightMode.scale)),
  SubtitleTemplateInfo(id: 'yellow_highlight', name: 'Yellow Highlight', category: 'SHORTS', description: 'White caption with yellow active words.', recommendedFonts: _banglaStoryFonts, style: subtitleStyle(templateId: 'yellow_highlight', highlight: 0xFFFFEB3B, highlightMode: SubtitleHighlightMode.background)),
  SubtitleTemplateInfo(id: 'white_black_stroke', name: 'White + Black Stroke', category: 'REELS', description: 'Classic readable social subtitle.', recommendedFonts: _banglaStoryFonts, style: subtitleStyle(templateId: 'white_black_stroke', strokeWidth: 5.0, glowIntensity: 0.05)),
  SubtitleTemplateInfo(id: 'red_keyword', name: 'Red Keyword', category: 'TIKTOK STYLE', description: 'Active/emphasis words become red.', recommendedFonts: ['Hind Siliguri', 'Baloo Da 2'], style: subtitleStyle(templateId: 'red_keyword', highlight: 0xFFFF1744, highlightMode: SubtitleHighlightMode.glow, glow: 0x55FF1744, glowIntensity: 0.22)),
  SubtitleTemplateInfo(id: 'karaoke_viral', name: 'Karaoke Viral', category: 'KARAOKE', description: 'Karaoke word fill/highlight.', recommendedFonts: _musicFonts, style: subtitleStyle(templateId: 'karaoke_viral', font: 'Baloo Da 2', highlight: 0xFF00E5FF, highlightMode: SubtitleHighlightMode.gradient, inAnim: SubtitleAnimationType.wordPop)),
  SubtitleTemplateInfo(id: 'center_pop', name: 'Center Pop', category: 'SHORTS', description: 'Center pop for impact words.', position: SubtitleVerticalPosition.center, recommendedFonts: ['Baloo Da 2'], style: subtitleStyle(templateId: 'center_pop', font: 'Baloo Da 2', weight: 900, size: 62, inAnim: SubtitleAnimationType.pop, outAnim: SubtitleAnimationType.zoom)),
  SubtitleTemplateInfo(id: 'bottom_caption', name: 'Bottom Caption', category: 'YOUTUBE', description: 'Safe lower caption.', recommendedFonts: _banglaStoryFonts, style: subtitleStyle(templateId: 'bottom_caption', font: 'Noto Sans Bengali', size: 42, background: SubtitleBackgroundType.rounded, backgroundOpacity: 0.28)),
  SubtitleTemplateInfo(id: 'dynamic_word', name: 'Dynamic Word', category: 'VIRAL', description: 'Word-by-word scaling highlight.', recommendedFonts: ['Baloo Da 2'], style: subtitleStyle(templateId: 'dynamic_word', font: 'Baloo Da 2', highlightMode: SubtitleHighlightMode.scale, inAnim: SubtitleAnimationType.wordPop)),
  SubtitleTemplateInfo(id: 'emphasis_caption', name: 'Emphasis Caption', category: 'MOTIVATIONAL', description: 'Bold clean emphasis.', recommendedFonts: ['Anek Bangla', 'Roboto Condensed'], style: subtitleStyle(templateId: 'emphasis_caption', font: 'Anek Bangla', weight: 800, color: 0xFFFFFFFF, highlight: 0xFFFF9500, strokeWidth: 4.8, glow: 0x55FF9500, glowIntensity: 0.18)),
  SubtitleTemplateInfo(id: 'fast_story', name: 'Fast Story Caption', category: 'REELS', description: 'Fast pop captions for shorts.', recommendedFonts: ['Hind Siliguri', 'Baloo Da 2'], style: subtitleStyle(templateId: 'fast_story', font: 'Hind Siliguri', inAnim: SubtitleAnimationType.pop, outAnim: SubtitleAnimationType.fade, highlightMode: SubtitleHighlightMode.pop)),
  SubtitleTemplateInfo(id: 'reaction_caption', name: 'Reaction Caption', category: 'COMEDY', description: 'Comic rounded style.', recommendedFonts: ['Baloo Da 2'], style: subtitleStyle(templateId: 'reaction_caption', font: 'Baloo Da 2', color: 0xFFFFF59D, strokeWidth: 5.5, background: SubtitleBackgroundType.pill, backgroundOpacity: 0.25, inAnim: SubtitleAnimationType.bounce)),
  SubtitleTemplateInfo(id: 'blue_neon', name: 'Blue Neon Glow', category: 'NEON', description: 'Electric blue neon text.', recommendedFonts: ['Noto Sans Bengali', 'Roboto'], style: subtitleStyle(templateId: 'blue_neon', color: 0xFFE0F2FE, glow: 0xCC0A84FF, glowIntensity: 0.55, highlight: 0xFF38BDF8, loop: SubtitleLoopAnimation.glowPulse)),
  SubtitleTemplateInfo(id: 'purple_neon', name: 'Purple Neon Glow', category: 'NEON', description: 'Purple glow caption.', recommendedFonts: ['Anek Bangla', 'Noto Sans Bengali'], style: subtitleStyle(templateId: 'purple_neon', color: 0xFFF5D0FE, glow: 0xCC8B5CF6, glowIntensity: 0.52, highlight: 0xFFE879F9)),
  SubtitleTemplateInfo(id: 'green_toxic', name: 'Green Toxic Glow', category: 'NEON', description: 'Toxic green gaming glow.', recommendedFonts: ['Anek Bangla', 'Monospace'], style: subtitleStyle(templateId: 'green_toxic', color: 0xFFECFCCB, glow: 0xCC22C55E, glowIntensity: 0.50, highlight: 0xFF84CC16)),
  SubtitleTemplateInfo(id: 'gold_luxury', name: 'Golden Luxury Glow', category: 'LUXURY', description: 'Gold premium serif.', recommendedFonts: ['Noto Serif Bengali', 'Noto Serif'], style: subtitleStyle(templateId: 'gold_luxury', font: 'Noto Serif Bengali', gradient: true, gradientStart: 0xFFFFF7AD, gradientEnd: 0xFFD97706, glow: 0x88F59E0B, glowIntensity: 0.38, highlight: 0xFFFFD700)),
  SubtitleTemplateInfo(id: 'ice_blue', name: 'Ice Blue Glow', category: 'GLOW', description: 'Cold blue cinematic glow.', recommendedFonts: ['Noto Sans Bengali'], style: subtitleStyle(templateId: 'ice_blue', color: 0xFFE0F7FF, glow: 0xAA67E8F9, glowIntensity: 0.42, highlight: 0xFFBAE6FD)),
  SubtitleTemplateInfo(id: 'orange_fire', name: 'Orange Fire Glow', category: 'GLOW', description: 'Orange fire gradient caption.', recommendedFonts: ['Baloo Da 2'], style: subtitleStyle(templateId: 'orange_fire', gradient: true, gradientStart: 0xFFFFF7AD, gradientEnd: 0xFFFF3B30, glow: 0xAAFF6B00, glowIntensity: 0.46, highlight: 0xFFFF9500)),
  SubtitleTemplateInfo(id: 'cyan_glow', name: 'Cyan Glow', category: 'GLOW', description: 'Clean cyan glow.', recommendedFonts: ['Noto Sans Bengali'], style: subtitleStyle(templateId: 'cyan_glow', color: 0xFFE0FFFF, glow: 0xAA00E5FF, glowIntensity: 0.42, highlight: 0xFF00E5FF)),
  SubtitleTemplateInfo(id: 'pink_glow', name: 'Pink Glow', category: 'GLOW', description: 'Pink social subtitle.', recommendedFonts: ['Galada', 'Baloo Da 2'], style: subtitleStyle(templateId: 'pink_glow', color: 0xFFFFE4F1, glow: 0xAAFF2D55, glowIntensity: 0.42, highlight: 0xFFFF2D55)),
  SubtitleTemplateInfo(id: 'rgb_glow', name: 'RGB Glow', category: 'GLOW', description: 'Rainbow/RGB text glow.', recommendedFonts: ['Anek Bangla', 'Roboto'], style: subtitleStyle(templateId: 'rgb_glow', gradient: true, gradientStart: 0xFFFF2D55, gradientEnd: 0xFF0A84FF, glow: 0x8800E5FF, glowIntensity: 0.40, highlightMode: SubtitleHighlightMode.gradient)),
  SubtitleTemplateInfo(id: 'soft_cinematic_glow', name: 'Soft Cinematic Glow', category: 'CINEMATIC', description: 'Subtle premium glow for documentaries.', recommendedFonts: ['Noto Serif Bengali', 'Noto Sans Bengali'], style: subtitleStyle(templateId: 'soft_cinematic_glow', font: 'Noto Serif Bengali', color: 0xFFF8FAFC, glow: 0x663B82F6, glowIntensity: 0.28, inAnim: SubtitleAnimationType.slideUp)),
  SubtitleTemplateInfo(id: 'news_lower', name: 'News Lower', category: 'NEWS', description: 'Bold news caption with box.', recommendedFonts: ['Mina', 'Roboto Condensed'], style: subtitleStyle(templateId: 'news_lower', font: 'Mina', weight: 800, size: 38, background: SubtitleBackgroundType.rounded, backgroundOpacity: 0.72, glowIntensity: 0.05)),
  SubtitleTemplateInfo(id: 'documentary_serif', name: 'Documentary Serif', category: 'DOCUMENTARY', description: 'Serif documentary caption.', recommendedFonts: ['Noto Serif Bengali', 'Noto Serif'], style: subtitleStyle(templateId: 'documentary_serif', font: 'Noto Serif Bengali', size: 40, strokeWidth: 2.4, glowIntensity: 0.12)),
  SubtitleTemplateInfo(id: 'gaming_bold', name: 'Gaming Bold', category: 'GAMING', description: 'Heavy gaming caption.', recommendedFonts: ['Anek Bangla', 'Baloo Da 2', 'Monospace'], style: subtitleStyle(templateId: 'gaming_bold', font: 'Anek Bangla', weight: 900, color: 0xFFFFFFFF, highlight: 0xFF22C55E, strokeWidth: 5.0, glow: 0x6622C55E, glowIntensity: 0.30, inAnim: SubtitleAnimationType.pop)),
  SubtitleTemplateInfo(id: 'meme_heavy', name: 'Meme Heavy', category: 'MEME', description: 'Classic meme readability.', recommendedFonts: ['Baloo Da 2', 'Roboto Condensed'], style: subtitleStyle(templateId: 'meme_heavy', font: 'Baloo Da 2', weight: 900, color: 0xFFFFFFFF, strokeWidth: 6.0, glowIntensity: 0.02)),
  SubtitleTemplateInfo(id: 'lyrics_clean', name: 'Lyrics Clean', category: 'LYRICS', description: 'Clean lyric subtitle.', recommendedFonts: _musicFonts, style: subtitleStyle(templateId: 'lyrics_clean', font: 'Noto Sans Bengali', color: 0xFFFFFFFF, highlight: 0xFF38BDF8, highlightMode: SubtitleHighlightMode.underline)),
  SubtitleTemplateInfo(id: 'minimal_white', name: 'Minimal White', category: 'MINIMAL', description: 'Minimal white sans.', recommendedFonts: ['Noto Sans Bengali', 'Hind Siliguri'], style: subtitleStyle(templateId: 'minimal_white', font: 'Noto Sans Bengali', size: 38, strokeWidth: 1.5, glowIntensity: 0.0)),
  SubtitleTemplateInfo(id: 'premium_gradient', name: 'Premium Gradient', category: 'PREMIUM', description: 'Premium gold-to-white gradient.', recommendedFonts: ['Noto Serif Bengali'], style: subtitleStyle(templateId: 'premium_gradient', font: 'Noto Serif Bengali', gradient: true, gradientStart: 0xFFFFFFFF, gradientEnd: 0xFFFFD54F, glow: 0x66FFD54F, glowIntensity: 0.28)),
];

SubtitleTemplateInfo subtitleTemplateById(String id) {
  return kSubtitleTemplates.firstWhere(
    (template) => template.id == id,
    orElse: () => kSubtitleTemplates.first,
  );
}

List<SubtitleFontInfo> recommendedFontsForCategory(String category) {
  final normalized = category.toUpperCase();
  final names = normalized.contains('HORROR')
      ? _horrorFonts
      : normalized.contains('MUSIC') || normalized.contains('KARAOKE') || normalized.contains('LYRICS')
          ? _musicFonts
          : _banglaStoryFonts;
  return names
      .map((name) => kSubtitleFonts.firstWhere((font) => font.family == name, orElse: () => kSubtitleFonts.first))
      .toList();
}
