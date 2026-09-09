import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:Note/routes/note_navigation.dart';

/// Listens for files, photos, videos, and links shared into the app from
/// another app's system share sheet — Telegram's "Share" menu on a
/// document, for instance — and drops them straight into a brand-new note.
///
/// Covers both hand-offs the `receive_sharing_intent` plugin exposes:
/// a cold start (the OS launched Pii Note *because* of the share) via
/// [ReceiveSharingIntent.getInitialMedia], and a warm share (the app was
/// already running) via [ReceiveSharingIntent.getMediaStream]. Android picks
/// this up through the `SEND`/`SEND_MULTIPLE` intent-filters on
/// `MainActivity`; iOS through the "Share Extension" target and its
/// App Group hand-off — see the plugin's own iOS setup for that half.
///
/// Started once, for the app's lifetime, from [NoteApp.initState].
class ShareIntentService {
  ShareIntentService._();
  static final ShareIntentService instance = ShareIntentService._();

  StreamSubscription<List<SharedMediaFile>>? _subscription;
  bool _started = false;

  /// Starts listening. Safe to call more than once — only the first call
  /// does anything.
  void start() {
    if (_started) return;
    _started = true;

    unawaited(_consumeInitialShare());

    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleShared,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[SHARE INTENT] stream error: $error');
      },
    );
  }

  Future<void> _consumeInitialShare() async {
    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initial.isNotEmpty) _handleShared(initial);
    } catch (error) {
      debugPrint('[SHARE INTENT] initial media error: $error');
    }
  }

  void _handleShared(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    // Acknowledge unconditionally, even when nothing usable came through,
    // so the plugin clears its native-side state before the next share.
    unawaited(ReceiveSharingIntent.instance.reset());

    final paths = files
        .map((file) => file.path)
        .where((path) => path.isNotEmpty && File(path).existsSync())
        .toSet() // a multi-select share can list the same path twice
        .toList();
    if (paths.isEmpty) return;

    NoteNavigation.toNewNoteFromSharedFiles(0, paths);
  }

  @visibleForTesting
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
