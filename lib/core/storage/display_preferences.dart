import 'package:get_storage/get_storage.dart';

/// Persisted defaults for how lists are displayed — read once by each screen
/// on init, and written back whenever the user changes the setting, either
/// from a screen's own quick menu or from Settings directly.
///
/// Modeled on [ThemeStorage]: a thin GetStorage wrapper rather than a GetX
/// service, since every value here is a plain read/write with no shared
/// reactive state to own.
class DisplayPreferences {
  final _storage = GetStorage();

  static const _noteViewModeKey = 'defaultNoteViewMode';
  static const _noteSortByNameKey = 'defaultNoteSortByName';
  static const _folderViewModeKey = 'defaultFolderViewMode';
  static const _folderGroupByDateKey = 'defaultFolderGroupByDate';

  /// 'list' or 'gallery'.
  String get noteViewMode => _storage.read(_noteViewModeKey) ?? 'list';
  void setNoteViewMode(String mode) => _storage.write(_noteViewModeKey, mode);

  /// Notes sort by last-edited date when false, alphabetically when true.
  bool get noteSortByName => _storage.read(_noteSortByNameKey) ?? false;
  void setNoteSortByName(bool value) =>
      _storage.write(_noteSortByNameKey, value);

  /// 'short' hides folder subtitles; 'list' shows the detailed folder rows.
  String get folderViewMode => _storage.read(_folderViewModeKey) ?? 'list';
  void setFolderViewMode(String mode) =>
      _storage.write(_folderViewModeKey, mode);

  /// Folders sort by their manual sort order + name when false, by
  /// last-updated date when true.
  bool get folderGroupByDate => _storage.read(_folderGroupByDateKey) ?? false;
  void setFolderGroupByDate(bool value) =>
      _storage.write(_folderGroupByDateKey, value);
}
