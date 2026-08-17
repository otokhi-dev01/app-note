import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/note/domain/entities/note.dart';

/// What a query matched.
class SearchResults {
  final List<Note> notes;
  final List<Folder> folders;

  const SearchResults({this.notes = const [], this.folders = const []});

  const SearchResults.empty() : this();

  List<Note> get pinnedNotes =>
      notes.where((n) => n.isPinned).toList(growable: false);

  List<Note> get otherNotes =>
      notes.where((n) => !n.isPinned).toList(growable: false);

  bool get isEmpty => notes.isEmpty && folders.isEmpty;
}

/// The canned queries offered as chips before the user types anything.
///
/// Modelled as an enum so the matching rule lives next to the label instead of
/// being re-derived from a lowercased string in the controller.
enum SearchFilter {
  shared('Shared Notes'),
  locked('Locked Notes'),
  checklists('Notes with Checklists'),
  tags('Notes with Tags'),
  drawings('Notes with Drawings'),
  scanned('Notes with Scanned Documents'),
  attachments('Notes with Attachments');

  final String label;

  const SearchFilter(this.label);

  /// The filter whose label equals [query], or `null` for a free-text search.
  static SearchFilter? fromQuery(String query) {
    final normalized = query.trim().toLowerCase();
    for (final filter in SearchFilter.values) {
      if (filter.label.toLowerCase() == normalized) return filter;
    }
    return null;
  }
}
