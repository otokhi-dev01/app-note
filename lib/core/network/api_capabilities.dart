/// What the PiisiitNoteApi backend actually supports.
///
/// Verified against https://note.piisiit.com/swagger/v1/swagger.json (v1) on
/// 2026-08-17. Flip these to `true` once the endpoints ship, and the UI will
/// re-enable the corresponding actions automatically.
class ApiCapabilities {
  ApiCapabilities._();

  /// No /api/note/permanent-delete, /api/note/empty-trash, or
  /// /api/folder/permanent-delete route exists. Trash is soft-delete only.
  static const bool permanentDelete = false;

  /// No /api/auth/forgot-password route exists.
  static const bool forgotPassword = false;
}
