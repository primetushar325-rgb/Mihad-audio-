import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:mihad_audio/app/app.dart';
import 'package:mihad_audio/screens/template_gallery_screen.dart';
import 'package:mihad_audio/widgets/template_preview_tile.dart';

import 'fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = FakePathProvider();

  testWidgets('App starts up and shows the MIHAD AUDIO home screen', (
    tester,
  ) async {
    await tester.pumpWidget(const MihadAudioApp());
    await tester.pumpAndSettle();

    expect(find.text('MIHAD AUDIO'), findsWidgets);
    expect(find.text('Create New Project'), findsOneWidget);
    expect(find.text('Recent Projects'), findsOneWidget);
    expect(find.text('My Exports'), findsOneWidget);
  });

  testWidgets(
    'Home screen navigates to the Template Gallery and selection works',
    (tester) async {
      await tester.pumpWidget(const MihadAudioApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Browse Template Gallery'));
      // Pump fixed frames for the gallery route transition instead of
      // relying on pumpAndSettle in this navigation test.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(TemplateGalleryScreen), findsOneWidget);
      // The grid is virtualized, so only the tiles that fit the test
      // viewport are actually built - assert at least a handful render.
      expect(find.byType(TemplatePreviewTile), findsAtLeastNWidgets(2));

      // Tapping a template (the first one is always on-screen) pops the
      // gallery and returns the chosen type.
      await tester.tap(find.text('Story Equalizer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(TemplateGalleryScreen), findsNothing);
    },
  );
}
