import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/utils/image_pdf.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/note/domain/entities/note.dart';
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
    await GetStorage.init();
  });

  tearDown(Get.reset);

  testWidgets('PDF tap is wired to ios_image_editor', (
    tester,
  ) async {
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

    final controller = _createController();
    final token = DateTime.now().microsecondsSinceEpoch.toString();
    final blockId = 'tap-pdf-editor-$token';
    final sourceImage =
        '${Directory.current.path}/assets/icons/piisiit_logo_app.png';
    final pdfPath = await tester.runAsync(() async {
      final path = await buildImagePdf(
        imagePath: sourceImage,
        blockId: blockId,
        title: 'Editable PDF',
      );
      await storePdfSourceImage(imagePath: sourceImage, blockId: blockId);
      return path;
    });
    final sourcePath = await tester.runAsync(() => findPdfSourceImage(blockId));
    final block = AttachmentBlock(
      id: blockId,
      displayName: 'Editable PDF.pdf',
      localPath: pdfPath,
    );
    controller.blocks.assignAll([block]);

    await _pumpAttachment(tester, controller, block);
    final pdfTile = find.byKey(ValueKey('scanned-pdf-$blockId'));
    final tapTarget = find.descendant(
      of: pdfTile,
      matching: find.byType(GestureDetector),
    );
    expect(tester.widget<GestureDetector>(tapTarget.first).onTap, isNotNull);

    await tester.runAsync(() => controller.editPdfSourceImage(0));
    await tester.pump();

    expect(editorCall?.method, 'editImage');
    expect(editorCall?.arguments, {'path': sourcePath});

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() => deletePdfFiles(blockId));
  });

  for (final media in [
    (
      name: 'video',
      block: const AttachmentBlock(id: 'video-menu', displayName: 'video.mp4'),
      key: const ValueKey('video-video-menu'),
    ),
    (
      name: 'voice recording',
      block: const AttachmentBlock(
        id: 'audio-menu',
        displayName: 'recording.m4a',
      ),
      key: const ValueKey('audio-audio-menu'),
    ),
    (
      name: 'PDF',
      block: const AttachmentBlock(id: 'pdf-menu', displayName: 'document.pdf'),
      key: const ValueKey('scanned-pdf-pdf-menu'),
    ),
  ]) {
    testWidgets('long press on ${media.name} shows clipboard actions', (
      tester,
    ) async {
      final controller = _createController();
      controller.blocks.assignAll([media.block]);
      await _pumpAttachment(tester, controller, media.block);

      await tester.longPress(find.byKey(media.key));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('note-media-context-menu')), findsOne);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      if (media.name == 'PDF') {
        expect(find.text('Edit PDF'), findsOneWidget);
      }
    });
  }

  testWidgets('attachment clipboard copies, pastes, and cuts independent files', (
    tester,
  ) async {
    final controller = _createController();
    Get.find<GuestModeService>().enable();
    final fixturePath =
        '${Directory.current.path}/assets/icons/piisiit_logo_app.png';
    final sourcePath =
        '${Directory.systemTemp.path}/note_clipboard_source_${DateTime.now().microsecondsSinceEpoch}.png';
    await tester.runAsync(() => File(fixturePath).copy(sourcePath));
    final source = AttachmentBlock(
      id: 'clipboard-source',
      displayName: 'piisiit_logo_app.png',
      localPath: sourcePath,
    );
    controller.currentNote.value = const Note(
      id: 0,
      folderId: 0,
      title: '',
      folderName: '',
      content: [],
    );
    controller.blocks.assignAll([source]);
    await _pumpAttachment(tester, controller, source);

    await tester.runAsync(() => controller.copyAttachmentBlock(0));
    await tester.pumpAndSettle();
    expect(controller.hasAttachmentClipboard, isTrue);

    await tester.runAsync(() => controller.pasteAttachmentBlock(afterIndex: 0));
    await tester.pumpAndSettle();
    final pasted = controller.blocks.whereType<AttachmentBlock>().toList();
    expect(pasted, hasLength(2));
    expect(pasted.last.localPath, isNot(sourcePath));
    expect(File(pasted.last.localPath!).existsSync(), isTrue);

    await tester.runAsync(() => controller.cutAttachmentBlock(1));
    await tester.pumpAndSettle();
    expect(controller.blocks.whereType<AttachmentBlock>(), hasLength(1));
    expect(controller.hasAttachmentClipboard, isTrue);
  });

  testWidgets('copying an image PDF preserves its editable source', (
    tester,
  ) async {
    final controller = _createController();
    Get.find<GuestModeService>().enable();
    final token = DateTime.now().microsecondsSinceEpoch.toString();
    final sourceId = 'pdf-source-$token';
    final sourceImage =
        '${Directory.current.path}/assets/icons/piisiit_logo_app.png';
    final pdfPath = '${Directory.systemTemp.path}/$sourceId.pdf';
    await tester.runAsync(() async {
      await File(pdfPath).writeAsBytes(const [0x25, 0x50, 0x44, 0x46]);
      await storePdfSourceImage(imagePath: sourceImage, blockId: sourceId);
    });

    final pdf = AttachmentBlock(
      id: sourceId,
      displayName: 'Editable image.pdf',
      localPath: pdfPath,
    );
    controller.currentNote.value = const Note(
      id: 0,
      folderId: 0,
      title: '',
      folderName: '',
      content: [],
    );
    controller.blocks.assignAll([pdf]);
    await _pumpAttachment(tester, controller, pdf);

    await tester.runAsync(() => controller.copyAttachmentBlock(0));
    await tester.pumpAndSettle();
    await tester.runAsync(() => controller.pasteAttachmentBlock(afterIndex: 0));
    await tester.pumpAndSettle();

    final pasted = controller.blocks.whereType<AttachmentBlock>().toList();
    expect(pasted, hasLength(2));
    final pastedSource = await tester.runAsync(
      () => findPdfSourceImage(pasted.last.id),
    );
    expect(pastedSource, isNotNull);
    expect(File(pastedSource!).existsSync(), isTrue);

    await tester.runAsync(() async {
      await deletePdfFiles(sourceId);
      await deletePdfFiles(pasted.last.id);
      if (File(pdfPath).existsSync()) await File(pdfPath).delete();
    });
  });
}

NoteDetailController _createController() {
  InitialBinding().dependencies();
  return Get.put(
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
}

Future<void> _pumpAttachment(
  WidgetTester tester,
  NoteDetailController controller,
  AttachmentBlock block,
) {
  return tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: NoteAttachmentBlock(
              block: block,
              blockIndex: 0,
              controller: controller,
            ),
          ),
        ),
      ),
    ),
  );
}
