import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_attachment_block.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    await GetStorage.init('note-image-context-menu-test');
  });

  tearDown(Get.reset);

  testWidgets('tapping an image previews it before editing', (tester) async {
    const editorChannel = MethodChannel('ios_image_editor');
    MethodCall? editorCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(editorChannel, (call) async {
          editorCall = call;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(editorChannel, null),
    );

    InitialBinding().dependencies();
    final controller = Get.put(
      NoteDetailController(
        getNoteDetail: Get.find<GetNoteDetail>(),
        saveNoteMetadata: Get.find<SaveNoteMetadata>(),
        saveNoteContent: Get.find<SaveNoteContent>(),
        updateNoteState: Get.find<UpdateNoteState>(),
        deleteRestoreNote: Get.find<DeleteRestoreNote>(),
        uploadAttachment: Get.find<UploadAttachment>(),
        downloadAttachment: Get.find<DownloadAttachment>(),
        getFolders: Get.find<GetFolders>(),
      ),
    );
    final imagePath =
        '${Directory.current.path}/assets/icons/piisiit_logo_mark.png';
    final block = AttachmentBlock(
      id: 'tap-to-edit-image',
      displayName: 'piisiit_logo_mark.png',
      localPath: imagePath,
    );
    controller.blocks.assignAll([block]);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: NoteAttachmentBlock(
            block: block,
            blockIndex: 0,
            controller: controller,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(ValueKey('local-${block.id}-$imagePath')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('image-preview-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('image-preview-app-bar')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('image-preview-app-bar')),
        matching: find.text('Image'),
      ),
      findsOneWidget,
    );
    expect(editorCall, isNull);

    await tester.tap(find.byKey(const ValueKey('image-preview-edit')));
    await tester.pumpAndSettle();

    expect(editorCall?.method, 'editImage');
    expect(editorCall?.arguments, {'path': imagePath});
  });

  testWidgets('long press shows image actions and View As choices', (
    tester,
  ) async {
    InitialBinding().dependencies();
    final controller = Get.put(
      NoteDetailController(
        getNoteDetail: Get.find<GetNoteDetail>(),
        saveNoteMetadata: Get.find<SaveNoteMetadata>(),
        saveNoteContent: Get.find<SaveNoteContent>(),
        updateNoteState: Get.find<UpdateNoteState>(),
        deleteRestoreNote: Get.find<DeleteRestoreNote>(),
        uploadAttachment: Get.find<UploadAttachment>(),
        downloadAttachment: Get.find<DownloadAttachment>(),
        getFolders: Get.find<GetFolders>(),
      ),
    );
    final imagePath =
        '${Directory.current.path}/assets/icons/piisiit_logo_mark.png';
    const block = AttachmentBlock(
      id: 'context-menu-image',
      displayName: 'piisiit_logo_mark.png',
    );
    final localBlock = AttachmentBlock(
      id: block.id,
      displayName: block.displayName,
      localPath: imagePath,
    );
    controller.blocks.assignAll([localBlock]);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: NoteAttachmentBlock(
                block: localBlock,
                blockIndex: 0,
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    final image = find.byKey(ValueKey('local-${block.id}-$imagePath'));
    expect(image, findsOneWidget);
    final largeWidth = tester.getSize(image).width;

    await tester.longPress(image);
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Paste'), findsOneWidget);
    expect(find.text('Cut'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('View As'), findsOneWidget);
    expect(find.text('Large'), findsOneWidget);
    expect(find.text('Convert to PDF'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('View As'));
    await tester.pumpAndSettle();
    expect(find.text('Small'), findsOneWidget);
    expect(find.text('Large'), findsOneWidget);

    await tester.tap(find.text('Small'));
    await tester.pumpAndSettle();

    expect(tester.getSize(image).width, lessThan(largeWidth));
  });

  testWidgets('tapping an image edge shows the border cursor', (tester) async {
    InitialBinding().dependencies();
    final controller = Get.put(
      NoteDetailController(
        getNoteDetail: Get.find<GetNoteDetail>(),
        saveNoteMetadata: Get.find<SaveNoteMetadata>(),
        saveNoteContent: Get.find<SaveNoteContent>(),
        updateNoteState: Get.find<UpdateNoteState>(),
        deleteRestoreNote: Get.find<DeleteRestoreNote>(),
        uploadAttachment: Get.find<UploadAttachment>(),
        downloadAttachment: Get.find<DownloadAttachment>(),
        getFolders: Get.find<GetFolders>(),
      ),
    );
    const block = AttachmentBlock(
      id: 'border-cursor-image',
      displayName: 'photo.jpg',
    );
    controller.blocks.assignAll([block]);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: NoteAttachmentBlock(
              block: block,
              blockIndex: 0,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('image-border-cursor-before')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('image-focus-before')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('image-border-cursor-before')),
      findsOneWidget,
    );
    expect(controller.blocks.first, isA<TextBlock>());
  });
}
