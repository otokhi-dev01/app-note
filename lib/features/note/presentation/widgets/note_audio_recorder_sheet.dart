import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class NoteAudioRecorderSheet extends StatefulWidget {
  final Future<void> Function(String path, String displayName) onRecorded;

  const NoteAudioRecorderSheet({super.key, required this.onRecorded});

  @override
  State<NoteAudioRecorderSheet> createState() => _NoteAudioRecorderSheetState();
}

class _NoteAudioRecorderSheetState extends State<NoteAudioRecorderSheet> {
  static const _minKeepable = Duration(milliseconds: 500);
  static const _maxWaveformSamples = 56;

  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _stopwatch = Stopwatch();
  Timer? _ticker;
  StreamSubscription<Amplitude>? _ampSub;
  StreamSubscription<RecordState>? _stateSub;
  StreamSubscription<Duration>? _playbackDurationSub;
  StreamSubscription<Duration>? _playbackPositionSub;
  StreamSubscription<void>? _playbackCompleteSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  Duration _elapsed = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  final _waveformSamples = <double>[];
  String? _recordedPath;
  bool _starting = true;
  bool _finishing = false;
  bool _paused = false;
  bool _changingState = false;
  bool _isReviewing = false;
  bool _isPlaying = false;
  bool _playbackReady = false;

  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _listenToPlayer();
    _start();
  }

  void _listenToPlayer() {
    _playbackDurationSub = _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _playbackDuration = duration);
    });
    _playbackPositionSub = _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _playbackPosition = position);
    });
    _playbackCompleteSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
    });
    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  Future<void> _start() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (_finished || !mounted) return;
      if (!hasPermission) {
        AppSnackbar.error(
          'note_editor_mic_unavailable_title'.tr,
          'note_editor_mic_unavailable_message'.tr,
        );
        Navigator.of(context).pop();
        return;
      }

      final dir = await getTemporaryDirectory();
      if (_finished || !mounted) return;
      final path =
          '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: path,
      );
    } catch (e) {
      debugPrint('[AUDIO RECORD ERROR] $e');
      if (_finished || !mounted) return;
      AppSnackbar.error(
        'note_editor_error_title'.tr,
        'note_editor_could_not_start_recording'.tr,
      );
      Navigator.of(context).pop();
      return;
    }

    if (_finished || !mounted) return;

    _startLiveUpdates();
    if (mounted) setState(() => _starting = false);
  }

  void _startLiveUpdates() {
    _stateSub = _recorder.onStateChanged().listen(_handleRecorderState);
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && _stopwatch.isRunning) {
        setState(() => _elapsed = _stopwatch.elapsed);
      }
    });
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((amp) {
          final normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0);
          if (mounted && !_paused) {
            setState(() {
              _waveformSamples.add(normalized.clamp(0.04, 1.0));
              if (_waveformSamples.length > _maxWaveformSamples) {
                _waveformSamples.removeAt(0);
              }
            });
          }
        });
  }

  Future<void> _togglePause() async {
    if (_starting || _finishing || _changingState || _finished) return;
    setState(() => _changingState = true);
    final shouldPause = !_paused;

    try {
      if (shouldPause) {
        await _recorder.pause();
        _stopwatch.stop();
      } else {
        await _recorder.resume();
        _stopwatch.start();
      }
      if (!mounted || _finished) return;
      setState(() {
        _paused = shouldPause;
        _elapsed = _stopwatch.elapsed;
      });
    } catch (error) {
      debugPrint('[AUDIO PAUSE ERROR] $error');
      if (mounted && !_finished) {
        AppSnackbar.error(
          'note_editor_error_title'.tr,
          'note_editor_could_not_change_recording'.tr,
        );
      }
    } finally {
      if (mounted && !_finished) {
        setState(() => _changingState = false);
      }
    }
  }

  void _handleRecorderState(RecordState state) {
    if (!mounted || _finished || _starting) return;

    switch (state) {
      case RecordState.pause:
        _stopwatch.stop();
        setState(() {
          _paused = true;
          _elapsed = _stopwatch.elapsed;
        });
      case RecordState.record:
        _stopwatch.start();
        setState(() => _paused = false);
      case RecordState.stop:
        _stopwatch.stop();
    }
  }

  Future<void> _stopForReview() async {
    if (_starting || _finishing || _changingState || _finished) return;
    setState(() => _changingState = true);

    _stopwatch.stop();
    _elapsed = _stopwatch.elapsed;
    await _stopLiveUpdates();

    String? path;
    try {
      path = await _recorder.stop();
      if (path == null) {
        throw StateError('Recorder returned no file');
      }
    } catch (error) {
      debugPrint('[AUDIO REVIEW ERROR] $error');
      if (!mounted || _finished) return;
      AppSnackbar.error(
        'note_editor_error_title'.tr,
        'note_editor_could_not_prepare_review'.tr,
      );
      try {
        if (await _recorder.isRecording()) {
          _startLiveUpdates();
          setState(() => _changingState = false);
          return;
        }
      } catch (_) {}
      setState(() => _changingState = false);
      unawaited(_finish(save: false));
      return;
    }

    _recordedPath = path;
    _isReviewing = true;

    var playbackReady = false;
    var duration = _elapsed;
    try {
      await _player.setSourceDeviceFile(path);
      duration = await _player.getDuration() ?? _elapsed;
      playbackReady = true;
    } catch (error) {
      debugPrint('[AUDIO REVIEW SOURCE ERROR] $error');
      if (!_finished) {
        AppSnackbar.error(
          'note_editor_error_title'.tr,
          'note_editor_could_not_play_recording'.tr,
        );
      }
    }

    if (!mounted || _finished) return;
    setState(() {
      _recordedPath = path;
      _playbackDuration = duration;
      _playbackPosition = Duration.zero;
      _isReviewing = true;
      _isPlaying = false;
      _playbackReady = playbackReady;
      _paused = false;
      _changingState = false;
    });
  }

  Future<void> _togglePlayback() async {
    if (!_isReviewing || !_playbackReady || _changingState || _finishing) {
      return;
    }
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_playbackDuration > Duration.zero &&
            _playbackPosition >= _playbackDuration) {
          await _player.seek(Duration.zero);
        }
        await _player.resume();
      }
    } catch (error) {
      debugPrint('[AUDIO REVIEW PLAY ERROR] $error');
      AppSnackbar.error(
        'note_editor_error_title'.tr,
        'note_editor_could_not_play_recording'.tr,
      );
    }
  }

  Future<void> _seekPlayback(double value) async {
    if (_playbackDuration <= Duration.zero) return;
    final target = Duration(
      milliseconds: (_playbackDuration.inMilliseconds * value).round(),
    );
    await _player.seek(target);
  }

  Future<void> _recordAgain() async {
    if (!_isReviewing || _changingState || _finishing) return;
    setState(() => _changingState = true);

    final oldPath = _recordedPath;
    try {
      await _player.stop();
      await _player.release();
      _deleteFileBestEffort(oldPath);
    } catch (error) {
      debugPrint('[AUDIO RESTART CLEANUP ERROR] $error');
    }

    _stopwatch
      ..reset()
      ..stop();
    if (!mounted || _finished) return;
    setState(() {
      _elapsed = Duration.zero;
      _playbackDuration = Duration.zero;
      _playbackPosition = Duration.zero;
      _recordedPath = null;
      _waveformSamples.clear();
      _isReviewing = false;
      _isPlaying = false;
      _playbackReady = false;
      _paused = false;
      _starting = true;
      _changingState = false;
    });
    await _start();
  }

  Future<void> _stopLiveUpdates() async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
    await _stateSub?.cancel();
    _stateSub = null;
  }

  Future<void> _finish({required bool save}) async {
    if (_finished) return;
    _finished = true;
    if (mounted) setState(() => _finishing = true);

    _stopwatch.stop();
    _elapsed = _stopwatch.elapsed;
    await _stopLiveUpdates();

    String? path = _isReviewing ? _recordedPath : null;
    var stopFailed = false;
    try {
      if (_isReviewing) {
        await _player.stop();
        if (!save) {
          await _player.release();
          _deleteFileBestEffort(path);
          path = null;
        }
      } else if (save) {
        path = await _recorder.stop();
      } else {
        await _recorder.cancel();
      }
    } catch (e) {
      debugPrint('[AUDIO STOP ERROR] $e');
      stopFailed = true;
    }
    await _recorder.dispose();

    if (save && (stopFailed || path == null)) {
      AppSnackbar.error(
        'note_editor_error_title'.tr,
        'note_editor_could_not_save_recording'.tr,
      );
    }

    if (save && path != null) {
      if (_elapsed >= _minKeepable) {
        await widget.onRecorded(path, _recordingName());
      } else {
        _deleteFileBestEffort(path);
        AppSnackbar.info(
          'note_editor_recording_too_short_title'.tr,
          'note_editor_recording_too_short_message'.tr,
        );
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ampSub?.cancel();
    _stateSub?.cancel();
    _playbackDurationSub?.cancel();
    _playbackPositionSub?.cancel();
    _playbackCompleteSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    if (!_finished) {
      _finished = true;

      unawaited(
        _recorder.cancel().catchError((_) {}).whenComplete(_recorder.dispose),
      );
      if (_isReviewing) _deleteFileBestEffort(_recordedPath);
    }
    super.dispose();
  }

  void _deleteFileBestEffort(String? path) {
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (error) {
      debugPrint('[AUDIO TEMP DELETE ERROR] $error');
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds.$tenths';
  }

  String _recordingName() {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final date = '${now.year}-${twoDigits(now.month)}-${twoDigits(now.day)}';
    final time =
        '${twoDigits(now.hour)}-${twoDigits(now.minute)}-${twoDigits(now.second)}';
    return '${'note_editor_recording_fallback_name'.tr} $date $time.m4a';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final iosBlue = CupertinoColors.activeBlue.resolveFrom(context);
    final systemRed = CupertinoColors.systemRed.resolveFrom(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(save: false);
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _finishing || _changingState
                              ? null
                              : () => _finish(save: false),
                          child: Text(
                            'Cancel'.tr,
                            style: TextStyle(color: iosBlue),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'record audio'.tr,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _starting || _finishing || _changingState
                              ? null
                              : () => _finish(save: true),
                          child: Text(
                            'Done'.tr,
                            style: TextStyle(
                              color: _starting || _finishing || _changingState
                                  ? iosBlue.withValues(alpha: 0.35)
                                  : iosBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: CustomGlassContainer(
                      width: double.infinity,
                      borderRadius: 30,
                      blur: 14,
                      opacity: 0.13,
                      thickness: 10,
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RecordingStatus(
                            label: _statusLabel,
                            isPaused: _paused,
                            isBusy: _starting || _finishing || _changingState,
                          ),
                          const SizedBox(height: 22),
                          Text(
                            _formatDuration(
                              _isReviewing ? _playbackPosition : _elapsed,
                            ),
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: colors.primaryText,
                              fontSize: 44,
                              height: 1,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -1.5,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Semantics(
                            label: 'live'.tr,
                            image: true,
                            child: SizedBox(
                              height: 112,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _WaveformPainter(
                                  samples: List<double>.of(_waveformSamples),
                                  color: _paused
                                      ? CupertinoColors.systemOrange
                                            .resolveFrom(context)
                                      : systemRed,
                                  guideColor: colors.divider,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_isReviewing) ...[
                            CupertinoSlider(
                              value: _playbackProgress,
                              activeColor: iosBlue,
                              onChanged:
                                  _playbackReady &&
                                      _playbackDuration > Duration.zero
                                  ? _seekPlayback
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatReviewDuration(_playbackPosition),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.secondaryText,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatReviewDuration(_playbackDuration),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.secondaryText,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                          ] else
                            Text(
                              _paused ? 'resume'.tr : 'recording'.tr,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.secondaryText,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isReviewing) ...[
                      _RecorderAction(
                        icon: CupertinoIcons.arrow_counterclockwise,
                        label: 'record'.tr,
                        color: CupertinoColors.systemOrange.resolveFrom(
                          context,
                        ),
                        onPressed: _finishing || _changingState
                            ? null
                            : _recordAgain,
                      ),
                      const SizedBox(width: 28),
                      _RecorderAction(
                        icon: _isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        label: _isPlaying ? 'pause'.tr : 'play'.tr,
                        color: iosBlue,
                        onPressed:
                            !_playbackReady || _finishing || _changingState
                            ? null
                            : _togglePlayback,
                        emphasized: true,
                      ),
                    ] else ...[
                      _RecorderAction(
                        icon: _paused
                            ? CupertinoIcons.play_fill
                            : CupertinoIcons.pause_fill,
                        label: _paused ? 'resume'.tr : 'pause'.tr,
                        color: _paused
                            ? CupertinoColors.systemGreen.resolveFrom(context)
                            : CupertinoColors.systemOrange.resolveFrom(context),
                        onPressed: _starting || _finishing || _changingState
                            ? null
                            : _togglePause,
                      ),
                      const SizedBox(width: 28),
                      _RecorderAction(
                        icon: CupertinoIcons.stop_fill,
                        label: 'recording'.tr,
                        color: systemRed,
                        onPressed: _starting || _finishing || _changingState
                            ? null
                            : _stopForReview,
                        emphasized: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _statusLabel {
    if (_starting) return 'note_editor_recording_starting'.tr;
    if (_finishing) return 'note_editor_recording_saving'.tr;
    if (_changingState) return 'note_editor_recording_updating'.tr;
    if (_isReviewing && _isPlaying) {
      return 'note_editor_playing_preview'.tr;
    }
    if (_isReviewing) return 'note_editor_ready_to_save'.tr;
    if (_paused) return 'note_editor_recording_paused'.tr;
    return 'note_editor_recording_status'.tr;
  }

  double get _playbackProgress {
    if (_playbackDuration <= Duration.zero) return 0;
    return (_playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  String _formatReviewDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _RecorderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool emphasized;

  const _RecorderAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final size = emphasized ? 76.0 : 66.0;

    return SizedBox(
      width: 108,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomGlassButton(
            onPressed: onPressed,
            semanticLabel: label,
            width: size,
            height: size,
            padding: EdgeInsets.zero,
            shape: GlassShape.circle,
            foregroundColor: color,
            glassColor: color.withValues(alpha: 0.12),
            blur: 14,
            opacity: 0.2,
            thickness: 9,
            child: Icon(icon, size: emphasized ? 30 : 26),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingStatus extends StatelessWidget {
  final String label;
  final bool isPaused;
  final bool isBusy;

  const _RecordingStatus({
    required this.label,
    required this.isPaused,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPaused
        ? CupertinoColors.systemOrange.resolveFrom(context)
        : CupertinoColors.systemRed.resolveFrom(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBusy)
            CupertinoActivityIndicator(radius: 7, color: color)
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  static const _barCount = 56;
  final List<double> samples;
  final Color color;
  final Color guideColor;

  const _WaveformPainter({
    required this.samples,
    required this.color,
    required this.guideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      Paint()
        ..color = guideColor.withValues(alpha: 0.55)
        ..strokeWidth = 1,
    );

    const gap = 2.4;
    final barWidth = (size.width - gap * (_barCount - 1)) / _barCount;
    final visibleSamples = samples.length > _barCount
        ? samples.sublist(samples.length - _barCount)
        : samples;
    final leadingEmpty = _barCount - visibleSamples.length;

    for (var index = 0; index < _barCount; index++) {
      final hasSample = index >= leadingEmpty;
      final sample = hasSample ? visibleSamples[index - leadingEmpty] : 0.035;
      final height = 4 + sample * (size.height - 10);
      final age = index / (_barCount - 1);
      final paint = Paint()
        ..color = color.withValues(alpha: hasSample ? 0.3 + age * 0.7 : 0.12)
        ..strokeWidth = barWidth.clamp(2.0, 4.0)
        ..strokeCap = StrokeCap.round;
      final x = index * (barWidth + gap) + barWidth / 2;
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.color != color ||
      oldDelegate.guideColor != guideColor;
}
