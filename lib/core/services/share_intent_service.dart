import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/routes/note_navigation.dart';

/// Listens for files, photos, and videos shared into the app from
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
  bool _navigationReady = false;
  bool _openScheduled = false;
  final Set<String> _pendingPaths = {};

  /// Starts listening. Safe to call more than once — only the first call
  /// does anything.
  void start() {
    if (_started) return;
    _started = true;

    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleShared,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[SHARE INTENT] stream error: $error');
      },
    );
    unawaited(_consumeInitialShare());
  }

  /// Wait for the home route before opening a shared note. Splash and sign-in
  /// replace the route stack, so navigating during either would lose the note.
  void onRouteChanged(String? route) {
    if (const {
      Routes.SPLASH,
      Routes.ONBOARDING,
      Routes.LOGIN,
      Routes.REGISTER,
      Routes.FORGOT_PASSWORD,
    }.contains(route)) {
      _navigationReady = false;
    } else if (route == Routes.FOLDER) {
      _navigationReady = true;
    }
    _scheduleOpen();
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
    if (!_started || files.isEmpty) return;

    for (final file in files) {
      if (file.type == SharedMediaType.text ||
          file.type == SharedMediaType.url) {
        continue;
      }
      try {
        final path = normalizeLocalPath(file.path);
        if (path != null && File(path).existsSync()) _pendingPaths.add(path);
      } catch (error) {
        debugPrint('[SHARE INTENT] unreadable file: $error');
      }
    }

    // Snapshot the files before reset; the plugin can clear the original list.
    unawaited(_reset());
    _scheduleOpen();
  }

  Future<void> _reset() async {
    try {
      await ReceiveSharingIntent.instance.reset();
    } catch (error) {
      debugPrint('[SHARE INTENT] reset error: $error');
    }
  }

  void _scheduleOpen() {
    if (!_started ||
        !_navigationReady ||
        _pendingPaths.isEmpty ||
        _openScheduled) {
      return;
    }
    _openScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openScheduled = false;
      if (!_started || !_navigationReady || _pendingPaths.isEmpty) return;
      final paths = _pendingPaths.toList();
      _pendingPaths.clear();
      NoteNavigation.toNewNoteFromSharedFiles(0, paths);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @visibleForTesting
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _started = false;
    _navigationReady = false;
    _openScheduled = false;
    _pendingPaths.clear();
  }
}
