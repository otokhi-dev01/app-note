import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_create_modal.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';

class _UnusedRepository implements FolderRepository, NoteRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Folder _folder(int id, String name, {int? parentId}) => Folder(
  id: id,
  parentId: parentId,
  name: name,
  iconName: 'folder',
  colorValue: '#FF69B4',
  sortOrder: 0,
);

class _FolderController extends FolderController {
  _FolderController()
    : super(
        getFolders: GetFolders(_UnusedRepository()),
        saveFolder: SaveFolder(_UnusedRepository()),
        deleteRestoreFolder: DeleteRestoreFolder(_UnusedRepository()),
        buildHierarchy: const BuildFolderHierarchy(),
        getNotes: GetNotes(_UnusedRepository()),
        createAudioNote: CreateAudioNote(_UnusedRepository()),
      );

  final result = Completer<int?>();
  int saveCount = 0;
  String? savedName;
  int? savedParentId;

  @override
  Future<int?> onSaveFolder({
    required int id,
    int? parentId,
    required String name,
    String? iconName,
    String? colorValue,
    int? sortOrder,
  }) {
    saveCount++;
    savedName = name;
    savedParentId = parentId;
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    await GetStorage.init();
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  });
  tearDown(() => Get.reset());

  Future<void> openForm(
    WidgetTester tester,
    _FolderController controller, {
    VoidCallback? onDone,
    int? parentId = 7,
    String sectionKeyword = '',
    String? draftName = 'Projects',
  }) async {
    await tester.pumpWidget(
      LiquidGlassWidgets.wrap(
        brightnessResolver: Theme.maybeBrightnessOf,
        child: GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(body: Text('Folder list')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      Get.to<void>(
        () => FolderCreateModal(
          controller: controller,
          parentId: parentId,
          sectionKeyword: sectionKeyword,
          onDone: onDone,
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (draftName != null) {
      await tester.enterText(find.byType(EditableText), draftName);
    }
  }

  test('folder numbering is independent by section and parent', () {
    final controller = _FolderController();
    controller.folders.assignAll([
      _folder(1, 'iCloud New Folder 2'),
      _folder(2, 'New Folder 5', parentId: 0),
      _folder(3, 'Shared New Folder 20'),
      _folder(4, 'New Folder 30', parentId: 1),
    ]);
    expect(
      controller.nextNewFolderName(sectionKeyword: 'iCloud'),
      'New Folder 3',
    );
    expect(controller.nextNewFolderName(), 'New Folder 6');
    expect(controller.nextNewFolderName(parentId: 1), 'New Folder 31');
    expect(controller.nextNewFolderName(parentId: 2), 'New Folder 1');

    controller.trashFolders.assignAll([
      _folder(5, 'iCloud New Folder 8'),
      _folder(6, 'New Folder 12'),
    ]);
    expect(
      controller.nextNewFolderName(sectionKeyword: 'iCloud'),
      'New Folder 3',
    );
    expect(controller.nextNewFolderName(), 'New Folder 6');
  });

  test(
    'empty sections restart at one while deleted folders remain in trash',
    () {
      final controller = _FolderController();
      final cloudFolder = _folder(1, 'iCloud New Folder 4');
      final phoneFolder = _folder(2, 'New Folder 7');
      controller.folders.assignAll([cloudFolder, phoneFolder]);

      controller.folders.remove(cloudFolder);
      controller.trashFolders.add(cloudFolder);
      expect(
        controller.nextNewFolderName(sectionKeyword: 'iCloud'),
        'New Folder 1',
      );
      expect(controller.nextNewFolderName(), 'New Folder 8');

      controller.folders.add(_folder(3, 'iCloud New Folder 1'));
      expect(
        controller.nextNewFolderName(sectionKeyword: 'iCloud'),
        'New Folder 2',
      );

      controller.folders.remove(phoneFolder);
      controller.trashFolders.add(phoneFolder);
      expect(controller.nextNewFolderName(), 'New Folder 1');
      expect(
        controller.nextNewFolderName(sectionKeyword: 'iCloud'),
        'New Folder 2',
      );

      controller.folders.add(_folder(4, 'New Folder 1'));
      expect(controller.nextNewFolderName(), 'New Folder 2');
    },
  );

  for (final section in ['', 'iCloud']) {
    testWidgets('new folder form uses the numbering for section "$section"', (
      tester,
    ) async {
      final controller = _FolderController();
      controller.folders.assignAll([
        _folder(1, 'iCloud New Folder 2'),
        _folder(2, 'New Folder 5'),
      ]);
      await openForm(
        tester,
        controller,
        parentId: null,
        sectionKeyword: section,
        draftName: null,
      );
      final expectedName = section.isEmpty ? 'New Folder 6' : 'New Folder 3';
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        expectedName,
      );
      await tester.tap(find.byIcon(CupertinoIcons.checkmark).first);
      expect(
        controller.savedName,
        section.isEmpty ? expectedName : '$section $expectedName',
      );
      controller.result.complete(42);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('check saves once then dismisses the form and keyboard', (
    tester,
  ) async {
    final controller = _FolderController();
    await openForm(tester, controller);
    final field = tester.widget<EditableText>(find.byType(EditableText));

    await tester.tap(find.byIcon(CupertinoIcons.checkmark).first);
    await tester.pump();
    expect(controller.savedName, 'Projects');
    expect(controller.savedParentId, 7);
    expect(field.controller.text, 'Projects');
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(controller.saveCount, 1);

    // A save success snackbar must not consume the page dismissal.
    Get.snackbar('Success', 'Folder created successfully');
    await tester.pump();
    controller.result.complete(42);
    await tester.pumpAndSettle();
    expect(find.byType(FolderCreateModal), findsNothing);
    expect(find.text('Folder list'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(controller.saveCount, 1);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed save preserves the entered name', (tester) async {
    final controller = _FolderController();
    var doneCount = 0;
    await openForm(tester, controller, onDone: () => doneCount++);
    await tester.tap(find.byIcon(CupertinoIcons.checkmark).first);
    controller.result.complete(null);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Projects',
    );
    expect(doneCount, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('folder picker creation still completes its caller flow', (
    tester,
  ) async {
    final controller = _FolderController();
    var doneCount = 0;
    await openForm(
      tester,
      controller,
      onDone: () {
        doneCount++;
        Get.key.currentState!.pop();
      },
    );
    await tester.tap(find.byIcon(CupertinoIcons.checkmark).first);
    controller.result.complete(42);
    await tester.pumpAndSettle();
    expect(doneCount, 1);
    expect(find.byType(FolderCreateModal), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
