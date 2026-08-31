import 'package:flutter_test/flutter_test.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/entities/note_bundle.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';

class _FakeNoteRepository implements NoteRepository {
  final calls = <String>[];
  List<NoteBlock> savedContent = const [];

  @override
  Future<Result<int>> saveNoteMetadata({
    required int folderId,
    required String title,
    int noteId = 0,
  }) async {
    calls.add('metadata');
    return const Ok(7);
  }

  @override
  Future<Result<AttachmentUpload>> uploadAttachment({
    required int noteId,
    required String filePath,
    required String blockId,
    required int displayOrder,
  }) async {
    calls.add('upload');
    return const Ok(
      AttachmentUpload(
        attachmentId: 9,
        filePath: '/documents/voice.m4a',
        blockId: 'audio-1',
        isLocal: true,
      ),
    );
  }

  @override
  Future<Result<void>> saveNoteContent({
    required int noteId,
    required String title,
    required List<NoteBlock> content,
  }) async {
    calls.add('content');
    savedContent = content;
    return okVoid;
  }

  @override
  Future<Result<Note>> getNoteDetail(int id) async {
    calls.add('detail');
    return const Ok(
      Note(id: 7, folderId: 2, folderName: 'Notes', title: 'Recording'),
    );
  }

  @override
  Future<Result<NoteBundle>> getNotes({int? folderId}) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'creates metadata, uploads audio, then saves attachment content',
    () async {
      final repository = _FakeNoteRepository();
      final useCase = CreateAudioNote(repository);

      final result = await useCase(
        const CreateAudioNoteParams(
          folderId: 2,
          title: 'Recording',
          filePath: '/tmp/voice.m4a',
          displayName: 'Recording.m4a',
          blockId: 'audio-1',
        ),
      );

      expect(result, isA<Ok<Note>>());
      expect(repository.calls, ['metadata', 'upload', 'content', 'detail']);
      final attachment = repository.savedContent.single as AttachmentBlock;
      expect(attachment.attachmentId, 9);
      expect(attachment.localPath, '/documents/voice.m4a');
      expect(attachment.url, isNull);
    },
  );
}
