import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

import '../app/theme.dart';
import '../models/audio_analysis_data.dart';
import '../models/visualizer_settings.dart';
import '../services/export_math.dart';
import '../visualizers/visualizer_painter_base.dart';
import '../visualizers/visualizer_registry.dart';

/// Renders the visualizer overlay on top of the video preview and lets
/// the user drag it to reposition, and drag its corner handle to resize.
///
/// Drag/resize uses a local draft while the pointer is moving, then commits
/// the final normalized values to the project once the gesture ends. This
/// avoids expensive project persistence on every pointer frame while keeping
/// preview/export WYSIWYG.
class VisualizerOverlayEditor extends StatefulWidget {
  final VideoPlayerController controller;
  final AudioAnalysisData analysisData;
  final VisualizerSettings settings;
  final ValueChanged<VisualizerSettings> onChanged;
  final bool editable;

  const VisualizerOverlayEditor({
    super.key,
    required this.controller,
    required this.analysisData,
    required this.settings,
    required this.onChanged,
    this.editable = true,
  });

  @override
  State<VisualizerOverlayEditor> createState() =>
      _VisualizerOverlayEditorState();
}

class _VisualizerRepaintSignal extends ChangeNotifier {
  void request() => notifyListeners();
}

class _VisualizerOverlayEditorState extends State<VisualizerOverlayEditor>
    with SingleTickerProviderStateMixin {
  late VisualizerSettings _draftSettings;
  late final Ticker _ticker;
  final _repaint = _VisualizerRepaintSignal();
  final _qualityLevel = ValueNotifier<int>(0);
  bool _interacting = false;
  double _lastCanvasWidth = 360;
  int _lastNotifyMicros = 0;
  int _lastTickMicros = 0;
  int _slowFrameStreak = 0;
  int _stableFrameStreak = 0;
  Duration _lastPaintedPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _draftSettings = widget.settings;
    widget.controller.addListener(_handleControllerEvent);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(covariant VisualizerOverlayEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_handleControllerEvent);
      widget.controller.addListener(_handleControllerEvent);
      _lastPaintedPosition = widget.controller.value.position;
      _repaint.request();
    }
    if (!_interacting && !identical(oldWidget.settings, widget.settings)) {
      _draftSettings = widget.settings;
      _repaint.request();
    }
    if (!identical(oldWidget.analysisData, widget.analysisData)) {
      _repaint.request();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerEvent);
    _ticker.dispose();
    _repaint.dispose();
    _qualityLevel.dispose();
    super.dispose();
  }

  int get _targetFrameMicros {
    final mobile = _lastCanvasWidth < 720;
    final baseMs = mobile ? 33 : 22; // ~30 FPS mobile, ~45 FPS larger screens.
    final interactionPenalty = _interacting ? 14 : 0;
    final qualityPenalty = _qualityLevel.value * 8;
    return (baseMs + interactionPenalty + qualityPenalty) * 1000;
  }

  void _handleControllerEvent() {
    final value = widget.controller.value;
    if (!value.isPlaying && value.position != _lastPaintedPosition) {
      _lastPaintedPosition = value.position;
      _repaint.request();
    }
  }

  void _onTick(Duration elapsed) {
    final micros = elapsed.inMicroseconds;
    final tickDelta = _lastTickMicros == 0 ? 0 : micros - _lastTickMicros;
    _lastTickMicros = micros;
    final target = _targetFrameMicros;
    if (tickDelta > 0) _updateAdaptiveQuality(tickDelta, target);

    final value = widget.controller.value;
    if (!value.isPlaying) return;
    if (micros - _lastNotifyMicros < target) return;
    _lastNotifyMicros = micros;
    _lastPaintedPosition = value.position;
    _repaint.request();
  }

  void _updateAdaptiveQuality(int tickDeltaMicros, int targetMicros) {
    if (tickDeltaMicros > targetMicros * 2.1) {
      _slowFrameStreak++;
      _stableFrameStreak = 0;
      if (_slowFrameStreak >= 6 && _qualityLevel.value < 2) {
        _qualityLevel.value++;
        _slowFrameStreak = 0;
        _repaint.request();
      }
    } else if (tickDeltaMicros < targetMicros * 1.25) {
      _stableFrameStreak++;
      _slowFrameStreak = 0;
      if (_stableFrameStreak >= 180 && _qualityLevel.value > 0) {
        _qualityLevel.value--;
        _stableFrameStreak = 0;
        _repaint.request();
      }
    }
  }

  void _setDraft(VisualizerSettings settings) {
    if (!widget.editable) return;
    setState(() {
      _interacting = true;
      _draftSettings = settings;
    });
  }

  void _commitDraft() {
    if (!_interacting) return;
    _interacting = false;
    widget.onChanged(_draftSettings);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasW = constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth;
        final canvasH = constraints.maxHeight <= 0 ? 1.0 : constraints.maxHeight;
        _lastCanvasWidth = canvasW;
        final s = _interacting ? _draftSettings : widget.settings;
        final bounds = resolveVisualizerBounds(s, canvasW, canvasH);
        final left = bounds.left;
        final top = bounds.top;
        final width = bounds.width;
        final height = bounds.height;

        VisualizerSettings movedBy(Offset delta) {
          final newLeft = (left + delta.dx)
              .clamp(0.0, canvasW - width)
              .toDouble();
          final newTop = (top + delta.dy)
              .clamp(0.0, canvasH - height)
              .toDouble();
          return s.copyWith(posX: newLeft / canvasW, posY: newTop / canvasH);
        }

        VisualizerSettings resizedBy(Offset delta) {
          final minW = canvasW < 44
              ? canvasW
              : (canvasW * 0.08).clamp(44.0, canvasW).toDouble();
          final minH = canvasH < 34
              ? canvasH
              : (canvasH * 0.06).clamp(34.0, canvasH).toDouble();
          final maxW = (canvasW - left).clamp(1.0, canvasW).toDouble();
          final maxH = (canvasH - top).clamp(1.0, canvasH).toDouble();
          final minWidthForClamp = minW > maxW ? maxW : minW;
          final minHeightForClamp = minH > maxH ? maxH : minH;
          final newWidth = (width + delta.dx)
              .clamp(minWidthForClamp, maxW)
              .toDouble();
          final newHeight = (height + delta.dy)
              .clamp(minHeightForClamp, maxH)
              .toDouble();
          return s.copyWith(
            width: newWidth / canvasW,
            height: newHeight / canvasH,
          );
        }

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: widget.editable
                    ? (details) => _setDraft(movedBy(details.delta))
                    : null,
                onPanEnd: widget.editable ? (_) => _commitDraft() : null,
                onPanCancel: widget.editable ? _commitDraft : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: widget.editable
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: MihadColors.accentPrimary.withValues(
                                    alpha: 0.70,
                                  ),
                                  width: 1,
                                ),
                              )
                            : const BoxDecoration(),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _LiveVisualizerCanvasPainter(
                              controller: widget.controller,
                              analysisData: widget.analysisData,
                              settings: s.copyWith(
                                posX: 0,
                                posY: 0,
                                width: 1,
                                height: 1,
                              ),
                              qualityLevel: _qualityLevel,
                              repaint: _repaint,
                            ),
                            size: Size(width, height),
                          ),
                        ),
                      ),
                    ),
                    if (widget.editable) ...[
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _OverlayHandle(
                          icon: Icons.drag_indicator,
                          label: 'Move visualizer',
                          onPanUpdate: (delta) => _setDraft(movedBy(delta)),
                          onPanEnd: _commitDraft,
                        ),
                      ),
                      Positioned(
                        right: -11,
                        bottom: -11,
                        child: _OverlayHandle(
                          icon: Icons.open_in_full,
                          label: 'Resize visualizer',
                          onPanUpdate: (delta) => _setDraft(resizedBy(delta)),
                          onPanEnd: _commitDraft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiveVisualizerCanvasPainter extends CustomPainter {
  final VideoPlayerController controller;
  final AudioAnalysisData analysisData;
  final VisualizerSettings settings;
  final ValueNotifier<int> qualityLevel;

  _LiveVisualizerCanvasPainter({
    required this.controller,
    required this.analysisData,
    required this.settings,
    required this.qualityLevel,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveSettings = _performanceAdjustedSettings(settings);
    final posMs = controller.value.position.inMilliseconds.toDouble();
    final frame = visualizerFrameFromAnalysis(
      analysisData,
      posMs,
      effectiveSettings,
    );
    paintVisualizerOverlayBox(
      canvas: canvas,
      size: size,
      data: frame,
      settings: effectiveSettings,
      delegate: painterFor(effectiveSettings.template),
    );
  }

  VisualizerSettings _performanceAdjustedSettings(VisualizerSettings source) {
    final level = qualityLevel.value;
    if (level <= 0) return source;
    final maxBars = level == 1 ? 48 : 32;
    final bars = source.barCount > maxBars ? maxBars : source.barCount;
    final glowScale = level == 1 ? 0.62 : 0.34;
    return source.copyWith(
      barCount: bars,
      glowIntensity: source.glowIntensity * glowScale,
    );
  }

  @override
  bool shouldRepaint(covariant _LiveVisualizerCanvasPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.analysisData != analysisData ||
        oldDelegate.settings != settings ||
        oldDelegate.qualityLevel != qualityLevel;
  }
}

class _OverlayHandle extends StatelessWidget {
  final IconData icon;
  final String label;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;

  const _OverlayHandle({
    required this.icon,
    required this.label,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onPanUpdate(details.delta),
        onPanEnd: (_) => onPanEnd(),
        onPanCancel: onPanEnd,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: MihadColors.accentPrimary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: MihadColors.accentPrimary.withValues(alpha: 0.25),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, size: 14, color: Colors.black),
        ),
      ),
    );
  }
}
