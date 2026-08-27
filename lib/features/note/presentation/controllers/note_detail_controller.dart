import 'dart:async';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as mlkit;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:ios_image_editor/ios_image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/app_media_storage.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/core/utils/image_pdf.dart';
import 'package:Note/core/utils/note_pdf.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/routes/note_navigation.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_create_modal.dart';
import 'package:Note/features/note/presentation/widgets/note_move_folder_modal.dart';
import 'package:Note/features/note/presentation/widgets/note_audio_recorder_sheet.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';
import 'package:Note/core/utils/note_snippet.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// Placeholder text kept in a checklist item's [TextEditingController] while
/// the item is otherwise empty. iOS never delivers a key event for the
/// on-screen keyboard's Backspace — the text-input channel only reports the
/// resulting value — so an item with truly empty text gives Backspace
/// nothing to report a change on. This invisible character gives it
/// something to delete, which [NoteChecklistBlock]'s input formatter reads
/// as "Backspace at the start of an empty item" and strips before the text
/// ever reaches [NoteDetailController.onUpdateChecklistItem].
final String kChecklistItemPlaceholder = String.fromCharCode(0x200B);

const _contentUriChannel = MethodChannel(
  'com.kimchheang.otokhi-note/content_uri',
);

/// Drives the note editor.
///
/// Block manipulation (text, checklists, tables, drawings, Quill state) is
/// editor view-state and stays here; everything that touches the server goes
/// through a use case.
class NoteDetailController extends GetxController {
  final GetNoteDetail _getNoteDetail;
  final SaveNoteMetadata _saveNoteMetadata;
  final SaveNoteContent _saveNoteContent;
  final UpdateNoteState _updateNoteState;
  final DeleteRestoreNote _deleteRestoreNote;
  final UploadAttachment _uploadAttachment;
  final DownloadAttachment _downloadAttachment;
  final GetFolders _getFolders;

  final ImagePicker _picker = ImagePicker();

  NoteDetailController({
    required GetNoteDetail getNoteDetail,
    required SaveNoteMetadata saveNoteMetadata,
    required SaveNoteContent saveNoteContent,
    required UpdateNoteState updateNoteState,
    required DeleteRestoreNote deleteRestoreNote,
    required UploadAttachment uploadAttachment,
    required DownloadAttachment downloadAttachment,
    required GetFolders getFolders,
  }) : _getNoteDetail = getNoteDetail,
       _saveNoteMetadata = saveNoteMetadata,
       _saveNoteContent = saveNoteContent,
       _updateNoteState = updateNoteState,
       _deleteRestoreNote = deleteRestoreNote,
       _uploadAttachment = uploadAttachment,
       _downloadAttachment = downloadAttachment,
       _getFolders = getFolders;

  // --- Observables ---
  final currentNote = Rxn<Note>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isReadOnly = false.obs;
  final isPinned = false.obs;
  final isArchived = false.obs;
  final isLocked = false.obs;

  // --- UI Controllers & Cache ---
  final titleController = TextEditingController();
  final titleFocusNode = FocusNode();
  final blocks = <NoteBlock>[].obs;
  final Map<String, quill.QuillController> quillControllers = {};
  final Map<String, TextEditingController> textControllers = {};
  final Map<String, FocusNode> blockFocusNodes = {};
  // Last-seen Document.length per text block, so its change listener can
  // tell "a delete just emptied this block" (length dropped to 1, the bare
  // trailing newline) apart from every other kind of edit — see
  // [_handleTextBlockEmptied].
  final Map<String, int> _lastTextBlockLength = {};
  // Set for the duration of qc.undo() only — see [undo].
  bool _suppressEmptiedCheck = false;

  // --- State ---
  final activeBlockIndex = (-1).obs;
  final currentBlockStyle = "body".obs;
  final isSearchVisible = false.obs;
  final searchQuery = "".obs;
  final searchFocusNode = FocusNode();
  final isFormatPanelVisible = false.obs;
  bool _autoRecordRequested = false;
  bool _isAudioRecorderOpen = false;

  // --- Global Drawing Mode (iOS 18 Style) ---
  final isDrawingMode = false.obs;
  final backgroundPoints = <Offset?>[].obs; // Global drawing data
  final drawingColor = Rx<Color>(Colors.black);
  final drawingStrokeWidth = 3.0.obs;

  void toggleDrawingMode() {
    isDrawingMode.toggle();
    if (isDrawingMode.value) {
      Get.focusScope?.unfocus(); // Dismiss keyboard when drawing
      AppSnackbar.info(
        'Drawing Mode',
        'You can now draw anywhere on the note.',
      );
    }
  }

  void clearGlobalDrawing() => backgroundPoints.clear();

  @override
  void onInit() {
    super.onInit();
    _handleArguments(Get.arguments);
  }

  @override
  void onReady() {
    super.onReady();
    if (!_autoRecordRequested) return;
    _autoRecordRequested = false;
    unawaited(recordAudio());
  }

  void _handleArguments(dynamic args) {
    if (args is Map) {
      final noteId = args['noteId'];
      final folderId = args['folderId'];
      isReadOnly.value = args['isDeleted'] == true;
      _autoRecordRequested = noteId == 0 && args['autoRecord'] == true;

      if (noteId != null && noteId != 0) {
        fetchNoteDetail(noteId);
      } else if (folderId != null) {
        _initNewNote(folderId);
      }
    }
  }

  Future<void> fetchNoteDetail(int id) async {
    isLoading.value = true;
    try {
      switch (await _getNoteDetail(id)) {
        case Ok(:final value):
          _setupNoteState(value);
        case Err(:final failure):
          AppSnackbar.failure('Could not load note', failure);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _setupNoteState(Note note) {
    currentNote.value = note;
    titleController.text = note.title;
    isPinned.value = note.isPinned;
    isArchived.value = note.isArchived;
    isLocked.value = note.isLocked;

    _clearControllers();
    blocks.assignAll(note.content);

    // A note whose last saved block is an image, checklist, table, or
    // drawing reopens with nowhere obvious to tap and keep writing — Apple
    // Notes always leaves a blank line under whatever you last added.
    // `blocks.isEmpty` alone missed this: it only covered a note with zero
    // content, not "content, but none of it trailing text."
    if (!isReadOnly.value && (blocks.isEmpty || blocks.last is! TextBlock)) {
      addTextBlock();
    }
  }

  void _initNewNote(int folderId) {
    currentNote.value = Note(
      id: 0,
      folderId: folderId,
      title: '',
      folderName: '',
      content: [],
    );
    blocks.clear();
    addTextBlock();
    isLoading.value = false;
  }

  // --- Controller Management ---

  quill.QuillController getQuillController(String blockId, String content) {
    return quillControllers.putIfAbsent(blockId, () {
      quill.Document doc;
      try {
        final trimmed = content.trim();
        if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
          doc = quill.Document.fromJson(jsonDecode(content));
        } else {
          doc = quill.Document()..insert(0, content);
        }
      } catch (_) {
        doc = quill.Document()..insert(0, content);
      }
      final qc = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
      _lastTextBlockLength[blockId] = doc.length;
      qc.addListener(() {
        _handleMarkdownShortcut(blockId);
        _handleTextBlockEmptied(blockId);
      });
      return qc;
    });
  }

  /// iOS 26 Notes-style body Backspace, detected the only way that's
  /// actually reliable on a touch device: [QuillEditorConfig.onKeyPressed]
  /// and raw `Focus.onKeyEvent` interception both explicitly don't fire for
  /// the on-screen keyboard's Backspace key (only for a hardware keyboard) —
  /// and there's no signal at all for "Backspace pressed while already
  /// empty," on any keyboard, because there's nothing to delete so no edit
  /// ever reaches the document. What *is* reliable: watching for the
  /// transition itself — a delete that brings a block's length down to 1
  /// (the bare trailing newline every [quill.Document] carries) is
  /// unambiguously "the user just backspaced the last character out of this
  /// block," so that's the moment [onTextBlockBackspace] runs instead.
  void _handleTextBlockEmptied(String blockId) {
    final qc = quillControllers[blockId];
    if (qc == null) return;

    final previousLength = _lastTextBlockLength[blockId] ?? qc.document.length;
    final currentLength = qc.document.length;
    _lastTextBlockLength[blockId] = currentLength;

    if (_suppressEmptiedCheck) return;
    if (currentLength != 1 || previousLength <= 1) return;

    final index = blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;
    // Deferred: this fires from inside the QuillController's own change
    // notification, and onTextBlockBackspace mutates blocks / disposes this
    // same controller.
    Future.microtask(() => onTextBlockBackspace(index));
  }

  /// iOS-Notes/Notion-style markdown shortcuts: typing "# " or "## " at the
  /// start of an otherwise-empty line switches that block to Heading /
  /// Subheading style, and "- " or "* " converts the still-empty text block
  /// straight into a checklist — the typed marker is consumed rather than
  /// left behind as literal text.
  void _handleMarkdownShortcut(String blockId) {
    final qc = quillControllers[blockId];
    if (qc == null) return;
    final raw = qc.document.toPlainText();
    final text = raw.endsWith('\n') ? raw.substring(0, raw.length - 1) : raw;

    String? newStyle;
    int prefixLength = 0;
    bool toChecklist = false;

    if (text == '# ') {
      newStyle = 'heading';
      prefixLength = 2;
    } else if (text == '## ') {
      newStyle = 'subheading';
      prefixLength = 3;
    } else if (text == '- ' || text == '* ') {
      toChecklist = true;
    } else {
      return;
    }

    final index = blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return;
    final block = blocks[index];
    if (block is! TextBlock) return;

    // Deferred: this fires from inside the QuillController's own change
    // notification, and both branches replace/dispose that controller.
    Future.microtask(() {
      if (toChecklist) {
        quillControllers.remove(blockId)?.dispose();
        final newItem = ChecklistItem(id: _generateId(), text: '');
        blocks[index] = ChecklistBlock(id: blockId, items: [newItem]);
        // Keep typing straight into the new item — same as every other
        // block-replacing mutation here (onChecklistItemEnter,
        // _exitChecklist) — instead of silently dropping the keyboard.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          getBlockFocusNode('${blockId}_${newItem.id}').requestFocus();
        });
      } else {
        qc.replaceText(
          0,
          prefixLength,
          '',
          const TextSelection.collapsed(offset: 0),
        );
        blocks[index] = TextBlock(
          id: block.id,
          text: block.text,
          style: newStyle!,
        );
        currentBlockStyle.value = newStyle;
      }
      blocks.refresh();
    });
  }

  TextEditingController getTextController(String key, String initialValue) {
    return textControllers.putIfAbsent(
      key,
      () => TextEditingController(text: initialValue),
    );
  }

  FocusNode getBlockFocusNode(String blockId) =>
      blockFocusNodes.putIfAbsent(blockId, () => FocusNode());

  /// iOS-Notes-style title→body flow: pressing return in the title field
  /// jumps straight into the first text block instead of just inserting a
  /// newline into the title.
  void focusFirstTextBlock() {
    final firstText = blocks.whereType<TextBlock>().firstOrNull;
    if (firstText != null) {
      getBlockFocusNode(firstText.id).requestFocus();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  /// iOS-Notes-style "tap anywhere to keep typing": tapping the empty space
  /// below the note's content jumps the cursor into the last text block,
  /// creating one first if the note doesn't have one yet.
  void focusLastTextBlock() {
    final lastText = blocks.whereType<TextBlock>().lastOrNull;
    if (lastText != null) {
      getBlockFocusNode(lastText.id).requestFocus();
      return;
    }
    addTextBlock();
    final created = blocks.whereType<TextBlock>().lastOrNull;
    if (created != null) getBlockFocusNode(created.id).requestFocus();
  }

  /// iOS 26 Notes-style body Backspace: once a block has just been
  /// backspaced down to empty (see [_handleTextBlockEmptied], the caller),
  /// this deletes that block outright and moves the cursor to the end of
  /// whatever's above — the previous text block, or back into the title if
  /// this was the first block in the note. Mirrors
  /// [onChecklistItemBackspace]'s scoping: with a non-text block (image,
  /// checklist, table, drawing) above it to fall back to, it's a no-op
  /// rather than attempting to merge rich content across block types.
  void onTextBlockBackspace(int blockIndex) {
    if (isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is! TextBlock) return;

    final qc = quillControllers[block.id];
    if (qc == null || !qc.document.isEmpty()) return;

    if (blockIndex == 0) {
      deleteBlock(blockIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        titleController.selection = TextSelection.collapsed(
          offset: titleController.text.length,
        );
        titleFocusNode.requestFocus();
      });
      return;
    }

    final previous = blocks[blockIndex - 1];
    deleteBlock(blockIndex);

    if (previous is TextBlock) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final previousQc = quillControllers[previous.id];
        if (previousQc == null) return;
        final end = previousQc.document.length - 1;
        previousQc.updateSelection(
          TextSelection.collapsed(offset: end < 0 ? 0 : end),
          quill.ChangeSource.local,
        );
        getBlockFocusNode(previous.id).requestFocus();
      });
    }
  }

  // --- Block Actions ---

  void addTextBlock({String style = 'body'}) {
    _insertBlock(TextBlock(id: _generateId(), text: '', style: style));
  }

  void addChecklistBlock() {
    _insertBlock(
      ChecklistBlock(
        id: _generateId(),
        items: [ChecklistItem(id: _generateId(), text: '')],
      ),
    );
  }

  void addTableBlock() {
    _insertBlock(
      TableBlock(
        id: _generateId(),
        rows: [
          ['', ''],
          ['', ''],
        ],
      ),
    );
  }

  /// Quick-compose shortcut from inside an already-open note — pushes a
  /// fresh blank note in the same folder, leaving this one where it is on
  /// the nav stack underneath.
  void createNewNote() {
    final folderId = currentNote.value?.folderId ?? 0;
    NoteNavigation.toNewNote(folderId);
  }

  Future<void> startDrawing() async {
    if (isReadOnly.value) return;

    try {
      // 1. Create a blank white canvas for a clean start
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()..color = Colors.white;
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 2000, 2000), paint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(2000, 2000);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      // 2. Save to temp file
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(buffer);

      // 3. Open native iOS Markup editor DIRECTLY
      final String? editedPath = await IOSImageEditor.editImage(path);

      if (editedPath != null && editedPath.isNotEmpty) {
        final id = _generateId();
        final persistedPath = await _persistAttachment(editedPath, id);
        // 4. Add as a new attachment block and refresh
        _insertBlock(
          AttachmentBlock(
            id: id,
            displayName: 'Sketch',
            localPath: persistedPath,
            attachmentId: 0,
          ),
        );
        blocks.refresh();
        addTextBlock();
        unawaited(saveNote());
      }
    } catch (e) {
      debugPrint('[DRAWING ERROR] $e');
      AppSnackbar.error('Error', 'Could not start drawing board');
    }
  }

  Future<void> addAttachment(ImageSource source, {bool isVideo = false}) async {
    if (isReadOnly.value) return;

    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(source: source, imageQuality: 80);

      if (file == null) return;

      final id = _generateId();
      final persistedPath = await _persistAttachment(file.path, id);
      _insertBlock(
        AttachmentBlock(
          id: id,
          displayName: file.name,
          localPath: persistedPath,
          attachmentId: 0,
        ),
      );
      blocks.refresh();
      addTextBlock();
      unawaited(saveNote(silent: true));
    } catch (e) {
      debugPrint('[CAMERA ERROR] $e');
      AppSnackbar.error(
        'Error',
        'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}',
      );
    }
  }

  /// "Choose Photo or Video" from the attachment sheet — one gallery pick
  /// that can return several photos and videos in any mix, unlike
  /// [addAttachment] which is locked to whichever `isVideo` says before the
  /// picker even opens and returns at most one file.
  Future<void> addMediaAttachment() async {
    if (isReadOnly.value) return;

    try {
      final files = await _picker.pickMultipleMedia(imageQuality: 80);
      if (files.isEmpty) return;

      for (final file in files) {
        final id = _generateId();
        final persistedPath = await _persistAttachment(file.path, id);
        _insertBlock(
          AttachmentBlock(
            id: id,
            displayName: file.name,
            localPath: persistedPath,
            attachmentId: 0,
          ),
        );
      }
      blocks.refresh();
      addTextBlock();
      unawaited(saveNote(silent: true));
    } catch (e) {
      debugPrint('[GALLERY ERROR] $e');
      AppSnackbar.error('Error', 'Could not access gallery');
    }
  }

  /// "Attach File" from the attachment sheet — any file type, not just
  /// photos/video. Reuses the same upload path as [addAttachment]; the
  /// block renders as a generic file tile when it isn't an image.
  Future<void> addFileAttachment() async {
    if (isReadOnly.value) return;

    try {
      final result = await FilePicker.platform.pickFiles();
      final picked = result?.files.single;
      if (picked?.path == null) return;

      final id = _generateId();
      final persistedPath = await _persistAttachment(picked!.path!, id);
      _insertBlock(
        AttachmentBlock(
          id: id,
          displayName: picked.name,
          localPath: persistedPath,
          attachmentId: 0,
        ),
      );
      blocks.refresh();
      addTextBlock();
      unawaited(saveNote(silent: true));
    } catch (e) {
      debugPrint('[FILE PICKER ERROR] $e');
      AppSnackbar.error('Error', 'Could not attach that file');
    }
  }

  /// "Scan Documents" — jumps straight into the native document camera with
  /// no prompts first. Every completed scan is printed into one A4 PDF under
  /// a default title, including a scan containing only one page.
  Future<void> scanDocuments() async {
    if (isReadOnly.value) return;

    try {
      final result = await FlutterDocScanner().getScannedDocumentAsImages(
        page: 20,
        imageFormat: ImageFormat.jpeg,
        quality: 0.8,
      );
      final pages = await _materializeScanPages(result?.images ?? const []);
      if (pages.isEmpty) return;
      await _insertScannedDocumentPdf(pages);
    } catch (e) {
      debugPrint('[SCAN DOCS ERROR] $e');
      AppSnackbar.error('Error', 'Could not scan document');
    }
  }

  /// "Document from Photo" — same output as [scanDocuments], but the pages
  /// come from the photo gallery instead of the live document camera.
  Future<void> scanDocumentsFromGallery() async {
    if (isReadOnly.value) return;

    try {
      final files = await _picker.pickMultiImage(imageQuality: 80);
      if (files.isEmpty) return;
      final pages = files.map((file) => file.path).toList(growable: false);
      await _insertScannedDocumentPdf(pages);
    } catch (e) {
      debugPrint('[SCAN DOCS FROM GALLERY ERROR] $e');
      AppSnackbar.error('Error', 'Could not add those photos');
    }
  }

  Future<void> _insertScannedDocumentPdf(List<String> pages) async {
    final title = 'note_editor_scanned_document_default_title'.tr;
    final id = 'scan_${_generateId()}';
    final pdfPath = await buildMultiPageImagePdf(
      imagePaths: pages,
      blockId: id,
      title: title,
      showTitle: true,
      createdAt: DateTime.now(),
      showPageNumbers: true,
      pageLabel: 'note_editor_pdf_page'.tr,
      ofLabel: 'note_editor_pdf_of'.tr,
    );
    _insertBlock(
      AttachmentBlock(
        id: id,
        displayName: _scannedDocumentFileName(title),
        localPath: pdfPath,
        attachmentId: 0,
      ),
    );
    blocks.refresh();
    addTextBlock();
    unawaited(saveNote(silent: true));
  }

  Future<List<String>> _materializeScanPages(List<String> rawPaths) async {
    final pages = <String>[];
    for (final rawPath in rawPaths) {
      final uri = Uri.tryParse(rawPath);
      if (uri?.scheme == 'content') {
        final copiedPath = await _contentUriChannel.invokeMethod<String>(
          'copyContentUriToCache',
          {'uri': rawPath, 'extension': '.jpg'},
        );
        if (copiedPath != null && copiedPath.isNotEmpty) pages.add(copiedPath);
      } else if (uri?.scheme == 'file') {
        pages.add(uri!.toFilePath());
      } else {
        pages.add(rawPath);
      }
    }
    return pages;
  }

  String _scannedDocumentFileName(String title) {
    var name = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
    if (name.toLowerCase().endsWith('.pdf')) {
      name = name.substring(0, name.length - 4).trim();
    }
    if (name.isEmpty) name = 'note_editor_scanned_document_default_title'.tr;
    return '$name.pdf';
  }

  /// "Scan Text" — captures one page with the same document camera as
  /// [scanDocuments], runs on-device text recognition over it, then throws
  /// the photo away and attaches the recognized *text* itself as a clean,
  /// typeset PDF — unlike [scanDocuments], which keeps the photographed page.
  Future<void> scanText() async {
    if (isReadOnly.value) return;

    try {
      final result = await FlutterDocScanner().getScannedDocumentAsImages(
        page: 1,
        imageFormat: ImageFormat.jpeg,
        quality: 0.9,
      );
      final pages = await _materializeScanPages(result?.images ?? const []);
      final path = pages.firstOrNull;
      if (path == null) return;
      await _insertScannedTextPdf(path);
    } catch (e) {
      debugPrint('[SCAN TEXT ERROR] $e');
      AppSnackbar.error('Error', 'Could not scan text');
    }
  }

  /// "Text from Photo" — same output as [scanText], but the source page
  /// comes from the photo gallery instead of the live document camera.
  Future<void> scanTextFromGallery() async {
    if (isReadOnly.value) return;

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file == null) return;
      await _insertScannedTextPdf(file.path);
    } catch (e) {
      debugPrint('[SCAN TEXT FROM GALLERY ERROR] $e');
      AppSnackbar.error('Error', 'Could not scan text from that photo');
    }
  }

  Future<void> _insertScannedTextPdf(String imagePath) async {
    final recognizer = mlkit.TextRecognizer(
      script: mlkit.TextRecognitionScript.latin,
    );
    final mlkit.RecognizedText recognizedText;
    try {
      recognizedText = await recognizer.processImage(
        mlkit.InputImage.fromFilePath(imagePath),
      );
    } finally {
      await recognizer.close();
    }

    final text = recognizedText.text.trim();
    if (text.isEmpty) {
      AppSnackbar.info('No text found', "Couldn't find any text in that scan.");
      return;
    }

    final title = _titleFromRecognizedText(text);
    final id = 'scan_${_generateId()}';
    final pdfPath = await buildTextPdf(
      title: title,
      text: text,
      date: DateTime.now(),
    );
    _insertBlock(
      AttachmentBlock(
        id: id,
        displayName: _scannedDocumentFileName(title),
        localPath: pdfPath,
        attachmentId: 0,
      ),
    );
    blocks.refresh();
    addTextBlock();
    unawaited(saveNote(silent: true));
  }

  /// The first non-empty line of the OCR result, capped to a sane file-name
  /// length — falls back to the generic default when nothing usable is left.
  String _titleFromRecognizedText(String text) {
    final firstLine = text
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) {
      return 'note_editor_scanned_text_default_title'.tr;
    }
    return firstLine.length > 60
        ? '${firstLine.substring(0, 60).trim()}…'
        : firstLine;
  }

  /// "Record Audio" — the sheet owns the entire record/stop/cancel flow and
  /// only calls back once, with a finished file. This just attaches it the
  /// same way every other pick does.
  Future<void> recordAudio() async {
    if (isReadOnly.value || _isAudioRecorderOpen) return;

    _isAudioRecorderOpen = true;
    try {
      await Get.to(
        () => NoteAudioRecorderSheet(onRecorded: _addRecordedAttachment),
        fullscreenDialog: true,
        transition: Transition.cupertino,
      );
    } finally {
      _isAudioRecorderOpen = false;
    }
  }

  Future<void> _addRecordedAttachment(String path, String displayName) async {
    try {
      final id = _generateId();
      final persistedPath = await _persistAttachment(path, id);
      _insertBlock(
        AttachmentBlock(
          id: id,
          displayName: displayName,
          localPath: persistedPath,
          attachmentId: 0,
        ),
      );
      blocks.refresh();
      addTextBlock();
      unawaited(saveNote(silent: true));
    } catch (error) {
      debugPrint('[AUDIO SAVE ERROR] $error');
      AppSnackbar.error('Error', 'Could not save that recording');
    }
  }

  /// Resolves a local file for [remoteUrl] so the image editor has something to
  /// open. Returns `null` and reports the reason if the download fails.
  Future<String?> cacheAttachmentForEditing(String remoteUrl) async {
    final directory = await getTemporaryDirectory();
    final savePath =
        '${directory.path}/edit_${DateTime.now().millisecondsSinceEpoch}.png';

    final result = await _downloadAttachment(
      DownloadAttachmentParams(url: remoteUrl, savePath: savePath),
    );

    switch (result) {
      case Ok(:final value):
        return value;
      case Err(:final failure):
        AppSnackbar.failure('Could not prepare image for editing', failure);
        return null;
    }
  }

  /// Resolves a local file for a remote audio attachment so the player has
  /// something to open — the audio equivalent of [cacheAttachmentForEditing].
  /// Kept separate rather than generalizing that one: it hardcodes `.png`
  /// for the image editor, and playback needs the file's real extension so
  /// the platform decoder picks the right codec.
  Future<String?> cacheAttachmentForPlayback(
    String remoteUrl, {
    required String extension,
  }) async {
    final directory = await getTemporaryDirectory();
    final savePath =
        '${directory.path}/playback_${DateTime.now().millisecondsSinceEpoch}$extension';

    final result = await _downloadAttachment(
      DownloadAttachmentParams(url: remoteUrl, savePath: savePath),
    );

    switch (result) {
      case Ok(:final value):
        return value;
      case Err(:final failure):
        AppSnackbar.failure('Could not load audio', failure);
        return null;
    }
  }

  /// Downloads a remote PDF into temporary storage so it can be rendered by
  /// the inline paper preview and full-screen viewer.
  Future<String?> cacheAttachmentForPreview(
    String remoteUrl, {
    required String extension,
  }) async {
    final directory = await getTemporaryDirectory();
    final savePath =
        '${directory.path}/preview_${DateTime.now().millisecondsSinceEpoch}$extension';

    final result = await _downloadAttachment(
      DownloadAttachmentParams(url: remoteUrl, savePath: savePath),
    );

    switch (result) {
      case Ok(:final value):
        return value;
      case Err(:final failure):
        AppSnackbar.failure('note_editor_pdf_preview_failed'.tr, failure);
        return null;
    }
  }

  void updateAttachmentImage(int blockIndex, String editedPath) {
    unawaited(_persistEditedAttachment(blockIndex, editedPath));
  }

  Future<void> _persistEditedAttachment(
    int blockIndex,
    String editedPath,
  ) async {
    if (isReadOnly.value || blockIndex < 0 || blockIndex >= blocks.length) {
      return;
    }
    final block = blocks[blockIndex];
    if (block is! AttachmentBlock) return;

    try {
      // ios_image_editor may return a temporary path or overwrite the input
      // in place. Copying first gives the edit a stable, uniquely keyed file.
      final persistedPath = await _persistAttachment(
        editedPath,
        block.id,
        forceCopy: true,
      );
      if (blockIndex >= blocks.length || blocks[blockIndex].id != block.id) {
        return;
      }

      PaintingBinding.instance.imageCache.evict(FileImage(File(persistedPath)));
      blocks[blockIndex] = AttachmentBlock(
        id: block.id,
        attachmentId: 0,
        // Keep a real extension on the name — it's the most reliable of the
        // three signals note_attachment_block.dart uses to identify images.
        displayName: 'Edited Image${_extensionOf(persistedPath)}',
        localPath: persistedPath,
        url: block.url,
      );
      blocks.refresh();
      if (block.localPath != persistedPath) {
        await AppMediaStorage.deleteIfManaged(
          path: block.localPath,
          folder: 'note_attachments',
        );
      }
      unawaited(saveNote(silent: true));
    } catch (error) {
      debugPrint('[EDITED IMAGE SAVE ERROR] $error');
      AppSnackbar.error('Error', 'Could not save that edited image');
    }
  }

  /// `.jpg` from `/tmp/.../photo.jpg`, or `''` if [path] has no extension.
  String _extensionOf(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot);
  }

  /// Turns an image attachment into a one-page PDF in place.
  ///
  /// The block keeps its id — that's what [buildImagePdf] files the editable
  /// original under — but goes back to `attachmentId: 0` because the PDF is a
  /// different file than whatever was uploaded for the image, so the next save
  /// has to upload it fresh.
  Future<void> convertAttachmentToPdf(int blockIndex) async {
    if (isReadOnly.value || blockIndex < 0 || blockIndex >= blocks.length) {
      return;
    }
    final block = blocks[blockIndex];
    if (block is! AttachmentBlock) return;

    final imagePath = await _resolveEditableImagePath(block);
    if (imagePath == null) return;

    try {
      final name = _pdfNameFor(block.displayName);
      final pdfPath = await buildImagePdf(
        imagePath: imagePath,
        blockId: block.id,
        title: name,
      );
      await storePdfSourceImage(imagePath: imagePath, blockId: block.id);

      // The image's own file is safe to drop now — its bytes live on both in
      // the PDF and in the stored source copy. Deliberately not
      // `_deleteLocalAttachmentFile`: that also clears the block's PDF
      // storage, which at this point holds the document just written.
      _deleteFileAt(normalizeLocalPath(block.localPath));

      blocks[blockIndex] = AttachmentBlock(
        id: block.id,
        attachmentId: 0,
        displayName: name,
        localPath: pdfPath,
        // The old url still points at the image on the server; carrying it
        // over would make the PDF block render that picture instead.
        url: null,
      );
      blocks.refresh();
      AppSnackbar.success('Converted', '$name is ready');
    } catch (e) {
      debugPrint('[PDF CONVERT ERROR] $e');
      AppSnackbar.error('Error', 'Could not convert that image to PDF');
    }
  }

  /// Restores the original image that was used to build a PDF attachment.
  ///
  /// This is the inverse of [convertAttachmentToPdf]. It only works if the
  /// source image is still on this device's local storage.
  Future<void> convertPdfToImage(int blockIndex) async {
    if (isReadOnly.value || blockIndex < 0 || blockIndex >= blocks.length) {
      return;
    }
    final block = blocks[blockIndex];
    if (block is! AttachmentBlock) return;

    final sourcePath = await findPdfSourceImage(block.id);
    if (sourcePath == null || !File(sourcePath).existsSync()) {
      AppSnackbar.info(
        'Not reversible',
        'The original image for this PDF is no longer on this device.',
      );
      return;
    }

    try {
      final name = _imageNameFor(block.displayName, sourcePath);

      // We move the source image out of the PDF storage back into the app's
      // general attachment area.
      final imageFile = File(sourcePath);
      final newPath = await _moveToAttachments(imageFile);

      // Clear the PDF storage for this block since it's no longer a PDF.
      await deletePdfFiles(block.id);

      blocks[blockIndex] = AttachmentBlock(
        id: block.id,
        attachmentId: 0,
        displayName: name,
        localPath: newPath,
        url: null,
      );
      blocks.refresh();
      AppSnackbar.success('Restored', 'Attachment is an image again');
    } catch (e) {
      debugPrint('[IMAGE RESTORE ERROR] $e');
      AppSnackbar.error('Error', 'Could not convert back to image');
    }
  }

  /// Re-opens the picture a PDF block was built from in the markup editor and
  /// rebuilds the PDF from the edited result.
  ///
  /// Only works where the source copy is: a PDF attached from Files, or one
  /// converted on another device, has nothing to go back to.
  Future<void> editPdfSourceImage(int blockIndex) async {
    if (isReadOnly.value || blockIndex < 0 || blockIndex >= blocks.length) {
      return;
    }
    final block = blocks[blockIndex];
    if (block is! AttachmentBlock) return;

    final sourcePath = await findPdfSourceImage(block.id);
    if (sourcePath == null || !File(sourcePath).existsSync()) {
      AppSnackbar.info(
        'Not editable',
        'The original image for this PDF isn\'t on this device.',
      );
      return;
    }

    try {
      final editedPath = await IOSImageEditor.editImage(sourcePath);
      if (editedPath == null || editedPath.isEmpty) return;

      // The editor usually writes the markup back into the file it was handed,
      // but re-store whenever it hands back somewhere else so the next edit
      // still starts from the newest version.
      if (editedPath != sourcePath) {
        await storePdfSourceImage(imagePath: editedPath, blockId: block.id);
      }

      final pdfPath = await buildImagePdf(
        imagePath: editedPath,
        blockId: block.id,
        title: block.displayName,
      );

      blocks[blockIndex] = AttachmentBlock(
        id: block.id,
        attachmentId: 0,
        displayName: block.displayName,
        localPath: pdfPath,
        url: null,
      );
      blocks.refresh();
    } catch (e) {
      debugPrint('[PDF EDIT ERROR] $e');
      AppSnackbar.error('Error', 'Could not edit that PDF');
    }
  }

  /// A local file for [block]'s image, downloading it first when the block
  /// only has a server copy. `null` means there's nothing to work from and the
  /// reason has already been reported.
  Future<String?> _resolveEditableImagePath(AttachmentBlock block) async {
    final localPath = normalizeLocalPath(block.localPath);
    if (localPath != null && File(localPath).existsSync()) return localPath;

    final url = normalizeAttachmentUrl(block.url);
    if (url == null || url.isEmpty) {
      AppSnackbar.error('Error', 'Image source not available');
      return null;
    }
    final cached = await cacheAttachmentForEditing(url);
    if (cached == null || !File(cached).existsSync()) return null;
    return cached;
  }

  /// `receipt.pdf` becomes `receipt.jpg` (or whatever the source image was).
  String _imageNameFor(String displayName, String sourcePath) {
    final name = displayName.trim();
    final extension = _extensionOf(sourcePath);
    if (name.toLowerCase().endsWith('.pdf')) {
      return '${name.substring(0, name.length - 4)}$extension';
    }
    return 'Restored Image$extension';
  }

  /// Copies a file into the app's persistent attachment storage.
  Future<String> _moveToAttachments(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${dir.path}/guest_attachments');
    if (!attachmentsDir.existsSync()) {
      await attachmentsDir.create(recursive: true);
    }

    final name =
        'restored_${DateTime.now().millisecondsSinceEpoch}${_extensionOf(file.path)}';
    final dest = await file.copy('${attachmentsDir.path}/$name');
    return dest.path;
  }

  /// `receipt.jpg` becomes `receipt.pdf`; a name with no extension just gains
  /// one. Keeping a real `.pdf` on the end is what makes the block render as a
  /// document tile rather than a broken image.
  String _pdfNameFor(String displayName) {
    final name = displayName.trim();
    if (name.isEmpty) return 'Document.pdf';
    final dot = name.lastIndexOf('.');
    return '${dot <= 0 ? name : name.substring(0, dot)}.pdf';
  }

  void updateDrawing(int blockIndex, String path) {
    unawaited(_persistDrawing(blockIndex, path));
  }

  Future<void> _persistDrawing(int blockIndex, String path) async {
    if (isReadOnly.value || blockIndex < 0 || blockIndex >= blocks.length) {
      return;
    }
    try {
      final id = blocks[blockIndex].id;
      final persistedPath = await _persistAttachment(path, id);
      if (blockIndex >= blocks.length || blocks[blockIndex].id != id) return;
      blocks[blockIndex] = DrawingBlock(id: id, localPath: persistedPath);
      blocks.refresh();
      unawaited(saveNote(silent: true));
    } catch (error) {
      debugPrint('[DRAWING SAVE ERROR] $error');
      AppSnackbar.error('Error', 'Could not save that drawing');
    }
  }

  // --- Checklist Actions ---

  void addChecklistItem(int blockIndex) {
    if (isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is ChecklistBlock) {
      final newItems = List<ChecklistItem>.from(block.items)
        ..add(ChecklistItem(id: _generateId(), text: ''));
      blocks[blockIndex] = ChecklistBlock(id: block.id, items: newItems);
      blocks.refresh();
    }
  }

  /// iOS-Notes-style checklist Return key: on a non-empty item, inserts a
  /// new empty item right below and focuses it (rather than a literal
  /// newline inside the same item). On an empty item, exits the list —
  /// leaving the rest of the checklist in place and continuing as a normal
  /// paragraph, or replacing the whole checklist if it was the only item.
  void onChecklistItemEnter(int blockIndex, int itemIndex) {
    if (isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is! ChecklistBlock) return;
    final item = block.items[itemIndex];

    if (item.text.trim().isEmpty) {
      _exitChecklist(blockIndex, itemIndex);
      return;
    }

    final newItem = ChecklistItem(id: _generateId(), text: '');
    final newItems = List<ChecklistItem>.from(block.items)
      ..insert(itemIndex + 1, newItem);
    blocks[blockIndex] = ChecklistBlock(id: block.id, items: newItems);
    blocks.refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getBlockFocusNode('${block.id}_${newItem.id}').requestFocus();
    });
  }

  void _exitChecklist(int blockIndex, int itemIndex) {
    final block = blocks[blockIndex];
    if (block is! ChecklistBlock) return;

    if (block.items.length == 1) {
      final newBlock = TextBlock(id: block.id, text: '', style: 'body');
      blocks[blockIndex] = newBlock;
      blocks.refresh();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        getBlockFocusNode(newBlock.id).requestFocus();
      });
      return;
    }

    final newItems = List<ChecklistItem>.from(block.items)..removeAt(itemIndex);
    blocks[blockIndex] = ChecklistBlock(id: block.id, items: newItems);
    final newBlock = TextBlock(id: _generateId(), text: '', style: 'body');
    blocks.insert(blockIndex + 1, newBlock);
    blocks.refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getBlockFocusNode(newBlock.id).requestFocus();
    });
  }

  void toggleChecklistItem(int blockIndex, int itemIndex) {
    final block = blocks[blockIndex];
    if (block is ChecklistBlock) {
      final item = block.items[itemIndex];
      final newItems = List<ChecklistItem>.from(block.items);
      newItems[itemIndex] = ChecklistItem(
        id: item.id,
        text: item.text,
        checked: !item.checked,
      );
      blocks[blockIndex] = ChecklistBlock(id: block.id, items: newItems);
      blocks.refresh();
    }
  }

  void onUpdateChecklistItem(int blockIndex, int itemIndex, String text) {
    final block = blocks[blockIndex];
    if (block is ChecklistBlock) {
      final item = block.items[itemIndex];
      final newItems = List<ChecklistItem>.from(block.items);
      newItems[itemIndex] = ChecklistItem(
        id: item.id,
        text: text,
        checked: item.checked,
      );
      blocks[blockIndex] = ChecklistBlock(id: block.id, items: newItems);
    }
  }

  void deleteChecklistItem(int blockIndex, int itemIndex) {
    if (isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is ChecklistBlock && block.items.length > 1) {
      final newItems = List<ChecklistItem>.from(block.items)
        ..removeAt(itemIndex);
      blocks[blockIndex] = ChecklistBlock(id: block.id, items: newItems);
      blocks.refresh();
    }
  }

  /// iOS-Notes-style checklist Backspace: pressed at the very start of an
  /// item, it deletes that item and merges its text onto the end of the
  /// item above, focusing there at the merge point — the reverse of
  /// [onChecklistItemEnter]. Pressed on the first item there is nothing
  /// above to merge into: it collapses the whole list back into a plain
  /// paragraph if that was the only item, otherwise it's a no-op.
  void onChecklistItemBackspace(int blockIndex, int itemIndex) {
    if (isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is! ChecklistBlock) return;

    if (itemIndex == 0) {
      if (block.items.length > 1) return;
      final newBlock = TextBlock(id: block.id, text: '', style: 'body');
      blocks[blockIndex] = newBlock;
      blocks.refresh();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        getBlockFocusNode(newBlock.id).requestFocus();
      });
      return;
    }

    final item = block.items[itemIndex];
    final previous = block.items[itemIndex - 1];
    final mergedText = previous.text + item.text;
    final newItems = List<ChecklistItem>.from(block.items);
    newItems[itemIndex - 1] = ChecklistItem(
      id: previous.id,
      text: mergedText,
      checked: previous.checked,
    );
    newItems.removeAt(itemIndex);
    blocks[blockIndex] = ChecklistBlock(id: block.id, items: newItems);
    blocks.refresh();

    final previousKey = '${block.id}_${previous.id}';
    final mergeOffset = previous.text.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final displayText = mergedText.isEmpty
          ? kChecklistItemPlaceholder
          : mergedText;
      getTextController(previousKey, displayText).value = TextEditingValue(
        text: displayText,
        selection: TextSelection.collapsed(
          offset: mergedText.isEmpty ? displayText.length : mergeOffset,
        ),
      );
      getBlockFocusNode(previousKey).requestFocus();
    });
  }

  // --- Table Actions ---

  void updateTableCell(
    int blockIndex,
    int rowIndex,
    int colIndex,
    String value,
  ) {
    final block = blocks[blockIndex];
    if (block is TableBlock) {
      final newRows = List<List<String>>.from(
        block.rows.map((r) => List<String>.from(r)),
      );
      newRows[rowIndex][colIndex] = value;
      blocks[blockIndex] = TableBlock(id: block.id, rows: newRows);
    }
  }

  void addTableRow(int blockIndex) {
    if (isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is TableBlock) {
      final colCount = block.rows.isNotEmpty ? block.rows.first.length : 2;
      final newRows = List<List<String>>.from(block.rows)
        ..add(List.filled(colCount, ''));
      blocks[blockIndex] = TableBlock(id: block.id, rows: newRows);
      blocks.refresh();
    }
  }

  void addTableColumn(int blockIndex) {
    if (isReadOnly.value) return;
    final block = blocks[blockIndex];
    if (block is TableBlock) {
      final newRows = block.rows
          .map((r) => List<String>.from(r)..add(''))
          .toList();
      blocks[blockIndex] = TableBlock(id: block.id, rows: newRows);
      blocks.refresh();
    }
  }

  // --- Formatting ---

  void toggleFormatPanel() {
    if (isReadOnly.value) return;
    isFormatPanelVisible.toggle();
  }

  void applyInlineFormat(quill.Attribute attribute) {
    if (isReadOnly.value || activeBlockIndex.value < 0) return;
    final block = blocks[activeBlockIndex.value];
    if (block is TextBlock) {
      final qc = quillControllers[block.id];
      qc?.formatSelection(attribute);
    }
  }

  /// Adds a web link to the current selection, or inserts linked text at the
  /// cursor when nothing is selected.
  Future<void> addLink() async {
    if (isReadOnly.value || activeBlockIndex.value < 0) {
      AppSnackbar.info(
        'note_editor_link_title'.tr,
        'note_editor_link_focus_message'.tr,
      );
      return;
    }

    final block = blocks[activeBlockIndex.value];
    if (block is! TextBlock) return;
    final quillController = quillControllers[block.id];
    final context = Get.context;
    if (quillController == null || context == null) return;

    final selection = quillController.selection;
    final selectionStart = selection.start.clamp(
      0,
      quillController.document.length - 1,
    );
    final selectionLength = selection.isCollapsed
        ? 0
        : selection.end - selection.start;
    final selectedText = selectionLength > 0
        ? quillController.document.getPlainText(selectionStart, selectionLength)
        : '';
    final textController = TextEditingController(text: selectedText);
    final urlController = TextEditingController();

    void insertLink() {
      final url = _normalizedWebLink(urlController.text);
      if (url == null) {
        AppSnackbar.warning(
          'note_editor_invalid_link_title'.tr,
          'note_editor_invalid_link_message'.tr,
        );
        return;
      }

      final label = textController.text.trim().isEmpty
          ? url
          : textController.text.trim();
      quillController.replaceText(
        selectionStart,
        selectionLength,
        label,
        TextSelection.collapsed(offset: selectionStart + label.length),
      );
      quillController.formatText(
        selectionStart,
        label.length,
        quill.LinkAttribute(url),
      );
      Get.back();
    }

    try {
      await CustomGlassSheet.show<void>(
        context: context,
        isScrollable: false,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'note_editor_link_title'.tr,
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              CustomGlassTextField(
                controller: textController,
                placeholder: 'note_editor_link_text_hint'.tr,
                textInputAction: TextInputAction.next,
                autofocus: selectedText.isEmpty,
                useOwnLayer: false,
              ),
              const SizedBox(height: 12),
              CustomGlassTextField(
                controller: urlController,
                placeholder: 'note_editor_link_url_hint'.tr,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                autofocus: selectedText.isNotEmpty,
                useOwnLayer: false,
                onSubmitted: (_) => insertLink(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: CustomGlassButton(
                  onPressed: insertLink,
                  semanticLabel: 'note_editor_link_add'.tr,
                  borderRadius: 24,
                  glassColor: Theme.of(sheetContext).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'note_editor_link_add'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      textController.dispose();
      urlController.dispose();
    }
  }

  String? _normalizedWebLink(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return null;
    final candidate = raw.contains('://') ? raw : 'https://$raw';
    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri.toString();
  }

  /// `Attribute.indent` carries no level, so running it through
  /// [applyInlineFormat] clears indentation instead of increasing it —
  /// indentation is stepped via [quill.QuillController.indentSelection].
  void applyIndent({bool increase = true}) {
    if (isReadOnly.value || activeBlockIndex.value < 0) return;
    final block = blocks[activeBlockIndex.value];
    if (block is TextBlock) {
      final qc = quillControllers[block.id];
      qc?.indentSelection(increase);
    }
  }

  /// Toggles a highlight in [color] on the current selection — off if it's
  /// already that color, applied otherwise (never stacks multiple colors).
  void applyHighlight(Color color) {
    if (isReadOnly.value || activeBlockIndex.value < 0) return;
    final block = blocks[activeBlockIndex.value];
    if (block is! TextBlock) return;
    final qc = quillControllers[block.id];
    if (qc == null) return;

    final hex =
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    final current = qc.getSelectionStyle().attributes['background']?.value;
    qc.formatSelection(quill.BackgroundAttribute(current == hex ? null : hex));
  }

  void updateActiveBlockStyle(String style) {
    if (isReadOnly.value || activeBlockIndex.value < 0) return;
    final block = blocks[activeBlockIndex.value];
    if (block is TextBlock) {
      blocks[activeBlockIndex.value] = TextBlock(
        id: block.id,
        text: block.text,
        style: style,
      );
      currentBlockStyle.value = style;
      blocks.refresh();
    }
  }

  // --- General Actions ---

  void deleteBlock(int index) {
    if (isReadOnly.value) return;
    final block = blocks[index];
    _deleteLocalAttachmentFile(block);
    if (block is TextBlock) {
      quillControllers.remove(block.id)?.dispose();
      _lastTextBlockLength.remove(block.id);
    }
    blockFocusNodes.remove(block.id)?.dispose();
    blocks.removeAt(index);
    blocks.refresh();
  }

  /// Removes an attachment/drawing block's on-device copy along with the
  /// block itself, so deleting a picture actually frees the space it was
  /// taking up in the app's local storage instead of leaving it orphaned
  /// there forever. `localPath` always points inside this app's own sandbox
  /// (image_picker/file_picker's cache, or `guest_attachments/` — see
  /// LocalNoteRepository), never a file another app owns, so it's always
  /// safe to delete outright.
  void _deleteLocalAttachmentFile(NoteBlock block) {
    final path = switch (block) {
      AttachmentBlock(:final localPath) => localPath,
      DrawingBlock(:final localPath) => localPath,
      _ => null,
    };
    // A converted PDF also has an editable original filed away under its
    // block id, which `localPath` says nothing about — clear that too so
    // deleting the block doesn't strand it.
    if (block is AttachmentBlock) unawaited(deletePdfFiles(block.id));
    _deleteFileAt(path);
  }

  void _deleteFileAt(String? path) {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      debugPrint('[DELETE ATTACHMENT FILE ERROR] $e');
    }
  }

  void _insertBlock(NoteBlock block) {
    if (activeBlockIndex.value >= 0 && activeBlockIndex.value < blocks.length) {
      blocks.insert(activeBlockIndex.value + 1, block);
      activeBlockIndex.value++;
    } else {
      blocks.add(block);
      activeBlockIndex.value = blocks.length - 1;
    }
  }

  Future<String> _persistAttachment(
    String sourcePath,
    String blockId, {
    bool forceCopy = false,
  }) {
    return AppMediaStorage.persist(
      sourcePath: sourcePath,
      folder: 'note_attachments',
      fileName: '${blockId}_${DateTime.now().microsecondsSinceEpoch}',
      forceCopy: forceCopy,
    );
  }

  void _syncBlocks() {
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block is TextBlock) {
        final qc = quillControllers[block.id];
        if (qc != null) {
          final deltaJson = qc.document.toDelta().toJson();
          blocks[i] = TextBlock(
            id: block.id,
            text: jsonEncode(deltaJson),
            style: block.style,
          );
        }
      }
    }
  }

  // --- SAVE FLOW ---

  Future<void> saveNote({bool silent = false}) async {
    if (isSaving.value || isReadOnly.value) return;

    Get.focusScope?.unfocus();
    isSaving.value = true;

    try {
      _syncBlocks();

      final int folderId = currentNote.value?.folderId ?? 0;
      final String title = titleController.text.trim();
      int noteId = currentNote.value?.id ?? 0;

      // FEATURE Logic: If there is a global background sketch, capture it as a block first
      if (backgroundPoints.isNotEmpty) {
        await _flattenBackgroundDrawing();
      }

      // Metadata first: a new note has no id until the server assigns one, and
      // both the uploads and the content save need it.
      final idResult = await _saveNoteMetadata(
        SaveNoteParams(
          folderId: folderId,
          title: title.isEmpty ? 'Untitled Note' : title,
          noteId: noteId,
        ),
      );
      if (idResult case Err(:final failure)) {
        AppSnackbar.failure('Failed to save note', failure);
        return;
      }
      noteId = idResult.valueOrNull!;

      final failedUploads = await _handleAttachmentUploads(noteId);

      final contentResult = await _saveNoteContent(
        SaveNoteContentParams(
          noteId: noteId,
          title: title,
          content: blocks.toList(),
        ),
      );
      if (contentResult case Err(:final failure)) {
        AppSnackbar.failure('Failed to save note', failure);
        return;
      }

      // BUG FIX: this used to re-fetch the whole note here, which disposed
      // every quill/text controller and replaced `blocks` with whatever the
      // server had — silently discarding anything typed during this save's
      // (multi-request) network round-trip. We already have everything a
      // re-fetch would provide: the real id came back from the metadata
      // save above, and _handleAttachmentUploads already patches attachment
      // urls/ids into `blocks` in place — so just carry those forward
      // locally instead of clobbering live edits.
      final previous = currentNote.value;
      currentNote.value = Note(
        id: noteId,
        folderId: folderId,
        folderName: previous?.folderName ?? '',
        title: title.isEmpty ? 'Untitled Note' : title,
        content: blocks.toList(),
        isPinned: previous?.isPinned ?? false,
        isArchived: previous?.isArchived ?? false,
        isLocked: previous?.isLocked ?? false,
        updatedAt: DateTime.now(),
        attachmentCount: previous?.attachmentCount ?? 0,
      );

      if (failedUploads.isNotEmpty) {
        // Failed blocks remain in the live list with their durable local path
        // and will retry on the next save.
        blocks.refresh();
        AppSnackbar.warning(
          'Saved with an issue',
          failedUploads.length == 1
              ? 'Note saved, but 1 image could not be uploaded. Try saving again.'
              : 'Note saved, but ${failedUploads.length} images could not be uploaded. Try saving again.',
        );
      } else if (!silent) {
        AppSnackbar.success('Saved', 'Note saved');
      }
    } catch (e) {
      // Every other async flow in this file reports failures via
      // AppSnackbar; this one only had a `finally`, so an unexpected error
      // (e.g. a RangeError from a stale block index) used to propagate
      // unhandled — isSaving still got reset, so the UI looked idle/
      // successful while the note silently failed to save.
      debugPrint('[SAVE ERROR] $e');
      AppSnackbar.error('Error', 'Could not save note');
    } finally {
      isSaving.value = false;
    }
  }

  /// Used when leaving the editor (e.g. the back button): saves like
  /// [saveNote] normally would, except a brand-new, still-empty note
  /// (`id == 0`, no title, no real block content) is left alone instead of
  /// being persisted as an empty note.
  Future<void> saveAndExitIfNeeded() async {
    final isNewNote = (currentNote.value?.id ?? 0) == 0;
    if (isNewNote && !_hasNoteContent()) return;
    await saveNote(silent: true);
  }

  bool _hasNoteContent() {
    if (titleController.text.trim().isNotEmpty) return true;
    for (final block in blocks) {
      if (block is TextBlock) {
        final plainText =
            quillControllers[block.id]?.document.toPlainText() ?? block.text;
        if (plainText.trim().isNotEmpty) return true;
      } else {
        // Any non-text block (checklist, attachment, drawing, table) is
        // real content on its own.
        return true;
      }
    }
    return false;
  }

  /// Converts the global background points into a temporary image and adds it as a block
  Future<void> _flattenBackgroundDrawing() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // We use a large virtual canvas to capture the drawing detail
      final paint = ui.Paint()
        ..color = drawingColor.value
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round
        ..strokeWidth = drawingStrokeWidth.value
        ..isAntiAlias = true;

      // Draw all points
      for (int i = 0; i < backgroundPoints.length - 1; i++) {
        if (backgroundPoints[i] != null && backgroundPoints[i + 1] != null) {
          canvas.drawLine(
            backgroundPoints[i]!,
            backgroundPoints[i + 1]!,
            paint,
          );
        }
      }

      final picture = recorder.endRecording();
      // Use standard logical bounds (approximate screen size)
      final img = await picture.toImage(1000, 2000);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/bg_sketch_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(buffer);

      // Insert at the very top (index 0) so it stays "under" or "behind" other content blocks
      blocks.insert(
        0,
        AttachmentBlock(
          id: _generateId(),
          displayName: 'Background Sketch',
          localPath: path,
          attachmentId: 0,
        ),
      );

      // Clear the volatile points now that they are a persistent block
      backgroundPoints.clear();
      isDrawingMode.value = false;
      blocks.refresh();
    } catch (e) {
      debugPrint('[FLATTEN ERROR] $e');
    }
  }

  /// Uploads every not-yet-uploaded attachment, returning the ones that
  /// failed so the caller can keep them around and tell the user.
  Future<List<AttachmentBlock>> _handleAttachmentUploads(int noteId) async {
    bool stateChanged = false;
    final failed = <AttachmentBlock>[];
    // Snapshot which blocks need uploading before the loop starts: `blocks`
    // is live and user-editable (e.g. deleting a block) while an earlier
    // upload's `await` is in flight, so writing back through a captured
    // index afterward can land on the wrong block — or throw — once
    // positions have shifted underneath it. Re-resolving each block's
    // current index by id right before writing back keeps this safe.
    final pending = blocks
        .whereType<AttachmentBlock>()
        .where((b) => b.attachmentId == 0 && b.localPath != null)
        .toList();

    for (final block in pending) {
      final displayOrder = blocks.indexWhere((b) => b.id == block.id);
      final result = await _uploadAttachment(
        UploadAttachmentParams(
          noteId: noteId,
          filePath: block.localPath!,
          blockId: block.id,
          displayOrder: displayOrder < 0 ? 0 : displayOrder,
        ),
      );

      switch (result) {
        case Ok(:final value):
          // Guest-mode "uploads" have nowhere to go but this device, so the
          // repository hands back a real file it just copied into permanent
          // storage rather than a server URL. Treating that path as a URL
          // would send Image.network to a host that was never asked for it.
          final isLocalFile = File(value.filePath).existsSync();
          final originalPath = normalizeLocalPath(block.localPath);
          final uploadedLocalPath = isLocalFile
              ? normalizeLocalPath(value.filePath)
              : null;
          final uploaded = AttachmentBlock(
            id: block.id,
            attachmentId: value.attachmentId,
            displayName: block.displayName,
            // Resolve immediately rather than waiting for the next fetch —
            // otherwise the block briefly (or, if the raw path is
            // malformed, permanently) carries an unresolved server path
            // and the image renders as unavailable right after saving.
            url: isLocalFile
                ? null
                : (normalizeAttachmentUrl(value.filePath) ?? value.filePath),
            localPath: isLocalFile ? value.filePath : null,
          );
          final currentIndex = blocks.indexWhere((b) => b.id == block.id);
          if (currentIndex != -1) {
            blocks[currentIndex] = uploaded;
            stateChanged = true;
          }
          if (originalPath != null && originalPath != uploadedLocalPath) {
            _deleteFileAt(originalPath);
          }
        // Else: the block was deleted while its upload was in flight. The
        // upload still succeeded server-side, but there's nothing local
        // left to attach it to, so it's dropped rather than resurrected.
        case Err(:final failure):
          // Keep the local path so the block survives and can retry on the
          // next save rather than silently vanishing.
          failed.add(block);
          debugPrint('[UPLOAD] BlockId=${block.id}: ${failure.message}');
      }
    }
    if (stateChanged) blocks.refresh();
    return failed;
  }

  // --- MENU LOGIC ---

  void toggleSearch() {
    // The more-menu popup already closes itself before calling this (see
    // IOSActionMenu._buildMenuItem) — an extra Get.back() here used to pop
    // the note editor itself instead of just the menu.
    isSearchVisible.toggle();
    if (isSearchVisible.value) {
      Future.delayed(const Duration(milliseconds: 300), () {
        searchFocusNode.requestFocus();
      });
    } else {
      searchQuery.value = "";
    }
  }

  /// Hands the note's plain-text content to the OS share sheet (Messages,
  /// Mail, AirDrop, …) instead of the old dialog that just displayed the
  /// text on-screen with a "Close" button — that never actually shared
  /// anything anywhere.
  Future<void> shareNote() async {
    final context = Get.context;
    if (context == null) return;

    _syncBlocks();
    final title = titleController.text.trim();
    final buffer = StringBuffer(title.isEmpty ? 'Untitled Note' : title)
      ..write('\n\n');
    for (final b in blocks) {
      if (b is TextBlock) buffer.write('${NoteSnippet.plainText(b.text)}\n');
    }

    // Anchors the share popover on iPad/macOS; harmless elsewhere.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    try {
      await Share.share(
        buffer.toString().trim(),
        subject: title.isEmpty ? 'Untitled Note' : title,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('[SHARE ERROR] $e');
      AppSnackbar.error('Error', 'Could not open the share sheet');
    }
  }

  /// Where a note with no folder of its own lives — same fallback
  /// [NoteEditorHeader] shows on-screen, so an unfiled or not-yet-saved
  /// note (e.g. one still open on the Create Note screen) doesn't read as
  /// having no folder at all.
  static String get _defaultFolderName => 'note_editor_default_folder_name'.tr;

  /// The folder line exactly as [NoteEditorHeader] resolves and shows it:
  /// prefer the live [Folder] record (its `displayName` already strips the
  /// iCloud/Shared section keyword the API bakes into raw names), fall back
  /// to the note's own `folderName`, and finally to [_defaultFolderName].
  /// Both the on-screen header and [exportNoteToPdf] call this — keeping it
  /// in one place means the PDF can't quietly drift from what's shown while
  /// editing, which is exactly what happened before this existed: the export
  /// used to read only `currentNote.value?.folderName`, which is empty for a
  /// brand-new note, so the PDF's folder line was silently blank for any
  /// note exported before its first save.
  String resolveFolderLabel() {
    final note = currentNote.value;
    final folder = resolveFolder(note?.folderId ?? 0);
    final resolved = folder?.displayName ?? '';
    if (resolved.isNotEmpty) return resolved;
    final fromNote = note?.folderName.trim() ?? '';
    if (fromNote.isNotEmpty) return FolderAppearance.displayName(fromNote);
    return _defaultFolderName;
  }

  /// The live [Folder] record for [folderId], or `null` when there isn't
  /// one to draw from — an unfiled note, or a folder list that hasn't been
  /// loaded in this session. [NoteEditorHeader] uses this directly for the
  /// folder glyph; [resolveFolderLabel] uses it for the name.
  Folder? resolveFolder(int folderId) {
    if (folderId == 0 || !Get.isRegistered<FolderController>()) return null;
    return _findFolder(Get.find<FolderController>().folders, folderId);
  }

  Folder? _findFolder(List<Folder> folders, int id) {
    for (final folder in folders) {
      if (folder.id == id) return folder;
      final nested = _findFolder(folder.subFolders, id);
      if (nested != null) return nested;
    }
    return null;
  }

  /// "Export as PDF" — the whole note (folder name, title, timestamp, and
  /// every block in reading order: text, checklists, tables, images,
  /// drawings) as one printable document, handed to the OS share sheet.
  /// Distinct from [convertAttachmentToPdf], which turns a single picture
  /// attachment into its own PDF — this exports the note itself.
  Future<void> exportNoteToPdf() async {
    _syncBlocks();
    final title = titleController.text.trim();
    final folderName = resolveFolderLabel();
    final noteDate = currentNote.value?.updatedAt ?? DateTime.now();

    try {
      // Every image/drawing needs a local file before the PDF builder can
      // embed it — download whatever's remote-only first so building the
      // document itself never has to touch the network.
      final resolvedImagePaths = <String, String>{};
      for (final block in blocks) {
        String? localPath;
        String? remoteUrl;
        switch (block) {
          case AttachmentBlock(:final displayName):
            if (!_looksLikeImageName(displayName)) continue;
            localPath = normalizeLocalPath(block.localPath);
            remoteUrl = normalizeAttachmentUrl(block.url);
          case DrawingBlock():
            localPath = normalizeLocalPath(block.localPath);
            remoteUrl = normalizeAttachmentUrl(block.url);
          default:
            continue;
        }

        if (localPath != null && File(localPath).existsSync()) {
          resolvedImagePaths[block.id] = localPath;
        } else if (remoteUrl != null) {
          final cached = await cacheAttachmentForEditing(remoteUrl);
          if (cached != null) resolvedImagePaths[block.id] = cached;
        }
      }

      final path = await buildNotePdf(
        folderName: folderName,
        title: title.isEmpty ? 'Untitled Note' : title,
        date: noteDate,
        blocks: blocks.toList(),
        resolvedImagePaths: resolvedImagePaths,
      );

      // Required, not just for iPad/Mac's popover: some share_plus/iOS
      // combinations reject shareXFiles outright with "sharePositionOrigin:
      // argument must be set" when it's omitted, even on iPhone — see
      // shareNote's identical anchor computation just above.
      final context = Get.context;
      final box = context?.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await Share.shareXFiles([XFile(path)], sharePositionOrigin: origin);
    } catch (e) {
      debugPrint('[EXPORT PDF ERROR] $e');
      AppSnackbar.error('Error', 'Could not export this note as a PDF');
    }
  }

  /// Same extension set [note_attachment_block.dart] uses to decide an
  /// attachment renders as a picture rather than a generic file tile — an
  /// image attachment is worth resolving to a local file for the PDF export;
  /// anything else (a document, an audio recording) is exported as a named
  /// placeholder line instead.
  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'heic',
    'heif',
    'webp',
    'bmp',
  };

  bool _looksLikeImageName(String name) {
    final trimmed = name.trim();
    if (!trimmed.contains('.')) return false;
    return _imageExtensions.contains(trimmed.split('.').last.toLowerCase());
  }

  /// Undoes the last edit in whichever text block currently has focus, using
  /// each block's own Quill edit history. Title changes and non-text blocks
  /// (checklists, tables, attachments) aren't tracked by this — there's no
  /// edit history to undo them from.
  void undo() {
    final index = activeBlockIndex.value;
    if (index < 0 || index >= blocks.length) {
      AppSnackbar.info('Nothing to undo', 'Tap into some text first.');
      return;
    }
    final block = blocks[index];
    if (block is! TextBlock) {
      AppSnackbar.info('Nothing to undo', 'This block has no text history.');
      return;
    }
    final qc = quillControllers[block.id];
    if (qc == null || !qc.hasUndo) {
      AppSnackbar.info('Nothing to undo', '');
      return;
    }
    // Undoing a block down to its last character empties it the same way a
    // real Backspace would, and both report as ChangeSource.local — nothing
    // in the change itself says "this was Undo." Suppressing the block-
    // deletion listener for this one call is what keeps Undo reverting only
    // the text edit instead of also removing the block and moving focus.
    _suppressEmptiedCheck = true;
    qc.undo();
    _suppressEmptiedCheck = false;
  }

  Future<void> togglePin() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0) return;

    // The more-menu popup already closes itself before calling this — see
    // toggleSearch()'s note above.
    final newState = !isPinned.value;
    final result = await _updateNoteState(
      UpdateNoteStateParams(noteId: id, isPinned: newState),
    );

    switch (result) {
      case Ok():
        isPinned.value = newState;
        _refreshNoteList();
      case Err(:final failure):
        AppSnackbar.failure('Could not update pin state', failure);
    }
  }

  Future<void> toggleArchive() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0) return;

    // The more-menu popup already closes itself before calling this — see
    // toggleSearch()'s note above.
    final newState = !isArchived.value;
    final result = await _updateNoteState(
      UpdateNoteStateParams(noteId: id, isArchived: newState),
    );

    switch (result) {
      case Ok():
        isArchived.value = newState;
        _refreshNoteList();
        // An archived note no longer belongs in this list, so leave the editor.
        if (newState) Get.back(result: true);
      case Err(:final failure):
        AppSnackbar.failure('Could not update archive state', failure);
    }
  }

  Future<void> toggleLock() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0) return;

    // The more-menu popup already closes itself before calling this — see
    // toggleSearch()'s note above.
    final newState = !isLocked.value;
    final result = await _updateNoteState(
      UpdateNoteStateParams(noteId: id, isLocked: newState),
    );

    switch (result) {
      case Ok():
        isLocked.value = newState;
      case Err(:final failure):
        AppSnackbar.failure('Could not update lock state', failure);
    }
  }

  void _refreshNoteList() {
    if (Get.isRegistered<NoteController>()) {
      Get.find<NoteController>().fetchNotes(refresh: true);
    }
  }

  Future<void> deleteNote() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0 || isSaving.value) return;

    // Logic: Immediately unfocus and hide keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    // FEATURE Logic: Wipe all local state to "Clean screen" immediately
    // This ensures that even if navigation is slow, the user sees an empty screen
    blocks.clear();
    titleController.clear();
    final deletedNoteId = id;
    currentNote.value = null;

    final result = await _deleteRestoreNote(
      DeleteRestoreNoteParams(noteId: deletedNoteId, isDelete: true),
    );

    if (result case Err(:final failure)) {
      AppSnackbar.failure('Could not delete note', failure);
      // The screen was already cleared optimistically, so restore it.
      await fetchNoteDetail(deletedNoteId);
      return;
    }

    // Trash counts live on the folder screen and go stale otherwise.
    if (Get.isRegistered<FolderController>()) {
      unawaited(Get.find<FolderController>().fetchFolders(refresh: true));
    }

    // Optimistic cleanup so the list behind us is already correct.
    if (Get.isRegistered<NoteController>()) {
      final nc = Get.find<NoteController>();
      nc.notes.removeWhere((n) => n.id == deletedNoteId);
      nc.pinnedNotes.removeWhere((n) => n.id == deletedNoteId);
      nc.otherNotes.removeWhere((n) => n.id == deletedNoteId);
      unawaited(nc.fetchNotes(refresh: true));
    }

    // Land exactly on the list or folder screen — more robust than stacking
    // Get.back() calls, which can pop too far when a menu is still open.
    Get.until(
      (route) =>
          route.settings.name == Routes.NOTE_LIST ||
          route.settings.name == Routes.FOLDER ||
          route.isFirst,
    );

    AppSnackbar.success('Deleted', 'Note moved to Recently Deleted');
  }

  Future<void> moveNote() async {
    // No Get.back() here: the more-menu popup already closes itself before
    // calling this (see toggleSearch()'s note above), and this is also
    // called directly by tapping the folder label in the editor, which
    // never had a menu to close in the first place.
    if (isLoading.value ||
        isSaving.value ||
        isReadOnly.value ||
        currentNote.value == null) {
      return;
    }
    await _openFolderPicker();
  }

  Future<void> _openFolderPicker() async {
    final sourceNote = currentNote.value;
    if (sourceNote == null) return;

    final foldersResult = await _getFolders(const NoParams());
    if (foldersResult case Err(:final failure)) {
      AppSnackbar.failure('note_editor_load_folders_failed_title'.tr, failure);
      return;
    }

    final folders = foldersResult.valueOrNull!.folders;
    if (folders.isEmpty) {
      AppSnackbar.info(
        'note_editor_no_destination_title'.tr,
        'note_editor_no_destination_message'.tr,
      );
      return;
    }

    await Get.to(
      () => NoteMoveFolderModal(
        folders: folders,
        currentFolderId: sourceNote.folderId,
        onFolderSelected: (targetFolder) async {
          Get.back();
          final note = currentNote.value;
          if (note == null || note.folderId == targetFolder.id) return;

          // A new note does not have a server id yet. Changing its folder is
          // therefore a local draft update; the regular first-save flow will
          // persist the selected folder together with the note. Sending id 0
          // through the move endpoint would create metadata prematurely and
          // then try to fetch a note that still has id 0.
          if (note.id == 0) {
            currentNote.value = Note(
              id: note.id,
              folderId: targetFolder.id,
              folderName: targetFolder.displayName,
              title: note.title,
              content: note.content,
              isPinned: note.isPinned,
              isArchived: note.isArchived,
              isLocked: note.isLocked,
              updatedAt: note.updatedAt,
              deletedAt: note.deletedAt,
              attachmentCount: note.attachmentCount,
              isDeleteFlag: note.isDeleteFlag,
            );
            AppSnackbar.success(
              'note_editor_folder_updated_title'.tr,
              'note_editor_folder_updated_message'.trParams({
                'folder': targetFolder.displayName,
              }),
            );
            return;
          }

          isLoading.value = true;
          try {
            final result = await _saveNoteMetadata(
              SaveNoteParams(
                folderId: targetFolder.id,
                title: titleController.text,
                noteId: note.id,
              ),
            );
            switch (result) {
              case Ok():
                await fetchNoteDetail(note.id);
                _refreshNoteList();
                AppSnackbar.success(
                  'note_editor_move_success_title'.tr,
                  'note_editor_move_success_message'.trParams({
                    'folder': targetFolder.displayName,
                  }),
                );
              case Err(:final failure):
                AppSnackbar.failure(
                  'note_editor_move_failed_title'.tr,
                  failure,
                );
            }
          } finally {
            isLoading.value = false;
          }
        },
        onCreateNewFolder: () async {
          // Waits for FolderCreateModal to pop back here (rather than all
          // the way out to the main Folder screen), then reopens the picker
          // so the folder just created shows up as a destination.
          await Get.to(
            () => FolderCreateModal(
              controller: Get.find<FolderController>(),
              onDone: () => Get.back(),
            ),
            fullscreenDialog: true,
            transition: Transition.cupertino,
          );
          Get.back(); // Close the now-stale picker
          await _openFolderPicker();
        },
      ),
      fullscreenDialog: true,
      transition: Transition.cupertino,
    );
  }

  void _clearControllers() {
    for (var c in quillControllers.values) {
      c.dispose();
    }
    quillControllers.clear();
    _lastTextBlockLength.clear();
    for (var c in textControllers.values) {
      c.dispose();
    }
    textControllers.clear();
    for (var f in blockFocusNodes.values) {
      f.dispose();
    }
    blockFocusNodes.clear();
  }

  @override
  void onClose() {
    titleController.dispose();
    titleFocusNode.dispose();
    _clearControllers();
    searchFocusNode.dispose();
    super.onClose();
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}
