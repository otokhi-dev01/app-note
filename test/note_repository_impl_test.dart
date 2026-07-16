import 'package:flutter_test/flutter_test.dart';
import 'package:notes/core/database/database_service.dart';
import 'package:notes/data/models/note_model.dart';
import 'package:notes/data/repositories/note_repository_impl.dart';
import 'package:notes/data/services/auth_service.dart';
import 'package:notes/data/services/folder_api_service.dart';
import 'package:notes/data/services/local_storage.dart';
import 'package:notes/data/services/note_api_service.dart';
import 'package:notes/data/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryDatabase database;
  late _TestAuthService auth;
  late _FakeNoteApiService noteApi;
  late NoteRepositoryImpl repository;

  setUp(() async {
    database = _MemoryDatabase();
    auth = _TestAuthService();
    await auth.ready;
    noteApi = _FakeNoteApiService(auth);
    repository = NoteRepositoryImpl(
      database,
      auth,
      FolderApiService(auth, tokenProvider: () => 'test-token'),
      noteApi,
    );
  });

  test('remote note list is cached and then read from the cache', () async {
    final remote = _note(id: 11, title: 'Remote', content: 'Server copy');
    noteApi.notes = [remote];

    final result = await repository.getNotes();

    expect(noteApi.listRequests, [false]);
    expect(database.cacheCalls, hasLength(1));
    expect(database.cacheCalls.single.ownerId, 'user:repository-test');
    expect(database.cacheCalls.single.replaceRemote, isTrue);
    expect(database.cacheCalls.single.includeDeleted, isFalse);
    expect(database.getNotesCalls, 1);
    expect(result, hasLength(1));
    expect(result.single.id, 11);
    expect(result.single.title, 'Remote');
  });

  test('create delegates to save-content and caches the server note', () async {
    final draft = _note(title: 'Draft', content: 'Local content');
    final saved = _note(id: 42, title: 'Draft', content: 'Canonical content');
    noteApi.savedResult = saved;

    final id = await repository.createNote(draft);

    expect(id, 42);
    expect(noteApi.savedNotes, hasLength(1));
    expect(noteApi.savedNotes.single.id, isNull);
    expect(noteApi.savedNotes.single.content, 'Local content');
    expect(database.notes[42]?.content, 'Canonical content');
  });

  test(
    'content updates use save-content but do not emit state changes',
    () async {
      final previous = _note(id: 7, title: 'Before', content: 'Old body');
      database.seed(previous);
      final changed = previous.copyWith(
        title: 'After',
        content: 'New body',
        updatedAt: DateTime.utc(2026, 7, 16, 12),
      );
      noteApi.savedResult = changed;

      final count = await repository.updateNote(changed);

      expect(count, 1);
      expect(noteApi.savedNotes, hasLength(1));
      expect(noteApi.stateChanges, isEmpty);
      expect(database.notes[7]?.title, 'After');
      expect(database.notes[7]?.content, 'New body');
    },
  );

  test('state-only updates skip save-content and use update-state', () async {
    final previous = _note(id: 8, title: 'Pinned', content: 'Same body');
    database.seed(previous);
    final changed = previous.copyWith(
      isPinned: true,
      updatedAt: DateTime.utc(2026, 7, 16, 12),
    );

    final count = await repository.updateNote(changed);

    expect(count, 1);
    expect(noteApi.savedNotes, isEmpty);
    expect(noteApi.stateChanges, hasLength(1));
    expect(noteApi.stateChanges.single.state, 'pinned');
    expect(noteApi.stateChanges.single.value, isTrue);
    expect(database.notes[8]?.isPinned, isTrue);
  });

  test('API write errors propagate without committing a local write', () async {
    noteApi.saveError = const NoteApiException('save failed');

    await expectLater(
      repository.createNote(_note(title: 'Draft', content: 'Body')),
      throwsA(
        isA<NoteApiException>().having(
          (error) => error.message,
          'message',
          'save failed',
        ),
      ),
    );

    expect(database.notes, isEmpty);
    expect(database.cacheCalls, isEmpty);

    final previous = _note(id: 9, title: 'State', content: 'Body');
    database.seed(previous);
    noteApi
      ..saveError = null
      ..stateError = const NoteApiException('state failed');

    await expectLater(
      repository.updateNote(previous.copyWith(isLocked: true)),
      throwsA(
        isA<NoteApiException>().having(
          (error) => error.message,
          'message',
          'state failed',
        ),
      ),
    );

    expect(database.notes[9]?.isLocked, isFalse);
    expect(database.updateCalls, 0);
  });

  test('positive note IDs cannot be permanently deleted', () async {
    database.seed(_note(id: 10, title: 'Trash', content: 'Keep cached'));

    await expectLater(
      repository.deleteNote(10),
      throwsA(isA<UnsupportedError>()),
    );

    expect(database.deleteCalls, 0);
    expect(database.notes, contains(10));
  });
}

NoteModel _note({int? id, required String title, required String content}) {
  return NoteModel(
    id: id,
    title: title,
    content: content,
    createdAt: DateTime.utc(2026, 7, 16, 8),
    updatedAt: DateTime.utc(2026, 7, 16, 9),
  );
}

class _CacheCall {
  const _CacheCall({
    required this.ownerId,
    required this.replaceRemote,
    required this.includeDeleted,
  });

  final String ownerId;
  final bool replaceRemote;
  final bool includeDeleted;
}

class _MemoryDatabase extends DatabaseService {
  final Map<int, NoteModel> notes = {};
  final List<_CacheCall> cacheCalls = [];
  int getNotesCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  void seed(NoteModel note) {
    notes[note.id!] = note;
  }

  @override
  Future<List<Map<String, Object?>>> getNotes({
    required String ownerId,
    bool includeDeleted = false,
  }) async {
    getNotesCalls++;
    return notes.values
        .where((note) => includeDeleted || !note.isDeleted)
        .map((note) => note.toMap())
        .toList(growable: false);
  }

  @override
  Future<List<Map<String, Object?>>> getRecentlyDeleted({
    required String ownerId,
  }) async {
    return notes.values
        .where((note) => note.isDeleted)
        .map((note) => note.toMap())
        .toList(growable: false);
  }

  @override
  Future<Map<String, Object?>?> getNoteById(
    int id, {
    required String ownerId,
    bool includeDeleted = false,
  }) async {
    final note = notes[id];
    if (note == null || (!includeDeleted && note.isDeleted)) return null;
    return note.toMap();
  }

  @override
  Future<void> cacheRemoteNotes(
    List<NoteModel> remoteNotes, {
    required String ownerId,
    bool replaceRemote = false,
    bool includeDeleted = false,
  }) async {
    cacheCalls.add(
      _CacheCall(
        ownerId: ownerId,
        replaceRemote: replaceRemote,
        includeDeleted: includeDeleted,
      ),
    );
    if (replaceRemote) {
      final ids = remoteNotes.map((note) => note.id).whereType<int>().toSet();
      notes.removeWhere(
        (id, note) =>
            id > 0 && (includeDeleted || !note.isDeleted) && !ids.contains(id),
      );
    }
    for (final note in remoteNotes) {
      if (note.id != null && note.id! > 0) notes[note.id!] = note;
    }
  }

  @override
  Future<int> updateNote(NoteModel note, {required String ownerId}) async {
    updateCalls++;
    if (!notes.containsKey(note.id)) return 0;
    notes[note.id!] = note;
    return 1;
  }

  @override
  Future<int> deleteNote(int id, {required String ownerId}) async {
    deleteCalls++;
    return notes.remove(id) == null ? 0 : 1;
  }
}

class _StateChange {
  const _StateChange(this.note, this.state, this.value);

  final NoteModel note;
  final String state;
  final Object? value;
}

class _FakeNoteApiService extends NoteApiService {
  _FakeNoteApiService(super.auth) : super(tokenProvider: () => 'test-token');

  List<NoteModel> notes = [];
  NoteModel? savedResult;
  NoteApiException? saveError;
  NoteApiException? stateError;
  final List<bool> listRequests = [];
  final List<NoteModel> savedNotes = [];
  final List<_StateChange> stateChanges = [];

  @override
  Future<List<NoteModel>> getNotes({bool includeDeleted = false}) async {
    listRequests.add(includeDeleted);
    return notes;
  }

  @override
  Future<NoteModel?> getNote(int id) async {
    return notes.where((note) => note.id == id).firstOrNull;
  }

  @override
  Future<NoteModel> saveContent(NoteModel note) async {
    savedNotes.add(note);
    final error = saveError;
    if (error != null) throw error;
    return savedResult ?? note.copyWith(id: 100);
  }

  @override
  Future<NoteModel?> updateState(
    NoteModel note, {
    required String state,
    required Object? value,
  }) async {
    stateChanges.add(_StateChange(note, state, value));
    final error = stateError;
    if (error != null) throw error;
    return note;
  }
}

class _TestAuthService extends AuthService {
  _TestAuthService() : super(_NoopLocalStorage());

  @override
  String? get accountScopeId => 'user:repository-test';
}

class _NoopLocalStorage extends LocalStorage {
  @override
  Future<UserModel?> getAuthUser() async => null;

  @override
  Future<void> clearAuthUser() async {}
}
