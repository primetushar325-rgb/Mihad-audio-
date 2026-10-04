import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mihad_audio/services/media_picker_service.dart';
import 'package:mihad_audio/widgets/pick_feedback.dart';

void main() {
  Future<BuildContext> pumpHarness(WidgetTester tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );
    return capturedContext;
  }

  testWidgets('resolvePick returns the path on success without a SnackBar', (
    tester,
  ) async {
    final context = await pumpHarness(tester);

    final path = await resolvePick(
      context,
      Future.value(MediaPickResult.success('/sdcard/clip.mp4')),
    );
    await tester.pump();

    expect(path, '/sdcard/clip.mp4');
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('resolvePick returns null on cancellation without a SnackBar', (
    tester,
  ) async {
    final context = await pumpHarness(tester);

    final path = await resolvePick(
      context,
      Future.value(MediaPickResult.cancelled()),
    );
    await tester.pump();

    expect(path, isNull);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('resolvePick shows a SnackBar and returns null on error', (
    tester,
  ) async {
    final context = await pumpHarness(tester);

    final path = await resolvePick(
      context,
      Future.value(MediaPickResult.error('No file manager available.')),
    );
    await tester.pump();

    expect(path, isNull);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('No file manager available.'), findsOneWidget);
  });
}
