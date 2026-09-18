import 'dart:async';

import 'package:get/get.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/routes/app_pages.dart';

class SplashController extends GetxController {
  final _session = Get.find<SessionStorage>();
  final _guestMode = Get.find<GuestModeService>();
  final isRestoring = true.obs;
  final restoreFailed = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_navigateToNext());
  }

  Future<void> _navigateToNext() async {
    // Animation and secure-storage restoration run together. Never choose a
    // signed-out route just because a slow Keychain read exceeded the animation.
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 3500)),
      _session.ready,
    ]);
    _finishRestore();
  }

  void _finishRestore() {
    if (isClosed) return;
    isRestoring.value = false;
    restoreFailed.value = _session.restoreFailed.value;
    if (restoreFailed.value) return;
    if (_session.isLoggedIn) {
      // A persisted signed-in account takes precedence over stale guest flags.
      _guestMode.disable();
      unawaited(Get.offAllNamed(Routes.FOLDER));
    } else if (_guestMode.isGuestMode.value) {
      unawaited(Get.offAllNamed(Routes.FOLDER));
    } else {
      unawaited(Get.offAllNamed(Routes.ONBOARDING));
    }
  }

  Future<void> retryRestore() async {
    if (isClosed || isRestoring.value) return;
    isRestoring.value = true;
    await _session.loadSession();
    _finishRestore();
  }
}
