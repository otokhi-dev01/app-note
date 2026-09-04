import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pdfx/pdfx.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/utils/image_pdf.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/views/create_note_view.dart';
import 'package:Note/features/note/presentation/widgets/note_attachment_block.dart';
import 'package:Note/features/note/presentation/widgets/pdf_pages_editor_page.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

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

  test('document scanning enables the in-camera gallery control', () async {
    const scannerChannel = MethodChannel('cunning_document_scanner');
    MethodCall? scannerCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(scannerChannel, (call) async {
          scannerCall = call;
          return null;
        });

    try {
      await _createController().scanDocuments();

      expect(scannerCall?.method, 'getPictures');
      final arguments = scannerCall?.arguments as Map<Object?, Object?>;
      expect(arguments['scannerSource'], 'camera_and_gallery');
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(scannerChannel, null);
    }
  });

  test(
    'only one native document scanner can open across note controllers',
    () async {
      const scannerChannel = MethodChannel('cunning_document_scanner');
      final scannerResult = Completer<List<String>?>();
      var scannerCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(scannerChannel, (_) {
            scannerCalls += 1;
            return scannerResult.future;
          });

      try {
        final firstController = _createController(tag: 'first-scan');
        final secondController = _createController(tag: 'second-scan');

        final firstScan = firstController.scanDocuments();
        await Future<void>.delayed(Duration.zero);
        await secondController.scanDocuments();

        expect(scannerCalls, 1);

        scannerResult.complete(null);
        await firstScan;
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(scannerChannel, null);
      }
    },
  );

  testWidgets('tapping the create-note body reopens a hidden keyboard', (
    tester,
  ) async {
    final controller = _createController();
    controller.currentNote.value = const Note(
      id: 0,
      folderId: 0,
      title: '',
      folderName: '',
      content: [],
    );
    controller.isLoading.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const CreateNoteView(),
      ),
    );
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
    tester.testTextInput.hide();
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tapAt(const Offset(200, 500));
    await tester.pump();
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('PDF preview Edit button opens the all-page editor', (
    tester,
  ) async {
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
      return path;
    });
    final block = AttachmentBlock(
      id: blockId,
      displayName: 'Editable PDF.pdf',
      localPath: pdfPath,
    );
    controller.blocks.assignAll([block]);

    await _pumpAttachment(tester, controller, block);
    final pdfTile = find.byKey(ValueKey('scanned-pdf-$blockId'));
    await tester.tap(pdfTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('pdf-preview-page')), findsOneWidget);
    final previewScaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('pdf-preview-page')),
    );
    expect(
      previewScaffold.backgroundColor,
      Theme.of(tester.element(pdfTile)).scaffoldBackgroundColor,
    );
    expect(find.byKey(const ValueKey('pdf-preview-app-bar')), findsOneWidget);
    expect(find.byType(CustomGlassAppBar), findsOneWidget);
    expect(find.byKey(const ValueKey('pdf-preview-edit')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pdf-preview-app-bar')),
        matching: find.text('PDF'),
      ),
      findsOneWidget,
    );
    final pdfView = tester.widget<PdfViewPinch>(find.byType(PdfViewPinch));
    expect(pdfView.scrollDirection, Axis.horizontal);
    expect(pdfView.backgroundDecoration.color, Colors.white);
    expect(pdfView.backgroundDecoration.border, isNull);

    // Let the unregistered pdfx test channel report its loading error while
    // the viewer is still mounted; this avoids a package-level dispose race.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('pdf-preview-edit')));
    // PdfViewPinch keeps scheduling frames while its document initializes, so
    // use a bounded route-transition pump instead of pumpAndSettle here.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('pdf-preview-page')), findsNothing);
    expect(find.byKey(const ValueKey('pdf-pages-editor-page')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() => deletePdfFiles(blockId));
  });

  testWidgets('tapping a video opens the PDF-style preview page', (
    tester,
  ) async {
    final controller = _createController();
    final token = DateTime.now().microsecondsSinceEpoch;
    final videoPath = '${Directory.systemTemp.path}/preview-$token.mp4';
    await tester.runAsync(
      () => File(videoPath).writeAsBytes(const [0, 0, 0, 0], flush: true),
    );
    final block = AttachmentBlock(
      id: 'video-preview-$token',
      displayName: 'Holiday.mp4',
      localPath: videoPath,
    );
    controller.blocks.assignAll([block]);

    await _pumpAttachment(tester, controller, block);
    await tester.tap(find.byKey(ValueKey('video-inline-preview-${block.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('video-preview-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('video-preview-app-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('video-preview-close')), findsOneWidget);
    expect(find.byKey(const ValueKey('video-preview-share')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('video-preview-app-bar')),
        matching: find.text('Video'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      final file = File(videoPath);
      if (file.existsSync()) await file.delete();
    });
  });

  testWidgets('PDF page editor lists all nine pages in order', (tester) async {
    final token = DateTime.now().microsecondsSinceEpoch;
    final fixture = File(
      '${Directory.current.path}/assets/icons/piisiit_logo_app.png',
    );
    final pages = (await tester.runAsync<List<String>>(() async {
      final paths = <String>[];
      for (var index = 1; index <= 9; index++) {
        final path =
            '${Directory.systemTemp.path}/pdf_editor_${token}_$index.png';
        await fixture.copy(path);
        paths.add(path);
      }
      return paths;
    }))!;
    PdfPaperSize? savedPaperSize;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: PdfPagesEditorPage(
          pdfPath: 'nine-pages.pdf',
          pageRenderer: (_) async => pages,
          onSave: (_, paperSize) async {
            savedPaperSize = paperSize;
            return true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('pdf-pages-editor-grid')),
    );
    expect(grid.childrenDelegate.estimatedChildCount, 9);
    expect(find.byKey(const ValueKey('pdf-edit-page-1')), findsOneWidget);
    expect(find.text('Edit PDF'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.pencil), findsNothing);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('pdf-paper-size-label')))
          .data,
      'A4',
    );

    await tester.tap(find.byKey(const ValueKey('pdf-paper-size-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Legal').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('pdf-paper-size-label')))
          .data,
      'Legal',
    );
    await tester.tap(find.byKey(const ValueKey('pdf-pages-editor-done')));
    await tester.pumpAndSettle();
    expect(savedPaperSize, PdfPaperSize.legal);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      for (final path in pages) {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      }
    });
  });

  test('multi-page PDF editing prefers original scan pages', () async {
    final token = DateTime.now().microsecondsSinceEpoch.toString();
    final blockId = 'source-pages-$token';
    final fixture = File(
      '${Directory.current.path}/assets/icons/piisiit_logo_app.png',
    );
    final inputs = <String>[];
    for (var page = 1; page <= 3; page++) {
      final path = '${Directory.systemTemp.path}/${blockId}_input_$page.png';
      fixture.copySync(path);
      inputs.add(path);
    }

    await storePdfSourcePages(imagePaths: inputs, blockId: blockId);
    final stored = await findPdfSourcePages(blockId);
    final staged = await preparePdfPagesForEditing(
      pdfPath: '${Directory.systemTemp.path}/does-not-need-to-exist.pdf',
      blockId: blockId,
    );

    expect(stored, hasLength(3));
    expect(staged, hasLength(3));
    expect(staged, isNot(equals(stored)));
    for (var index = 0; index < inputs.length; index++) {
      expect(File(staged[index]).readAsBytesSync(), fixture.readAsBytesSync());
    }

    for (final path in [...inputs, ...staged]) {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    }
    await deletePdfFiles(blockId);
  });

  test('full-size PDF pages support date, time, and page numbers', () async {
    final blockId =
        'footer-${DateTime.now().microsecondsSinceEpoch.toString()}';
    final fixture =
        '${Directory.current.path}/assets/icons/piisiit_logo_app.png';
    final path = await buildMultiPageImagePdf(
      imagePaths: [fixture, fixture],
      blockId: blockId,
      createdAt: DateTime(2026, 9, 1, 13, 37),
      showDateTime: true,
      showPageNumbers: true,
      imagesAreCompletePages: true,
      paperSize: PdfPaperSize.legal,
    );

    expect(File(path).existsSync(), isTrue);
    expect(File(path).lengthSync(), greaterThan(0));
    await deletePdfFiles(blockId);
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

  for (final media in [
    (
      name: 'video',
      prefix: 'video',
      block: const AttachmentBlock(
        id: 'video-border',
        displayName: 'video.mp4',
      ),
    ),
    (
      name: 'PDF',
      prefix: 'pdf',
      block: const AttachmentBlock(
        id: 'pdf-border',
        displayName: 'document.pdf',
      ),
    ),
  ]) {
    testWidgets('${media.name} left and right borders show cursor focus', (
      tester,
    ) async {
      final controller = _createController();
      controller.blocks.assignAll([media.block]);
      await _pumpAttachment(tester, controller, media.block);

      await tester.tap(find.byKey(ValueKey('${media.prefix}-focus-before')));
      await tester.pump();
      expect(
        find.byKey(ValueKey('${media.prefix}-border-cursor-before')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ValueKey('${media.prefix}-focus-after')));
      await tester.pump();
      expect(
        find.byKey(ValueKey('${media.prefix}-border-cursor-after')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('${media.prefix}-border-cursor-before')),
        findsNothing,
      );
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

NoteDetailController _createController({String? tag}) {
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
    tag: tag,
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
