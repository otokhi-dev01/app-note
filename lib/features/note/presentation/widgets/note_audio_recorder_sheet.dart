import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// Full-screen "Record Audio" flow.
///
/// Starts recording the instant it opens (there's nothing to configure
/// first — Voice Memos-style) and shows elapsed time plus a live level
/// meter driven by the recorder's own amplitude stream. The sheet owns the
/// entire record/stop/cancel lifecycle itself; [onRecorded] only fires once
/// with a finished file, so the caller never has to think about recorder
/// state — cancelling always discards whatever was captured, nothing is
/// ever handed back half-done.
class NoteAudioRecorderSheet extends StatefulWidget {
  final void Function(String path, String displayName) onRecorded;

  const NoteAudioRecorderSheet({super.key, required this.onRecorded});

  @override
  State<NoteAudioRecorderSheet> createState() =>
      _NoteAudioRecorderSheetState();
}

class _NoteAudioRecorderSheetState extends State<NoteAudioRecorderSheet> {
  static const _minKeepable = Duration(milliseconds: 500);

  final _recorder = AudioRecorder();
  Timer? _ticker;
  StreamSubscription<Amplitude>? _ampSub;
  Duration _elapsed = Duration.zero;
  double _level = 0;
  bool _starting = true;
  // Guards against running the stop/cancel/dispose sequence twice — once
  // from a button tap and again from dispose() if the route is popped some
  // other way (e.g. a back gesture).
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      AppSnackbar.error(
        'Microphone unavailable',
        'Enable microphone access in Settings to record audio.',
      );
      Navigator.of(context).pop();
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _recorder.start(const RecordConfig(), path: path);
    } catch (e) {
      debugPrint('[AUDIO RECORD ERROR] $e');
      if (!mounted) return;
      AppSnackbar.error('Error', 'Could not start recording');
      Navigator.of(context).pop();
      return;
    }

    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() => _elapsed += const Duration(milliseconds: 200));
    });
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((amp) {
          // dBFS: silence sits around -45 and below, 0 is the loudest the
          // hardware reports — normalize that range to a 0..1 meter.
          final normalized = ((amp.current + 45) / 45).clamp(0.0, 1.0);
          if (mounted) setState(() => _level = normalized);
        });

    if (mounted) setState(() => _starting = false);
  }

  Future<void> _finish({required bool save}) async {
    if (_finished) return;
    _finished = true;

    _ticker?.cancel();
    await _ampSub?.cancel();

    String? path;
    try {
      if (save) {
        path = await _recorder.stop();
      } else {
        await _recorder.cancel();
      }
    } catch (e) {
      debugPrint('[AUDIO STOP ERROR] $e');
    }
    await _recorder.dispose();

    if (save && path != null) {
      if (_elapsed >= _minKeepable) {
        widget.onRecorded(path, 'Recording.m4a');
      } else {
        // Too short to be a real recording (e.g. an accidental tap) — don't
        // leave a near-silent file behind.
        try {
          File(path).deleteSync();
        } catch (_) {}
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ampSub?.cancel();
    if (!_finished) {
      _finished = true;
      // Torn down some other way (e.g. a back gesture bypassing the Cancel
      // button) — best-effort cleanup so the recorder doesn't leak.
      unawaited(_recorder.cancel().catchError((_) {}).whenComplete(_recorder.dispose));
    }
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // Every exit — Cancel, Done, or a back gesture — goes through
      // _finish so the recorder is always stopped/disposed cleanly instead
      // of racing the route's own pop animation.
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _finish(save: false),
                      child: const Text('Cancel'),
                    ),
                    Text(
                      'Record Audio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 56),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LevelIndicator(level: _starting ? 0 : _level),
                      const SizedBox(height: 28),
                      Text(
                        _formatDuration(_elapsed),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w300,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _starting ? 'Starting…' : 'Recording',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32, top: 12),
                child: CustomGlassButton(
                  onPressed: _starting ? null : () => _finish(save: true),
                  width: 72,
                  height: 72,
                  padding: EdgeInsets.zero,
                  shape: GlassShape.circle,
                  foregroundColor: AppTheme.folderPink,
                  blur: 12,
                  opacity: 0.18,
                  thickness: 8,
                  child: const Icon(CupertinoIcons.checkmark, size: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pulsing red circle that scales with [level] (0..1) — the same "the mic
/// is live and hearing you" affordance Voice Memos and every other recorder
/// uses, just simplified to a single shape instead of a waveform.
class _LevelIndicator extends StatelessWidget {
  final double level;

  const _LevelIndicator({required this.level});

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + level * 0.4;
    return SizedBox(
      width: 140,
      height: 140,
      child: Center(
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.systemRed.withValues(
                alpha: 0.15 + level * 0.15,
              ),
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.mic_fill,
                color: CupertinoColors.systemRed,
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
