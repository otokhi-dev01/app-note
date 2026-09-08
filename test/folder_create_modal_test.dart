import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:Note/core/localization/app_translations.dart';
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
  setUpAll(() async {
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  });
  tearDown(() => Get.reset());

  Future<void> openForm(
    WidgetTester tester,
    _FolderController controller, {
    required VoidCallback onDone,
    bool closeAfterSave = false,
  }) async {
    await tester.pumpWidget(
      LiquidGlassWidgets.wrap(
        brightnessResolver: Theme.maybeBrightnessOf,
        child: GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: FolderCreateModal(
            controller: controller,
            parentId: 7,
            onDone: onDone,
            closeAfterSave: closeAfterSave,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Projects');
  }

  testWidgets('check saves once then clears the form and keeps it open', (
    tester,
  ) async {
    final controller = _FolderController();
    var doneCount = 0;
    await openForm(tester, controller, onDone: () => doneCount++);
    final field = tester.widget<EditableText>(find.byType(EditableText));

    await tester.tap(find.byIcon(CupertinoIcons.checkmark).first);
    await tester.pump();
    expect(controller.savedName, 'Projects');
    expect(controller.savedParentId, 7);
    expect(field.controller.text, 'Projects');
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(controller.saveCount, 1);

    controller.result.complete(42);
    await tester.pumpAndSettle();
    expect(find.byType(FolderCreateModal), findsOneWidget);
    expect(field.controller.text, isEmpty);
    expect(doneCount, 0);
    expect(find.text('New Folder'), findsNWidgets(2));

    await tester.enterText(find.byType(EditableText), 'Child');
    await tester.pump();
    await tester.tap(find.byIcon(CupertinoIcons.checkmark).first);
    await tester.pumpAndSettle();
    expect(controller.savedParentId, 42);
    expect(controller.saveCount, 2);
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
      onDone: () => doneCount++,
      closeAfterSave: true,
    );
    await tester.tap(find.byIcon(CupertinoIcons.checkmark).first);
    controller.result.complete(42);
    await tester.pumpAndSettle();
    expect(doneCount, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
