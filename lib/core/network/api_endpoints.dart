abstract final class ApiEndpoints {
  // ===========================================================================
  // AUTHENTICATION
  // ===========================================================================

  static const String login =
      '/api/auth/login';

  static const String register =
      '/api/auth/register';

  // ===========================================================================
  // FOLDERS
  // ===========================================================================

  static const String folders =
      '/api/folder';

  static const String saveFolder =
      '/api/folder/save';

  static const String deleteRestoreFolder =
      '/api/folder/delete-restore';

  static const String deletedFolders =
      '/api/folder/deleted';

  // ===========================================================================
  // NOTES
  // ===========================================================================

  static const String notes =
      '/api/note';

  static const String saveNote =
      '/api/note/save';

  static const String saveContent =
      '/api/note/save-content';

  static const String noteAttachment =
      '/api/note/attachment';

  static const String updateNoteState =
      '/api/note/update-state';

  static String noteDetail(int noteId) {
    return '/api/note/$noteId';
  }
}