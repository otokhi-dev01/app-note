import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DailyNote {
  final String id;
  final DateTime date;
  final String title;
  final String body;
  final int startMinute;
  final int endMinute;
  final int color;
  final List<String> photoPaths;

  const DailyNote({
    required this.id,
    required this.date,
    required this.title,
    this.body = '',
    required this.startMinute,
    required this.endMinute,
    required this.color,
    this.photoPaths = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': dateKey(date),
    'title': title,
    'body': body,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'color': color,
    'photoPaths': photoPaths,
  };

  factory DailyNote.fromJson(Map<String, dynamic> json) => DailyNote(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    title: json['title'] as String,
    body: json['body'] as String? ?? '',
    startMinute: json['startMinute'] as int,
    endMinute: json['endMinute'] as int,
    color: json['color'] as int,
    photoPaths: List<String>.from(json['photoPaths'] as List? ?? const []),
  );

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Local daily entries are kept separate for guests and each signed-in account.
/// This store does not claim to sync with Pii Cloud.
class DailyNoteStore {
  final GetStorage storage;
  final String owner;
  final Future<Directory> Function() _documentsDirectory;

  DailyNoteStore({
    required this.storage,
    required this.owner,
    Future<Directory> Function()? documentsDirectory,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  Future<Directory> _photoDirectory() async {
    final documents = await _documentsDirectory();
    return Directory(
      '${documents.path}/daily_note_photos/${Uri.encodeComponent(owner)}',
    );
  }

  String get _key => 'daily_notes_v1_$owner';

  List<DailyNote> read() => (storage.read<List<dynamic>>(_key) ?? [])
      .map((item) => DailyNote.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();

  Future<void> save(DailyNote note) async {
    if (note.title.trim().isEmpty ||
        note.startMinute < 0 ||
        note.endMinute > 1440 ||
        note.endMinute <= note.startMinute) {
      throw ArgumentError('A title and a valid time range are required.');
    }
    final entries = read();
    final previousPhotos = entries
        .where((item) => item.id == note.id)
        .expand((item) => item.photoPaths)
        .toList();
    final copied = <String>[];
    final photos = <String>[];
    try {
      if (note.photoPaths.isNotEmpty) {
        final directory = await _photoDirectory();
        await directory.create(recursive: true);
        for (final path in note.photoPaths) {
          if (File(path).parent.path == directory.path) {
            photos.add(path);
          } else {
            final extension =
                RegExp(r'\.[a-zA-Z0-9]+$').firstMatch(path)?.group(0) ?? '.jpg';
            final destination =
                '${directory.path}/${const Uuid().v4()}$extension';
            copied.add(destination);
            await File(path).copy(destination);
            photos.add(destination);
          }
        }
      }
      final saved = DailyNote.fromJson({
        ...note.toJson(),
        'photoPaths': photos,
      });
      entries.removeWhere((item) => item.id == note.id);
      entries.add(saved);
      await storage.write(_key, entries.map((item) => item.toJson()).toList());
    } catch (_) {
      await _removePhotos(copied);
      rethrow;
    }
    await _removePhotos(previousPhotos.where((path) => !photos.contains(path)));
  }

  Future<void> delete(String id) async {
    final entries = read();
    final photos = entries
        .where((item) => item.id == id)
        .expand((item) => item.photoPaths)
        .toList();
    entries.removeWhere((item) => item.id == id);
    await storage.write(_key, entries.map((item) => item.toJson()).toList());
    await _removePhotos(photos);
  }

  Future<void> _removePhotos(Iterable<String> paths) async {
    if (paths.isEmpty) return;
    // Only remove owned files that are no longer referenced by any daily note.
    // A cleanup failure must not turn a successful note save into an error.
    try {
      final directory = await _photoDirectory();
      final retained = read().expand((item) => item.photoPaths).toSet();
      for (final path in paths) {
        if (File(path).parent.path != directory.path ||
            retained.contains(path)) {
          continue;
        }
        try {
          await File(path).delete();
        } on FileSystemException {
          // The file may already be absent or temporarily unavailable.
        }
      }
    } on FileSystemException {
      // Leave inaccessible files in place without affecting the saved note.
    }
  }
}

class DailyNotePlacement {
  final DailyNote note;
  final int column;
  final int columns;

  const DailyNotePlacement(this.note, this.column, this.columns);
}

/// Assign overlapping entries separate columns; touching endpoints can share one.
List<DailyNotePlacement> layoutDailyNotes(List<DailyNote> notes) {
  final sorted = [...notes]
    ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
  final result = <DailyNotePlacement>[];
  final group = <(DailyNote, int)>[];
  final ends = <int>[];
  var groupEnd = -1;
  void flush() {
    for (final (note, column) in group) {
      result.add(DailyNotePlacement(note, column, ends.length));
    }
    group.clear();
    ends.clear();
  }

  for (final note in sorted) {
    if (note.startMinute >= groupEnd) flush();
    var column = ends.indexWhere((end) => end <= note.startMinute);
    if (column == -1) {
      column = ends.length;
      ends.add(note.endMinute);
    } else {
      ends[column] = note.endMinute;
    }
    group.add((note, column));
    groupEnd = group.length == 1 || note.endMinute > groupEnd
        ? note.endMinute
        : groupEnd;
  }
  flush();
  return result;
}
