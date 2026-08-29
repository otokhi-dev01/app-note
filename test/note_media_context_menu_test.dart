import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
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
