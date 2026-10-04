import 'package:flutter/foundation.dart';

import '../models/audio_analysis_data.dart';
import '../models/project.dart';
import '../services/export_service.dart';

enum ExportUiState { idle, running, success, cancelled, error }

/// Drives the Export screen: wraps [ExportService] with observable state
/// (progress, stage, errors) and exposes [cancel].
class ExportController extends ChangeNotifier {
  final ExportService _service = ExportService();
  ExportCancelToken? _cancelToken;

  ExportUiState state = ExportUiState.idle;
  ExportStage stage = ExportStage.renderingOverlay;
  double progress = 0;
  String? errorMessage;
  String? outputPath;

  Future<void> start({
    required Project project,
    required Duration videoDuration,
    required int? sourceWidth,
    required int? sourceHeight,
    required double? sourceFps,
    required AudioAnalysisData analysisData,
  }) async {
    state = ExportUiState.running;
    progress = 0;
    errorMessage = null;
    outputPath = null;
    _cancelToken = ExportCancelToken();
    notifyListeners();

    try {
      final path = await _service.export(
        project: project,
        videoDuration: videoDuration,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        sourceFps: sourceFps,
        analysisData: analysisData,
        cancelToken: _cancelToken!,
        onProgress: (update) {
          stage = update.stage;
          progress = update.progress;
          notifyListeners();
        },
      );
      outputPath = path;
      project.exportedVideoPaths.insert(0, path);
      state = ExportUiState.success;
    } on ExportCancelledException {
      state = ExportUiState.cancelled;
    } on ExportException catch (e) {
      state = ExportUiState.error;
      errorMessage = e.message;
    } catch (e) {
      state = ExportUiState.error;
      if (e.toString().contains('ENOSPC') ||
          e.toString().toLowerCase().contains('no space')) {
        errorMessage =
            'Not enough free storage space to finish exporting. '
            'Free up space and try again.';
      } else {
        errorMessage = 'Export failed: $e';
      }
    }
    notifyListeners();
  }

  void cancel() {
    _cancelToken?.cancel();
  }

  void reset() {
    state = ExportUiState.idle;
    progress = 0;
    errorMessage = null;
    outputPath = null;
    notifyListeners();
  }
}
