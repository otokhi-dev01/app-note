import 'package:Note/core/utils/json_parsers.dart';
import 'package:Note/features/note/data/models/note_model.dart';

/// The `/api/note` envelope, split into the three buckets the UI shows.
///
/// The endpoint has shipped several shapes over time — a bare list, a map of
/// `note`/`archive`/`trash`, and a nested `data.data` list — so all three are
/// handled, then re-categorized from the notes' own flags because the server
/// sometimes files an archived note under `note`.
class NoteResponse {
  final int code;
  final String message;
  final List<NoteModel> notes;
  final List<NoteModel> archive;
  final List<NoteModel> trash;

  const NoteResponse({
    required this.code,
    required this.message,
    required this.notes,
    required this.archive,
    required this.trash,
  });

  const NoteResponse.empty()
    : code = 0,
      message = '',
      notes = const [],
      archive = const [],
      trash = const [];

  factory NoteResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    List<NoteModel> active = [];
    List<NoteModel> archived = [];
    List<NoteModel> deleted = [];

    void categorize(List<NoteModel> all) {
      active = all.where((n) => !n.isArchived && !n.isDeleted).toList();
      archived = all.where((n) => n.isArchived && !n.isDeleted).toList();
      deleted = all.where((n) => n.isDeleted).toList();
    }

    List<NoteModel> parseAll(List raw) => raw
        .whereType<Map>()
        .map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (rawData is List) {
      categorize(parseAll(rawData));
    } else if (rawData is Map) {
      final List rawNotes = (rawData['note'] ?? rawData['notes'] ?? []) as List;
      final List rawArchive =
          (rawData['archive'] ?? rawData['archived'] ?? []) as List;
      final List rawTrash =
          (rawData['trash'] ?? rawData['deleted'] ?? []) as List;

      if (rawNotes.isNotEmpty || rawArchive.isNotEmpty || rawTrash.isNotEmpty) {
        categorize([
          ...parseAll(rawNotes),
          ...parseAll(rawArchive),
          ...parseAll(rawTrash),
        ]);
      } else {
        categorize(parseAll((rawData['data'] ?? []) as List));
      }
    }

    return NoteResponse(
      code: asInt(json['code'] ?? json['Code']),
      message: asString(json['message'] ?? json['Message']),
      notes: active,
      archive: archived,
      trash: deleted,
    );
  }
}
