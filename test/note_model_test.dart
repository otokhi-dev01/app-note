import 'package:flutter_test/flutter_test.dart';
import 'package:notes/data/models/note_model.dart';

void main() {
  final timestamp = DateTime.utc(2026, 1, 1);

  test('copyWith keeps nullable fields when they are omitted', () {
    final note = NoteModel(
      title: 'Title',
      content: 'Content',
      createdAt: timestamp,
      updatedAt: timestamp,
      deletedAt: timestamp,
      folderId: 7,
    );

    final copy = note.copyWith(title: 'Updated');

    expect(copy.folderId, 7);
    expect(copy.deletedAt, timestamp);
  });

  test('copyWith can explicitly clear folder and deletion date', () {
    final note = NoteModel(
      title: 'Title',
      content: 'Content',
      createdAt: timestamp,
      updatedAt: timestamp,
      deletedAt: timestamp,
      folderId: 7,
    );

    final copy = note.copyWith(folderId: null, deletedAt: null);

    expect(copy.folderId, isNull);
    expect(copy.deletedAt, isNull);
  });
}
