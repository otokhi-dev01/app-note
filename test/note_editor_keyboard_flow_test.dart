import 'dart:io';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    await GetStorage.init('note-editor-keyboard-flow-test');
  });
  tearDown(Get.reset);

  test('Return splits a body line and keeps trailing text', () async {
    final controller = _createController();
    const block = TextBlock(id: 'line', text: 'Hello world');
    controller.blocks.assignAll([block]);
    final editor = controller.getQuillController(block.id, block.text);
    editor.updateSelection(
      const TextSelection.collapsed(offset: 5),
      quill.ChangeSource.local,
    );

    editor.replaceText(5, 0, '\n', const TextSelection.collapsed(offset: 6));
    await Future<void>.delayed(Duration.zero);

    expect(controller.blocks, hasLength(2));
    final leading = controller.blocks.first as TextBlock;
    final trailing = controller.blocks.last as TextBlock;
    expect(
      controller
          .getQuillController(leading.id, leading.text)
          .document
          .toPlainText(),
      'Hello\n',
    );
    expect(
      controller
          .getQuillController(trailing.id, trailing.text)
          .document
          .toPlainText(),
      ' world\n',
    );
    expect(controller.activeBlockIndex.value, 1);
  });

  test('Backspace deletes the original empty body line', () async {
    final controller = _createController();
    const block = TextBlock(id: 'original-empty-line', text: '');
    controller.blocks.assignAll([block]);
    final editor = controller.getQuillController(block.id, block.text);
    expect(editor.document.toPlainText(), '$kTextBlockBackspaceMarker\n');

    editor.replaceText(
      0,
      kTextBlockBackspaceMarker.length,
      '',
      const TextSelection.collapsed(offset: 0),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.blocks, isEmpty);
  });

  test('Backspace removes the empty body line created by Return', () async {
    final controller = _createController();
    const block = TextBlock(id: 'line-before-empty', text: 'Hello');
    controller.blocks.assignAll([block]);
    final editor = controller.getQuillController(block.id, block.text);

    editor.replaceText(5, 0, '\n', const TextSelection.collapsed(offset: 6));
    await Future<void>.delayed(Duration.zero);

    final emptyBlock = controller.blocks.last as TextBlock;
    final emptyEditor = controller.getQuillController(
      emptyBlock.id,
      emptyBlock.text,
    );
    expect(emptyEditor.document.toPlainText(), '$kTextBlockBackspaceMarker\n');

    emptyEditor.replaceText(
      0,
      kTextBlockBackspaceMarker.length,
      '',
      const TextSelection.collapsed(offset: 0),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.blocks, hasLength(1));
    expect(controller.blocks.single.id, block.id);
  });

  test('typing on an empty body line removes its keyboard marker', () async {
    final controller = _createController();
    const block = TextBlock(id: 'line-before-typing', text: 'Hello');
    controller.blocks.assignAll([block]);
    final editor = controller.getQuillController(block.id, block.text);

    editor.replaceText(5, 0, '\n', const TextSelection.collapsed(offset: 6));
    await Future<void>.delayed(Duration.zero);
    final nextBlock = controller.blocks.last as TextBlock;
    final nextEditor = controller.getQuillController(
      nextBlock.id,
      nextBlock.text,
    );

    nextEditor.replaceText(1, 0, 'x', const TextSelection.collapsed(offset: 2));

    expect(nextEditor.document.toPlainText(), 'x\n');
    expect(nextEditor.selection, const TextSelection.collapsed(offset: 1));
  });

  test('Space applies the heading shortcut to the active body line', () async {
    final controller = _createController();
    const block = TextBlock(id: 'shortcut', text: '');
    controller.blocks.assignAll([block]);
    final editor = controller.getQuillController(block.id, block.text);

    editor.replaceText(0, 0, '#', const TextSelection.collapsed(offset: 1));
    editor.replaceText(1, 0, ' ', const TextSelection.collapsed(offset: 2));
    await Future<void>.delayed(Duration.zero);

    expect((controller.blocks.single as TextBlock).style, 'heading');
    expect(editor.document.toPlainText(), '\n');
  });

  test(
    'Backspace on the last character returns to the previous line',
    () async {
      final controller = _createController();
      const first = TextBlock(id: 'first', text: 'First');
      const second = TextBlock(id: 'second', text: 'x');
      controller.blocks.assignAll([first, second]);
      controller.getQuillController(first.id, first.text);
      final editor = controller.getQuillController(second.id, second.text);

      editor.replaceText(0, 1, '', const TextSelection.collapsed(offset: 0));
      await Future<void>.delayed(Duration.zero);

      expect(controller.blocks, [first]);
    },
  );

  test('left image edge creates a text line before the image', () {
    final controller = _createController();
    const image = AttachmentBlock(id: 'image', displayName: 'photo.jpg');
    controller.blocks.assignAll([image]);

    controller.focusTextBesideAttachment(0, after: false);

    expect(controller.blocks, hasLength(2));
    expect(controller.blocks.first, isA<TextBlock>());
    expect(controller.blocks.last, image);
    expect(controller.activeBlockIndex.value, 0);
  });

  test('right image edge reuses the following text line', () {
    final controller = _createController();
    const image = AttachmentBlock(id: 'image', displayName: 'photo.jpg');
    const text = TextBlock(id: 'after-image', text: 'Caption');
    controller.blocks.assignAll([image, text]);

    controller.focusTextBesideAttachment(0, after: true);

    expect(controller.blocks, [image, text]);
    expect(controller.activeBlockIndex.value, 1);
    expect(
      controller.getQuillController(text.id, text.text).selection,
      const TextSelection.collapsed(offset: 0),
    );
  });
}

NoteDetailController _createController() {
  InitialBinding().dependencies();
  return NoteDetailController(
    getNoteDetail: Get.find<GetNoteDetail>(),
    saveNoteMetadata: Get.find<SaveNoteMetadata>(),
    saveNoteContent: Get.find<SaveNoteContent>(),
    updateNoteState: Get.find<UpdateNoteState>(),
    deleteRestoreNote: Get.find<DeleteRestoreNote>(),
    uploadAttachment: Get.find<UploadAttachment>(),
    downloadAttachment: Get.find<DownloadAttachment>(),
    getFolders: Get.find<GetFolders>(),
  );
}
