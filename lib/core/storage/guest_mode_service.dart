import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Tracks whether the app is running in local-only "Continue without
/// account" mode, as distinct from merely being logged out (e.g. sitting on
/// the Login screen).
///
/// While true, [FolderRepositoryRouter]/[NoteRepositoryRouter] read and write
/// on-device storage instead of the network, so folder/note features work
/// without an account — required by App Store guideline 5.1.1(v).
class GuestModeService extends GetxService {
  static const _key = 'isGuestMode';
  final _storage = GetStorage();

  final isGuestMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    isGuestMode.value = _storage.read(_key) ?? false;
  }

  void enable() {
    isGuestMode.value = true;
    _storage.write(_key, true);
  }

  void disable() {
    isGuestMode.value = false;
    _storage.write(_key, false);
  }
}
