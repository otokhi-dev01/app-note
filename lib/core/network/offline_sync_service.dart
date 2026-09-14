import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/folder/data/repositories/folder_sync_repository.dart';
import 'package:Note/features/note/data/repositories/note_sync_repository.dart';

/// Retries queued offline folder/note writes for a signed-in account.
///
/// `FolderSyncRepository`/`NoteSyncRepository` already flush their own
/// queues opportunistically — at the start of every read and write — which
/// covers the vast majority of real usage: reconnecting almost always
/// happens while the user is still doing something in the app. This service
/// covers the one gap that leaves — a user who goes offline, backgrounds
/// the app, and comes back later — with a flush on every app resume, the
/// moment a phone most often regains a signal.
///
/// Deliberately event-driven rather than a background poll timer: a
/// `permanent: true` GetxService lives for the app's whole lifetime, and a
/// live `Timer.periodic` on it stays pending through every widget test that
/// boots `InitialBinding` — which is most of this suite — tripping
/// flutter_test's "no pending timers" invariant. Resume-triggered is both
/// simpler and free of that problem.
///
/// Never used in guest mode — there is nothing to sync, `LocalFolderRepository`
/// / `LocalNoteRepository` are the only copy of guest data that exists.
class OfflineSyncService extends GetxService with WidgetsBindingObserver {
  final SessionStorage _session;
  final GuestModeService _guestMode;
  final FolderSyncRepository _folders;
  final NoteSyncRepository _notes;

  OfflineSyncService(
    this._session,
    this._guestMode,
    this._folders,
    this._notes,
  );

  /// True while a folder or note write is still waiting to reach the
  /// server — for a "syncing…" indicator elsewhere in the app, if one is
  /// wanted; nothing currently reads this.
  bool get hasPendingChanges =>
      _folders.pendingCount > 0 || _notes.pendingCount > 0;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_flushIfNeeded());
  }

  Future<void> _flushIfNeeded() async {
    if (_guestMode.isGuestMode.value || !_session.isLoggedIn) return;
    if (!hasPendingChanges) return;
    try {
      await _folders.flushPending();
      await _notes.flushPending();
    } catch (e) {
      // Best-effort background retry — a failed attempt here must never
      // crash the app; the next timer tick or resume will just try again.
      if (kDebugMode) debugPrint('[SYNC] Background flush failed: $e');
    }
  }
}
