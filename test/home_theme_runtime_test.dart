import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:notes/app/theme/app_theme.dart';
import 'package:notes/data/services/auth_service.dart';
import 'package:notes/data/services/local_storage.dart';
import 'package:notes/domain/entities/folder.dart';
import 'package:notes/domain/entities/note.dart';
import 'package:notes/domain/repositories/note_repository.dart';
import 'package:notes/domain/usecases/delete_note_usecase.dart';
import 'package:notes/domain/usecases/get_notes_usecase.dart';
import 'package:notes/domain/usecases/update_note_usecase.dart';
import 'package:notes/presentation/modules/home/home_controller.dart';
import 'package:notes/presentation/modules/home/home_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    final repository = _FakeNoteRepository();
    Get.put<NoteRepository>(repository);
    final auth = AuthService(LocalStorage());
    Get.put<AuthService>(auth);
    await auth.ready;
    Get.put(
      HomeController(
        GetNotesUseCase(repository),
        UpdateNoteUseCase(repository),
        DeleteNoteUseCase(repository),
      ),
    );
  });

  tearDown(Get.reset);

  testWidgets('folder ListTiles paint correctly in light and dark themes', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const HomeView(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('All Notes'), findsOneWidget);
    expect(tester.takeException(), isNull);

    Get.changeThemeMode(ThemeMode.dark);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      Theme.of(tester.element(find.byType(HomeView))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('routed application views remain stateless', (tester) async {
    expect(const HomeView(), isA<StatelessWidget>());
  });
}

class _FakeNoteRepository implements NoteRepository {
  final _notes = <Note>[
    Note(
      id: 1,
      title: 'Design system',
      content: 'Review the #work palette',
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 16),
      folderId: 1,
    ),
  ];

  final _folders = <Folder>[
    Folder(id: 1, name: 'Design Projects', createdAt: DateTime(2026, 7, 1)),
  ];

  @override
  Future<int> createFolder(String name) async {
    final id = _folders.length + 1;
    _folders.add(Folder(id: id, name: name, createdAt: DateTime.now()));
    return id;
  }

  @override
  Future<int> createNote(Note note) async {
    _notes.add(note);
    return note.id ?? _notes.length;
  }

  @override
  Future<int> deleteFolder(int id) async {
    _folders.removeWhere((folder) => folder.id == id);
    return 1;
  }

  @override
  Future<int> deleteNote(int id) async {
    _notes.removeWhere((note) => note.id == id);
    return 1;
  }

  @override
  Future<List<Folder>> getFolders() async => List.of(_folders);

  @override
  Future<Note?> getNoteById(int id) async {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  @override
  Future<List<Note>> getNotes({bool includeDeleted = false}) async => _notes
      .where((note) => includeDeleted || !note.isDeleted)
      .toList(growable: false);

  @override
  Future<List<Note>> getRecentlyDeleted() async =>
      _notes.where((note) => note.isDeleted).toList(growable: false);

  @override
  Future<int> renameFolder(int id, String newName) async => 1;

  @override
  Future<int> restoreFolder(int id) async => 1;

  @override
  Future<int> updateNote(Note note) async {
    final index = _notes.indexWhere((item) => item.id == note.id);
    if (index >= 0) _notes[index] = note;
    return index >= 0 ? 1 : 0;
  }
}
