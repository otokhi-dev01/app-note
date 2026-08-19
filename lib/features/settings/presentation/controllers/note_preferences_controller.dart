import 'package:get/get.dart';

import 'package:Note/core/storage/display_preferences.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';

/// Persisted defaults for how the Folder and Note-list screens display and
/// sort — set here, and read fresh by each of those controllers on init.
///
/// Also pushes the change into a live [NoteController]/[FolderController]
/// when one happens to already be alive in the navigation stack, so a
/// change made from Settings takes effect immediately rather than only on
/// the next time those screens are opened fresh.
class NotePreferencesController extends GetxController {
  final _prefs = DisplayPreferences();

  late final viewMode = _prefs.noteViewMode.obs;
  late final sortByName = _prefs.noteSortByName.obs;
  late final folderGroupByDate = _prefs.folderGroupByDate.obs;

  void setViewMode(String mode) {
    viewMode.value = mode;
    _prefs.setNoteViewMode(mode);
    if (Get.isRegistered<NoteController>()) {
      Get.find<NoteController>().applyViewMode(mode);
    }
  }

  void setSortByName(bool value) {
    sortByName.value = value;
    _prefs.setNoteSortByName(value);
    if (Get.isRegistered<NoteController>()) {
      Get.find<NoteController>().applySortByName(value);
    }
  }

  void setFolderGroupByDate(bool value) {
    folderGroupByDate.value = value;
    _prefs.setFolderGroupByDate(value);
    if (Get.isRegistered<FolderController>()) {
      final fc = Get.find<FolderController>();
      fc.isGroupedByDate.value = value;
      fc.sortFolders();
    }
  }
}
