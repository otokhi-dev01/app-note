import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_camera_capture_sheet.dart';
import 'package:Note/features/note/presentation/widgets/note_media_context_menu.dart';
import 'package:Note/features/note/presentation/widgets/note_media_title.dart';
import 'package:Note/shared/widgets/ios_action_menu.dart';

class _CameraController implements NoteDetailController {
  int captures = 0;

  @override
  bool get isClosed => false;

  @override
  Future<void> addAttachment(ImageSource source, {bool isVideo = false}) async {
    captures++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedNoteRepository implements NoteRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedFolderRepository implements FolderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => Get.reset());
  testWidgets('Closing a note cancels queued editor focus callbacks', (
    tester,
  ) async {
    final repository = _UnusedNoteRepository();
    final controller = NoteDetailController(
      getNoteDetail: GetNoteDetail(repository),
      saveNoteMetadata: SaveNoteMetadata(repository),
      saveNoteContent: SaveNoteContent(repository),
      updateNoteState: UpdateNoteState(repository),
      deleteRestoreNote: DeleteRestoreNote(repository),
      uploadAttachment: UploadAttachment(repository),
      downloadAttachment: DownloadAttachment(repository),
      getFolders: GetFolders(_UnusedFolderRepository()),
    );
    controller.focusFirstTextBlock();
    controller.onDelete();
    await tester.pump();
    expect(controller.isClosed, isTrue);
    expect(controller.quillControllers, isEmpty);
    expect(controller.blockFocusNodes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Camera sheet rebuilds after its source widget is removed', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final controller = _CameraController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (context, show, _) => show
                ? Builder(
                    builder: (sourceContext) => TextButton(
                      onPressed: () => unawaited(
                        showCameraCaptureSheet(sourceContext, controller),
                      ),
                      child: const Text('Camera'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
    final route = ModalRoute.of(
      tester.element(find.byType(CupertinoActionSheet)),
    )!;
    visible.value = false;
    await tester.pump();
    route.changedExternalState();
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(CupertinoActionSheetAction).first);
    await tester.pumpAndSettle();
    expect(controller.captures, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Title dialog rebuilds after its attachment is removed', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (context, show, _) => show
                ? NoteMediaTitle(
                    displayName: 'photo.jpg',
                    fallbackTitle: 'Photo',
                    isReadOnly: false,
                    onChanged: (_) => changes++,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('media-title-photo.jpg')));
    await tester.pumpAndSettle();
    final route = ModalRoute.of(
      tester.element(find.byType(CupertinoAlertDialog)),
    )!;
    visible.value = false;
    await tester.pump();
    route.changedExternalState();
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey('media-title-field')),
      'New title',
    );
    await tester.tap(find.byType(CupertinoDialogAction).last);
    await tester.pumpAndSettle();
    expect(changes, 0);
    expect(tester.takeException(), isNull);
  });

  for (final removeSource in [false, true]) {
    testWidgets('Media menu action respects source lifetime ($removeSource)', (
      tester,
    ) async {
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      var actions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (context, show, _) => show
                  ? Builder(
                      builder: (sourceContext) => TextButton(
                        onPressed: () => unawaited(
                          NoteMediaContextMenu.show(
                            context: sourceContext,
                            preview: const SizedBox.shrink(),
                            actions: [
                              NoteMediaMenuAction(
                                title: 'Edit',
                                icon: Icons.edit,
                                onTap: () => actions++,
                              ),
                            ],
                          ),
                        ),
                        child: const Text('Menu'),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      final ink = tester.widget<InkWell>(
        find.ancestor(of: find.text('Edit'), matching: find.byType(InkWell)),
      );
      ink.onTap!();
      if (removeSource) visible.value = false;
      await tester.pumpAndSettle();
      expect(actions, removeSource ? 0 : 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final type in IOSMenuType.values) {
    for (final removeSource in [false, true]) {
      testWidgets('iOS $type action respects source lifetime ($removeSource)', (
        tester,
      ) async {
        Get.testMode = true;
        final visible = ValueNotifier(true);
        addTearDown(visible.dispose);
        var actions = 0;
        await tester.pumpWidget(
          GetMaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: visible,
                builder: (context, show, _) => show
                    ? Builder(
                        builder: (sourceContext) => TextButton(
                          onPressed: () => unawaited(
                            IOSActionMenu.show(
                              context: sourceContext,
                              type: type,
                              actions: [
                                IOSMenuAction(
                                  label: 'Edit',
                                  icon: Icons.edit,
                                  onTap: () => actions++,
                                ),
                              ],
                            ),
                          ),
                          child: const Text('Menu'),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Menu'));
        await tester.pumpAndSettle();
        final ink = tester.widget<InkWell>(
          find.ancestor(of: find.text('Edit'), matching: find.byType(InkWell)),
        );
        ink.onTap!();
        if (removeSource) visible.value = false;
        await tester.pumpAndSettle();
        expect(actions, removeSource ? 0 : 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
