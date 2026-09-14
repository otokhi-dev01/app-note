import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/folder/data/repositories/folder_sync_repository.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';
import 'package:Note/features/note/data/repositories/note_sync_repository.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/entities/note_bundle.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';

/// Minimal in-memory stand-ins for the real backend — see
/// `folder_sync_repository_test.dart` for why a fake beats a Dio mock here:
/// these repositories only care about the [NetworkFailure] shape of a
/// failure, not how it was produced.
class _FakeFolderRepository implements FolderRepository {
  bool online = true;
  int _nextId = 100;
  final Map<int, Folder> byId = {};

  @override
  Future<Result<FolderBundle>> getFolders() async {
    if (!online) return const Err(NetworkFailure());
    final all = byId.values.toList();
    return Ok(
      FolderBundle(
        folders: all.where((f) => !f.isDeleted).toList(),
        trash: all.where((f) => f.isDeleted).toList(),
      ),
    );
  }

  @override
  Future<Result<int>> saveFolder({
    required int id,
    int? parentId,
    required String name,
    required String iconName,
    required String colorValue,
    int sortOrder = 0,
  }) async {
    if (!online) return const Err(NetworkFailure());
    final targetId = id == 0 ? _nextId++ : id;
    byId[targetId] = Folder(
      id: targetId,
      parentId: parentId,
      name: name,
      iconName: iconName,
      colorValue: colorValue,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return Ok(targetId);
  }

  @override
  Future<Result<void>> deleteRestoreFolder(int folderId, bool isDelete) async {
    if (!online) return const Err(NetworkFailure());
    return okVoid;
  }

  @override
  Future<Result<void>> deleteFolderPermanently(int folderId) async {
    return const Err(UnsupportedFeatureFailure('Not supported.'));
  }
}

class _FakeNoteRepository implements NoteRepository {
  bool online = true;
  int _nextId = 500;
  final Map<int, Note> byId = {};
  final List<String> calls = [];

  @override
  Future<Result<NoteBundle>> getNotes({int? folderId}) async {
    calls.add('getNotes');
    if (!online) return const Err(NetworkFailure());
    final all = folderId == null
        ? byId.values.toList()
        : byId.values.where((n) => n.folderId == folderId || n.isArchived || n.isDeleted).toList();
    return Ok(
      NoteBundle(
        notes: all.where((n) => !n.isDeleted && !n.isArchived).toList(),
        archive: all.where((n) => !n.isDeleted && n.isArchived).toList(),
        trash: all.where((n) => n.isDeleted).toList(),
      ),
    );
  }

  @override
  Future<Result<Note>> getNoteDetail(int id) async {
    if (!online) return const Err(NetworkFailure());
    final match = byId[id];
    return match == null ? const Err(ServerFailure('Note not found.')) : Ok(match);
  }

  @override
  Future<Result<Note>> saveNote({
    required int folderId,
    required String title,
    int noteId = 0,
    List<NoteBlock>? content,
  }) async {
    final idResult = await saveNoteMetadata(folderId: folderId, title: title, noteId: noteId);
    if (idResult case Err(:final failure)) return Err(failure);
    return getNoteDetail(idResult.valueOrNull!);
  }

  @override
  Future<Result<int>> saveNoteMetadata({
    required int folderId,
    required String title,
    int noteId = 0,
  }) async {
    calls.add('saveNoteMetadata:$noteId->folder$folderId');
    if (!online) return const Err(NetworkFailure());
    final targetId = noteId == 0 ? _nextId++ : noteId;
    final existing = byId[targetId];
    byId[targetId] = Note(
      id: targetId,
      folderId: folderId,
      folderName: 'F$folderId',
      title: title,
      content: existing?.content ?? const [],
      isPinned: existing?.isPinned ?? false,
      isArchived: existing?.isArchived ?? false,
      isLocked: existing?.isLocked ?? false,
      updatedAt: DateTime.now(),
      deletedAt: existing?.deletedAt,
      attachmentCount: existing?.attachmentCount ?? 0,
    );
    return Ok(targetId);
  }

  @override
  Future<Result<void>> saveNoteContent({
    required int noteId,
    required String title,
    required List<NoteBlock> content,
  }) async {
    calls.add('saveNoteContent:$noteId');
    if (!online) return const Err(NetworkFailure());
    final existing = byId[noteId];
    if (existing == null) return const Err(ServerFailure('Note not found.'));
    byId[noteId] = Note(
      id: existing.id,
      folderId: existing.folderId,
      folderName: existing.folderName,
      title: title,
      content: content,
      isPinned: existing.isPinned,
      isArchived: existing.isArchived,
      isLocked: existing.isLocked,
      updatedAt: DateTime.now(),
      deletedAt: existing.deletedAt,
      attachmentCount: content.whereType<AttachmentBlock>().length,
    );
    return okVoid;
  }

  @override
  Future<Result<void>> updateNoteState(
    int id, {
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  }) async {
    if (!online) return const Err(NetworkFailure());
    final existing = byId[id];
    if (existing == null) return const Err(ServerFailure('Note not found.'));
    byId[id] = Note(
      id: existing.id,
      folderId: existing.folderId,
      folderName: existing.folderName,
      title: existing.title,
      content: existing.content,
      isPinned: isPinned ?? existing.isPinned,
      isArchived: isArchived ?? existing.isArchived,
      isLocked: isLocked ?? existing.isLocked,
      updatedAt: DateTime.now(),
      deletedAt: existing.deletedAt,
      attachmentCount: existing.attachmentCount,
    );
    return okVoid;
  }

  @override
  Future<Result<void>> deleteRestoreNote(int id, bool isDelete) async {
    calls.add('deleteRestoreNote:$id');
    if (!online) return const Err(NetworkFailure());
    final existing = byId[id];
    if (existing == null) return const Err(ServerFailure('Note not found.'));
    byId[id] = Note(
      id: existing.id,
      folderId: existing.folderId,
      folderName: existing.folderName,
      title: existing.title,
      content: existing.content,
      isPinned: existing.isPinned,
      isArchived: existing.isArchived,
      isLocked: existing.isLocked,
      updatedAt: DateTime.now(),
      deletedAt: isDelete ? DateTime.now() : null,
      attachmentCount: existing.attachmentCount,
    );
    return okVoid;
  }

  @override
  Future<Result<void>> deleteNotePermanently(int id) async =>
      const Err(UnsupportedFeatureFailure('Not supported.'));

  @override
  Future<Result<void>> emptyTrash() async =>
      const Err(UnsupportedFeatureFailure('Not supported.'));

  @override
  Future<Result<AttachmentUpload>> uploadAttachment({
    required int noteId,
    required String filePath,
    required String blockId,
    required int displayOrder,
  }) async {
    if (!online) return const Err(NetworkFailure());
    return Ok(
      AttachmentUpload(attachmentId: 1, filePath: 'https://cdn/$blockId', blockId: blockId),
    );
  }

  @override
  Future<Result<String>> downloadAttachment({
    required String url,
    required String savePath,
  }) async {
    if (!online) return const Err(NetworkFailure());
    return Ok(savePath);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeFolderRepository fakeFolders;
  late _FakeNoteRepository fakeNotes;
  late SessionStorage session;
  late FolderSyncRepository folderRepo;
  late NoteSyncRepository noteRepo;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    // See folder_sync_repository_test.dart: isolates this file's default
    // GetStorage container onto its own directory so it doesn't contend for
    // the one file every other test file's default container shares under
    // flutter test's parallel execution.
    GetStorage(
      'GetStorage',
      Directory.systemTemp.createTempSync('note_sync_test_').path,
    );
  });

  setUp(() async {
    await GetStorage.init();
    session = SessionStorage()
      ..user.value = UserData(id: 'user-${DateTime.now().microsecondsSinceEpoch}');
    fakeFolders = _FakeFolderRepository();
    fakeNotes = _FakeNoteRepository();
    folderRepo = FolderSyncRepository(fakeFolders, session);
    noteRepo = NoteSyncRepository(fakeNotes, session, folderRepo);
  });

  test('creating a note offline assigns a temp id and is readable locally', () async {
    fakeFolders.online = false;
    fakeNotes.online = false;

    final folderId = (await folderRepo.saveFolder(
      id: 0,
      name: 'Work',
      iconName: 'folder',
      colorValue: '#000',
    )).valueOrNull!;
    final noteId = (await noteRepo.saveNoteMetadata(
      folderId: folderId,
      title: 'Todo',
    )).valueOrNull!;

    expect(noteId, lessThan(0));
    final detail = await noteRepo.getNoteDetail(noteId);
    expect(detail.valueOrNull!.title, 'Todo');

    final bundle = await noteRepo.getNotes(folderId: folderId);
    expect(bundle.valueOrNull!.notes.single.id, noteId);
  });

  test(
    'a note created offline inside a folder created offline resolves both '
    'ids once the server is reachable again',
    () async {
      fakeFolders.online = false;
      fakeNotes.online = false;

      final tempFolderId = (await folderRepo.saveFolder(
        id: 0,
        name: 'Work',
        iconName: 'folder',
        colorValue: '#000',
      )).valueOrNull!;
      final tempNoteId = (await noteRepo.saveNoteMetadata(
        folderId: tempFolderId,
        title: 'Todo',
      )).valueOrNull!;
      await noteRepo.saveNoteContent(
        noteId: tempNoteId,
        title: 'Todo',
        content: const [TextBlock(id: 'b1', text: 'Buy milk')],
      );

      fakeFolders.online = true;
      fakeNotes.online = true;
      await noteRepo.flushPending();

      expect(folderRepo.pendingCount, 0);
      expect(noteRepo.pendingCount, 0);

      final realFolder = fakeFolders.byId.values.single;
      final realNote = fakeNotes.byId.values.single;
      expect(realNote.folderId, realFolder.id);
      expect(realNote.title, 'Todo');
      expect(
        (realNote.content.single as TextBlock).text,
        'Buy milk',
      );
    },
  );

  test(
    'reading notes while offline falls back to the cache and never hits '
    'the network for a temp note',
    () async {
      final folderId = (await folderRepo.saveFolder(
        id: 0,
        name: 'Work',
        iconName: 'folder',
        colorValue: '#000',
      )).valueOrNull!;

      fakeNotes.online = false;
      final tempId = (await noteRepo.saveNoteMetadata(
        folderId: folderId,
        title: 'Draft',
      )).valueOrNull!;
      fakeNotes.calls.clear();

      final bundle = await noteRepo.getNotes(folderId: folderId);
      expect(bundle.valueOrNull!.notes.map((n) => n.id), contains(tempId));
      expect(
        fakeNotes.calls.any((c) => c.contains('$tempId')),
        isFalse,
        reason: 'a never-synced temp note must not be sent to the server',
      );
    },
  );

  test(
    'pinning a note offline merges into a single queued state change',
    () async {
      final folderId = (await folderRepo.saveFolder(
        id: 0,
        name: 'Work',
        iconName: 'folder',
        colorValue: '#000',
      )).valueOrNull!;
      final noteId = (await noteRepo.saveNoteMetadata(
        folderId: folderId,
        title: 'Note',
      )).valueOrNull!;

      fakeNotes.online = false;
      await noteRepo.updateNoteState(noteId, isPinned: true);
      await noteRepo.updateNoteState(noteId, isArchived: true);
      // Two calls on the same note collapse into one queued op.
      expect(noteRepo.pendingCount, 1);

      fakeNotes.online = true;
      await noteRepo.flushPending();

      final synced = fakeNotes.byId[noteId]!;
      expect(synced.isPinned, isTrue);
      expect(synced.isArchived, isTrue);
    },
  );
}
