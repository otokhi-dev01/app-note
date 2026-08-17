import 'package:Note/core/error/result.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';
import 'package:Note/features/search/domain/entities/search_results.dart';

/// Searches notes and folders in one pass.
///
/// Composes two repositories, which is exactly the kind of cross-feature
/// coordination a use case exists for — the controller just renders the result.
class SearchNotesAndFolders extends UseCase<SearchResults, String> {
  final NoteRepository _notes;
  final FolderRepository _folders;

  const SearchNotesAndFolders(this._notes, this._folders);

  @override
  Future<Result<SearchResults>> call(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const Ok(SearchResults.empty());

    final noteResult = await _notes.getNotes();
    if (noteResult case Err(:final failure)) return Err(failure);

    final folderResult = await _folders.getFolders();
    if (folderResult case Err(:final failure)) return Err(failure);

    final allNotes = noteResult.valueOrNull!.notes;
    final allFolders = folderResult.valueOrNull!.folders;

    final filter = SearchFilter.fromQuery(trimmed);
    if (filter != null) {
      // A canned filter narrows notes only — folders are not part of it.
      return Ok(SearchResults(notes: _applyFilter(allNotes, filter)));
    }

    final lower = trimmed.toLowerCase();
    return Ok(
      SearchResults(
        notes: allNotes
            .where(
              (n) =>
                  n.title.toLowerCase().contains(lower) ||
                  n.folderName.toLowerCase().contains(lower),
            )
            .toList(),
        folders: allFolders
            .where((f) => f.name.toLowerCase().contains(lower))
            .toList(),
      ),
    );
  }

  List<Note> _applyFilter(
    List<Note> notes,
    SearchFilter filter,
  ) => switch (filter) {
    SearchFilter.shared =>
      notes
          .where((n) => n.folderName.toLowerCase().contains('shared'))
          .toList(),
    SearchFilter.locked => notes.where((n) => n.isLocked).toList(),
    SearchFilter.checklists =>
      notes.where((n) => n.content.any((b) => b is ChecklistBlock)).toList(),
    SearchFilter.tags => notes.where((n) => n.title.contains('#')).toList(),
    SearchFilter.drawings =>
      notes.where((n) => n.content.any((b) => b is DrawingBlock)).toList(),
    SearchFilter.scanned => notes.where((n) => n.attachmentCount > 0).toList(),
    SearchFilter.attachments =>
      notes
          .where(
            (n) =>
                n.attachmentCount > 0 ||
                n.content.any((b) => b is AttachmentBlock),
          )
          .toList(),
  };
}
