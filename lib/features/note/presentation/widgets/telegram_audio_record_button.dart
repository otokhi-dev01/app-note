import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:Note/core/feedback/app_snackbar.dart';

class TelegramAudioRecording {
  final String path;
  final String displayName;
  final Duration duration;

  const TelegramAudioRecording({
    required this.path,
    required this.displayName,
    required this.duration,
  });
}

abstract interface class TelegramAudioRecorder {
  Future<bool> hasPermission();
  Future<void> start(String path);
  Future<String?> stop();
  Future<void> cancel();
  Future<void> dispose();
}

class _DeviceTelegramAudioRecorder implements TelegramAudioRecorder {
  final _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String path) => _recorder.start(
    const RecordConfig(
      numChannels: 1,
      autoGain: true,
      echoCancel: true,
      noiseSuppress: true,
    ),
    path: path,
  );

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Future<void> dispose() => _recorder.dispose();
}

typedef TelegramRecordingCallback =
    Future<void> Function(TelegramAudioRecording recording);
typedef TelegramRecordingPathBuilder = Future<String> Function();

/// Telegram-style voice recording: hold to record, drag left to cancel, and
/// release to save without navigating away from the current screen.
class TelegramAudioRecordButton extends StatefulWidget {
  final TelegramRecordingCallback onRecorded;
  final String semanticLabel;
  final double size;
  final double iconSize;
  final Duration minimumDuration;
  final TelegramAudioRecorder Function()? recorderFactory;
  final TelegramRecordingPathBuilder? pathBuilder;

  const TelegramAudioRecordButton({
    super.key,
    required this.onRecorded,
    required this.semanticLabel,
    this.size = 44,
    this.iconSize = 21,
    this.minimumDuration = const Duration(milliseconds: 500),
    this.recorderFactory,
    this.pathBuilder,
  });

  @override
  State<TelegramAudioRecordButton> createState() =>
      _TelegramAudioRecordButtonState();
}

class _TelegramAudioRecordButtonState extends State<TelegramAudioRecordButton> {
  static const _cancelDistance = 96.0;

  late final TelegramAudioRecorder _recorder;
  final _stopwatch = Stopwatch();
  Timer? _ticker;
  OverlayEntry? _overlayEntry;
  Offset _buttonOrigin = Offset.zero;
  Duration _elapsed = Duration.zero;
  String? _path;
  double _dragDx = 0;
  bool _pressed = false;
  bool _starting = false;
  bool _recording = false;
  bool _finishing = false;
  bool _releaseRequested = false;
  bool _cancelRequested = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _recorder =
        widget.recorderFactory?.call() ?? _DeviceTelegramAudioRecorder();
  }

  Future<String> _buildPath() async {
    final custom = widget.pathBuilder;
    if (custom != null) return custom();
    final directory = await getTemporaryDirectory();
    return '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _beginRecording() async {
    if (_starting || _recording || _finishing) return;
    _starting = true;
    _releaseRequested = false;
    _cancelRequested = false;
    _dragDx = 0;
    _elapsed = Duration.zero;
    _pressed = true;
    _captureButtonOrigin();
    _showOverlay();
    _refresh();
    unawaited(HapticFeedback.mediumImpact());

    try {
      if (!await _recorder.hasPermission()) {
        if (!_disposed) {
          AppSnackbar.error(
            'note_editor_mic_unavailable_title'.tr,
            'note_editor_mic_unavailable_message'.tr,
          );
        }
        await _reset();
        return;
      }

      final path = await _buildPath();
      if (_disposed) return;
      _path = path;
      await _recorder.start(path);
      if (_disposed) {
        await _recorder.cancel();
        return;
      }

      _starting = false;
      _recording = true;
      _stopwatch
        ..reset()
        ..start();
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (_disposed || !_stopwatch.isRunning) return;
        _elapsed = _stopwatch.elapsed;
        _refresh();
      });
      _refresh();

      if (_releaseRequested || _cancelRequested) {
        await _finish(save: !_cancelRequested);
      }
    } catch (error) {
      debugPrint('[INLINE AUDIO START ERROR] $error');
      try {
        await _recorder.cancel();
      } catch (_) {}
      _deleteTemporaryFile(_path);
      if (!_disposed) {
        AppSnackbar.error(
          'note_editor_error_title'.tr,
          'note_editor_could_not_start_recording'.tr,
        );
      }
      await _reset();
    }
  }

  void _captureButtonOrigin() {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      _buttonOrigin = renderObject.localToGlobal(Offset.zero);
    }
  }

  void _handleMove(LongPressMoveUpdateDetails details) {
    if (!_starting && !_recording) return;
    _dragDx = details.offsetFromOrigin.dx.clamp(-_cancelDistance, 0);
    _refresh();
    if (_dragDx <= -_cancelDistance && !_cancelRequested) {
      _cancelRequested = true;
      unawaited(HapticFeedback.heavyImpact());
      unawaited(_finish(save: false));
    }
  }

  void _handleRelease() {
    _pressed = false;
    _releaseRequested = true;
    _refresh();
    if (!_cancelRequested) unawaited(_finish(save: true));
  }

  Future<void> _finish({required bool save}) async {
    if (_finishing) return;
    if (_starting) {
      _releaseRequested = true;
      if (!save) _cancelRequested = true;
      return;
    }
    if (!_recording) return;

    _finishing = true;
    _recording = false;
    _pressed = false;
    _stopwatch.stop();
    _elapsed = _stopwatch.elapsed;
    _ticker?.cancel();
    _ticker = null;
    _refresh();

    String? completedPath;
    try {
      if (save) {
        completedPath = await _recorder.stop() ?? _path;
      } else {
        await _recorder.cancel();
      }

      if (save && completedPath != null) {
        if (_elapsed < widget.minimumDuration) {
          AppSnackbar.info(
            'note_editor_recording_too_short_title'.tr,
            'note_editor_recording_too_short_message'.tr,
          );
        } else {
          await widget.onRecorded(
            TelegramAudioRecording(
              path: completedPath,
              displayName: _recordingName(),
              duration: _elapsed,
            ),
          );
        }
      }
    } catch (error) {
      debugPrint('[INLINE AUDIO FINISH ERROR] $error');
      if (!_disposed) {
        AppSnackbar.error(
          'note_editor_error_title'.tr,
          'note_editor_could_not_save_recording'.tr,
        );
      }
    } finally {
      _deleteTemporaryFile(completedPath ?? _path);
      await _reset();
    }
  }

  String _recordingName() {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final date = '${now.year}-${twoDigits(now.month)}-${twoDigits(now.day)}';
    final time =
        '${twoDigits(now.hour)}-${twoDigits(now.minute)}-${twoDigits(now.second)}';
    return '${'note_editor_recording_fallback_name'.tr} $date $time.m4a';
  }

  void _deleteTemporaryFile(String? path) {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (error) {
      debugPrint('[INLINE AUDIO CLEANUP ERROR] $error');
    }
  }

  Future<void> _reset() async {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch
      ..stop()
      ..reset();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _path = null;
    _elapsed = Duration.zero;
    _dragDx = 0;
    _pressed = false;
    _starting = false;
    _recording = false;
    _finishing = false;
    _releaseRequested = false;
    _cancelRequested = false;
    _refresh();
  }

  void _showOverlay() {
    if (_overlayEntry != null || !mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _overlayEntry = OverlayEntry(builder: _buildRecordingOverlay);
    overlay.insert(_overlayEntry!);
  }

  Widget _buildRecordingOverlay(BuildContext overlayContext) {
    final theme = Theme.of(overlayContext);
    final red = CupertinoColors.systemRed.resolveFrom(overlayContext);
    final screen = MediaQuery.sizeOf(overlayContext);
    final top = (_buttonOrigin.dy - 3).clamp(
      MediaQuery.paddingOf(overlayContext).top + 8,
      screen.height - 64,
    );
    final cancelProgress = (-_dragDx / _cancelDistance).clamp(0.0, 1.0);

    return Positioned(
      left: 16,
      right: 16,
      top: top,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Transform.translate(
            offset: Offset(_dragDx * 0.12, 0),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.45,
                  ),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 48,
                    child: Text(
                      _formatDuration(_elapsed),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chevron_left,
                          size: 15,
                          color: Color.lerp(
                            theme.colorScheme.onSurfaceVariant,
                            red,
                            cancelProgress,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'note_editor_slide_to_cancel'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Color.lerp(
                                theme.colorScheme.onSurfaceVariant,
                                red,
                                cancelProgress,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(CupertinoIcons.mic_fill, color: red, size: 21),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _refresh() {
    if (mounted && !_disposed) setState(() {});
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _stopwatch.stop();
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_starting || _recording) {
      unawaited(_recorder.cancel().whenComplete(_recorder.dispose));
    } else {
      unawaited(_recorder.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final red = CupertinoColors.systemRed.resolveFrom(context);

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      hint: 'note_editor_hold_to_record'.tr,
      onLongPress: _beginRecording,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: (_) {
          _pressed = true;
          _refresh();
        },
        onTapUp: (_) {
          _pressed = false;
          _refresh();
        },
        onTapCancel: () {
          if (!_recording && !_starting) {
            _pressed = false;
            _refresh();
          }
        },
        onTap: () => AppSnackbar.info(
          'note_editor_record_audio'.tr,
          'note_editor_hold_to_record'.tr,
        ),
        onLongPressStart: (_) => unawaited(_beginRecording()),
        onLongPressMoveUpdate: _handleMove,
        onLongPressEnd: (_) => _handleRelease(),
        child: AnimatedScale(
          scale: _pressed ? 1.18 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _pressed ? red : red.withValues(alpha: 0.1),
            ),
            child: Icon(
              CupertinoIcons.mic_fill,
              size: widget.iconSize,
              color: _pressed ? CupertinoColors.white : red,
            ),
          ),
        ),
      ),
    );
  }
}
