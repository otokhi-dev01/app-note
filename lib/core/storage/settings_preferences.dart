import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Reactive, persisted preferences owned by the Settings drawer.
class SettingsPreferences extends GetxService {
  final _storage = GetStorage();

  static const _hideNotePreviewsKey = 'settingsHideNotePreviews';

  late final hideNotePreviews =
      (_storage.read<bool>(_hideNotePreviewsKey) ?? false).obs;

  void setHideNotePreviews(bool value) {
    hideNotePreviews.value = value;
    _storage.write(_hideNotePreviewsKey, value);
  }
}
