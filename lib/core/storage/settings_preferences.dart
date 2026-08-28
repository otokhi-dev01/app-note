import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Reactive, persisted preferences owned by the Settings drawer.
class SettingsPreferences extends GetxService {
  final _storage = GetStorage();

  static const _actionConfirmationsKey = 'settingsActionConfirmations';
  static const _hideNotePreviewsKey = 'settingsHideNotePreviews';

  late final actionConfirmations =
      (_storage.read<bool>(_actionConfirmationsKey) ?? true).obs;
  late final hideNotePreviews =
      (_storage.read<bool>(_hideNotePreviewsKey) ?? false).obs;

  void setActionConfirmations(bool value) {
    actionConfirmations.value = value;
    _storage.write(_actionConfirmationsKey, value);
  }

  void setHideNotePreviews(bool value) {
    hideNotePreviews.value = value;
    _storage.write(_hideNotePreviewsKey, value);
  }
}
