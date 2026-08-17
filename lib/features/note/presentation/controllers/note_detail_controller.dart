import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:ios_image_editor/ios_image_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_move_folder_modal.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';
import 'package:Note/core/utils/note_snippet.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/entities/note.dart';

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
  final blocks = <NoteBlock>[].obs;
  final Map<String, quill.QuillController> quillControllers = {};
  final Map<String, TextEditingController> textControllers = {};

  // --- State ---
  final activeBlockIndex = (-1).obs;
  final currentBlockStyle = "body".obs;
  final isSearchVisible = false.obs;
  final searchQuery = "".obs;
  final searchFocusNode = FocusNode();
  final isFormatPanelVisible = false.obs;

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

  void _handleArguments(dynamic args) {
    if (args is Map) {
      final noteId = args['noteId'];
      final folderId = args['folderId'];
      isReadOnly.value = args['isDeleted'] == true;

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

    if (blocks.isEmpty && !isReadOnly.value) {
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
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    });
  }

  TextEditingController getTextController(String key, String initialValue) {
    return textControllers.putIfAbsent(
      key,
      () => TextEditingController(text: initialValue),
    );
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
        // 4. Add as a new attachment block and refresh
        _insertBlock(
          AttachmentBlock(
            id: _generateId(),
            displayName: 'Sketch',
            localPath: editedPath,
            attachmentId: 0,
          ),
        );
        blocks.refresh();
        addTextBlock();
        saveNote();
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

      _insertBlock(
        AttachmentBlock(
          id: _generateId(),
          displayName: file.name,
          localPath: file.path,
          attachmentId: 0,
        ),
      );
      blocks.refresh();
      addTextBlock();
    } catch (e) {
      debugPrint('[CAMERA ERROR] $e');
      AppSnackbar.error(
        'Error',
        'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}',
      );
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

  void updateAttachmentImage(int blockIndex, String editedPath) {
    if (isReadOnly.value || blockIndex < 0 || blockIndex >= blocks.length)
      return;
    final block = blocks[blockIndex];
    if (block is! AttachmentBlock) return;

    blocks[blockIndex] = AttachmentBlock(
      id: block.id,
      attachmentId: 0,
      displayName: 'Edited Image',
      localPath: editedPath,
      url: block.url,
    );
    blocks.refresh();
    saveNote();
  }

  void updateDrawing(int blockIndex, String path) {
    if (isReadOnly.value || blockIndex < 0 || blockIndex >= blocks.length)
      return;
    blocks[blockIndex] = DrawingBlock(
      id: blocks[blockIndex].id,
      localPath: path,
    );
    blocks.refresh();
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
    blocks.removeAt(index);
    blocks.refresh();
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

  Future<void> saveNote() async {
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

      await _handleAttachmentUploads(noteId);

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

      // Re-fetch so server-assigned ids and attachment URLs land locally.
      await fetchNoteDetail(noteId);
      AppSnackbar.success('Saved', 'Note saved');
    } finally {
      isSaving.value = false;
    }
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

  Future<void> _handleAttachmentUploads(int noteId) async {
    bool stateChanged = false;
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block is AttachmentBlock &&
          block.attachmentId == 0 &&
          block.localPath != null) {
        final result = await _uploadAttachment(
          UploadAttachmentParams(
            noteId: noteId,
            filePath: block.localPath!,
            blockId: block.id,
            displayOrder: i,
          ),
        );

        switch (result) {
          case Ok(:final value):
            blocks[i] = AttachmentBlock(
              id: block.id,
              attachmentId: value.attachmentId,
              displayName: block.displayName,
              url: value.filePath,
              localPath: null,
            );
            stateChanged = true;
          case Err(:final failure):
            // Keep the local path so the block survives and can retry on the
            // next save rather than silently vanishing.
            debugPrint('[UPLOAD] BlockId=${block.id}: ${failure.message}');
        }
      }
    }
    if (stateChanged) blocks.refresh();
  }

  // --- MENU LOGIC ---

  void toggleSearch() {
    Get.back(); // Close More menu
    isSearchVisible.toggle();
    if (isSearchVisible.value) {
      Future.delayed(const Duration(milliseconds: 300), () {
        searchFocusNode.requestFocus();
      });
    } else {
      searchQuery.value = "";
    }
  }

  void shareNote() {
    final context = Get.context;
    if (context == null) return;

    _syncBlocks();
    String content = titleController.text + "\n\n";
    for (var b in blocks) {
      if (b is TextBlock) content += NoteSnippet.plainText(b.text) + "\n";
    }
    CustomGlassDialog.show<void>(
      context: context,
      title: 'Share Note',
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: SingleChildScrollView(child: Text(content)),
      ),
      actions: const [
        CustomGlassDialogAction(label: 'Close', onPressed: _noOp),
      ],
    );
  }

  void undo() => AppSnackbar.info('Undo', 'Undo feature is coming soon');

  Future<void> togglePin() async {
    final id = currentNote.value?.id ?? 0;
    if (id == 0) return;

    Get.back(); // Close menu
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

    Get.back(); // Close menu
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

    Get.back(); // Close menu
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
      Get.find<FolderController>().fetchFolders(refresh: true);
    }

    // Optimistic cleanup so the list behind us is already correct.
    if (Get.isRegistered<NoteController>()) {
      final nc = Get.find<NoteController>();
      nc.notes.removeWhere((n) => n.id == deletedNoteId);
      nc.pinnedNotes.removeWhere((n) => n.id == deletedNoteId);
      nc.otherNotes.removeWhere((n) => n.id == deletedNoteId);
      nc.fetchNotes(refresh: true);
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
    Get.back(); // Close menu
    if (isLoading.value || currentNote.value == null) return;

    final foldersResult = await _getFolders(const NoParams());
    if (foldersResult case Err(:final failure)) {
      AppSnackbar.failure('Could not load folders', failure);
      return;
    }

    final folders = foldersResult.valueOrNull!.folders;
    if (folders.isEmpty) {
      AppSnackbar.info('No destination', 'Create another folder first.');
      return;
    }

    Get.to(
      () => NoteMoveFolderModal(
        folders: folders,
        currentFolderId: currentNote.value!.folderId,
        onFolderSelected: (targetFolder) async {
          Get.back(); // Pop modal
          isLoading.value = true;
          try {
            final result = await _saveNoteMetadata(
              SaveNoteParams(
                folderId: targetFolder.id,
                title: titleController.text,
                noteId: currentNote.value!.id,
              ),
            );
            switch (result) {
              case Ok():
                await fetchNoteDetail(currentNote.value!.id);
                _refreshNoteList();
                AppSnackbar.success('Moved', 'Moved to ${targetFolder.name}');
              case Err(:final failure):
                AppSnackbar.failure('Could not move note', failure);
            }
          } finally {
            isLoading.value = false;
          }
        },
      ),
      fullscreenDialog: true,
      transition: Transition.cupertino,
    );
  }

  void _clearControllers() {
    for (var c in quillControllers.values) c.dispose();
    quillControllers.clear();
    for (var c in textControllers.values) c.dispose();
    textControllers.clear();
  }

  @override
  void onClose() {
    titleController.dispose();
    _clearControllers();
    searchFocusNode.dispose();
    super.onClose();
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}

void _noOp() {}
