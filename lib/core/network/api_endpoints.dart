abstract final class ApiEndpoints {
  // Authentication
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';

  // Folders
  static const String folders = '/api/folder';
  static const String saveFolder = '/api/folder/save';
  static const String deleteRestoreFolder = '/api/folder/delete-restore';

  // Notes
  static const String notes = '/api/note';
  static const String saveNote = '/api/note/save';

  /// Saves a note's ordered content blocks after the note header exists.
  static const String saveContent = '/api/note/save-content';

  static const String noteAttachment = '/api/note/attachment';
  static const String updateNoteState = '/api/note/update-state';

  static String noteDetail(int noteId) => '/api/note/$noteId';
}
