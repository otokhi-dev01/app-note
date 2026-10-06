import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/features/daily_note/data/daily_note_store.dart';
import 'package:Note/features/folder/data/repositories/local_folder_repository.dart';
import 'package:Note/features/note/data/repositories/local_note_repository.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late LocalFolderRepository folders;
  late LocalNoteRepository notes;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('guest_notes_audit_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    await GetStorage.init();
  });
  setUp(() async {
    await GetStorage().erase();
    folders = LocalFolderRepository();
    notes = LocalNoteRepository(folders);
  });
  tearDownAll(() async {
    await GetStorage().erase();
    await directory.delete(recursive: true);
  });

  test(
    'Guest notes persist content through edit, move, archive and trash',
    () async {
      final first = (await folders.saveFolder(
        id: 0,
        name: 'Work',
        iconName: 'folder',
        colorValue: 'blue',
      )).valueOrNull!;
      final second = (await folders.saveFolder(
        id: 0,
        name: 'Home',
        iconName: 'folder',
        colorValue: 'pink',
      )).valueOrNull!;
      final created = (await notes.saveNote(
        folderId: first,
        title: 'Draft',
        content: const [TextBlock(id: 'text', text: 'First body')],
      )).valueOrNull!;
      await notes.saveNote(
        folderId: second,
        noteId: created.id,
        title: 'Updated',
        content: const [TextBlock(id: 'text', text: 'Edited body')],
      );
      final reopened = (await LocalNoteRepository(
        folders,
      ).getNoteDetail(created.id)).valueOrNull!;
      expect(reopened.title, 'Updated');
      expect(reopened.folderId, second);
      expect((reopened.content.single as TextBlock).text, 'Edited body');
      await notes.saveNote(
        folderId: second,
        noteId: created.id,
        title: 'Updated',
        content: [],
      );
      expect(
        (await notes.getNoteDetail(created.id)).valueOrNull!.content,
        isEmpty,
      );
      expect(
        (await notes.getNotes(folderId: first)).valueOrNull!.notes,
        isEmpty,
      );
      await notes.updateNoteState(created.id, isPinned: true, isArchived: true);
      expect(
        (await notes.getNotes()).valueOrNull!.archive.single.isPinned,
        isTrue,
      );
      await notes.updateNoteState(created.id, isArchived: false);
      await notes.deleteRestoreNote(created.id, true);
      expect((await notes.getNotes()).valueOrNull!.trash.single.id, created.id);
      await notes.deleteRestoreNote(created.id, false);
      expect((await notes.getNotes()).valueOrNull!.notes, hasLength(1));
      await notes.deleteRestoreNote(created.id, true);
      await notes.emptyTrash();
      expect((await notes.getNoteDetail(created.id)).isErr, isTrue);
    },
  );

  test('Deleting a guest note never deletes the picker source file', () async {
    final source = await File(
      '${directory.path}/original.jpg',
    ).writeAsString('original');
    final note = (await notes.saveNote(
      folderId: -1,
      title: 'Photo',
      content: [
        AttachmentBlock(
          id: 'photo',
          displayName: 'original.jpg',
          localPath: source.path,
        ),
      ],
    )).valueOrNull!;
    await notes.deleteNotePermanently(note.id);
    expect(source.existsSync(), isTrue);
  });

  test(
    'Shared guest attachments remain until the last reference is deleted',
    () async {
      final source = await File(
        '${directory.path}/picked.jpg',
      ).writeAsString('image');
      final uploaded = (await notes.uploadAttachment(
        noteId: 1,
        filePath: source.path,
        blockId: 'photo',
        displayOrder: 0,
      )).valueOrNull!;
      final content = [
        AttachmentBlock(
          id: 'photo',
          displayName: 'photo.jpg',
          localPath: uploaded.filePath,
        ),
      ];
      final first = (await notes.saveNote(
        folderId: -1,
        title: 'First',
        content: content,
      )).valueOrNull!;
      final second = (await notes.saveNote(
        folderId: -1,
        title: 'Second',
        content: content,
      )).valueOrNull!;
      await notes.deleteNotePermanently(first.id);
      expect(File(uploaded.filePath).existsSync(), isTrue);
      await notes.deleteNotePermanently(second.id);
      expect(File(uploaded.filePath).existsSync(), isFalse);
      expect(source.existsSync(), isTrue);
    },
  );

  test(
    'Emptying trash removes shared files but retains live attachments',
    () async {
      final source = await File(
        '${directory.path}/bulk.jpg',
      ).writeAsString('image');
      final upload = (await notes.uploadAttachment(
        noteId: 1,
        filePath: source.path,
        blockId: 'photo',
        displayOrder: 0,
      )).valueOrNull!;
      final content = [
        AttachmentBlock(
          id: 'photo',
          displayName: 'bulk.jpg',
          localPath: upload.filePath,
        ),
      ];
      final first = (await notes.saveNote(
        folderId: -1,
        title: 'First',
        content: content,
      )).valueOrNull!;
      final second = (await notes.saveNote(
        folderId: -1,
        title: 'Second',
        content: content,
      )).valueOrNull!;
      final live = (await notes.saveNote(
        folderId: -1,
        title: 'Live',
        content: content,
      )).valueOrNull!;
      await notes.deleteRestoreNote(first.id, true);
      await notes.deleteRestoreNote(second.id, true);
      await notes.emptyTrash();
      expect(File(upload.filePath).existsSync(), isTrue);
      // A second copy shares the last live attachment. Both now enter trash.
      final copy = (await notes.saveNote(
        folderId: -1,
        title: 'Copy',
        content: content,
      )).valueOrNull!;
      await notes.deleteRestoreNote(live.id, true);
      await notes.deleteRestoreNote(copy.id, true);
      await notes.emptyTrash();
      expect(File(upload.filePath).existsSync(), isFalse);
      expect(source.existsSync(), isTrue);
    },
  );

  test('Daily notes validate times and keep account data separate', () async {
    final first = DailyNoteStore(
      storage: GetStorage(),
      owner: 'A',
      documentsDirectory: () async => directory,
    );
    final second = DailyNoteStore(
      storage: GetStorage(),
      owner: 'B',
      documentsDirectory: () async => directory,
    );
    final entry = DailyNote(
      id: 'one',
      date: DateTime(2026, 10, 4),
      title: 'Meeting',
      startMinute: 540,
      endMinute: 600,
      color: 0xFFFF0000,
    );
    await first.save(entry);
    expect(first.read().single.title, 'Meeting');
    expect(second.read(), isEmpty);
    await expectLater(
      first.save(
        DailyNote(
          id: 'bad',
          date: entry.date,
          title: 'Bad',
          startMinute: 600,
          endMinute: 540,
          color: 0,
        ),
      ),
      throwsArgumentError,
    );
    await first.delete(entry.id);
    expect(first.read(), isEmpty);
  });
}
