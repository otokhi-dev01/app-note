import 'package:notes/features/notes/domain/entities/note.dart';

/// Small host contract used by library projections.
///
/// It keeps library pages independent from the notes home controller while the
/// app shell remains responsible for navigation and shared note state.
abstract interface class LibraryCoordinator {
  List<Note> get notes;
  List<Note> get trashNotes;
  int get selectedCalendarDayValue;

  Future<void> loadNotes();
  Future<void> openCreateNote();
  Future<void> openNote(Note note);
  void search(String query);
  void searchCategory(String category);
  void selectTab(int index);
  void setSelectedCalendarDay(int day);
  void showTrash();
}
