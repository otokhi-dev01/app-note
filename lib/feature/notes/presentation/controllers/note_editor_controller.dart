import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/repositories/note_state_field.dart';
import 'home_controller.dart';

class NoteChecklistItemDraft {
  final String id;
  final Map<String, dynamic> original;
  String text;
  bool checked;

  NoteChecklistItemDraft({
    required this.id,
    required this.text,
    required this.checked,
    required this.original,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...original,
      'id': id,
      'text': text.trim(),
      'checked': checked,
    };
  }
}

class NoteChecklistBlockDraft {
  final String id;
  final Map<String, dynamic> original;
  final List<NoteChecklistItemDraft> items;

  NoteChecklistBlockDraft({
    required this.id,
    required this.original,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    final String blockId =
        original['blockId']?.toString().trim().isNotEmpty == true
        ? original['blockId'].toString()
        : id;

    return <String, dynamic>{
      ...original,
      'id': id,
      'blockId': blockId,
      'type': 'checklist',
      'items': items
          .where((NoteChecklistItemDraft item) {
            return item.text.trim().isNotEmpty;
          })
          .map((NoteChecklistItemDraft item) => item.toJson())
          .toList(growable: false),
    };
  }
}

class NoteEditorController extends GetxController {
  final NoteRepository noteRepository;
  final HomeController? homeController;
  final int? initialNoteId;

  NoteEditorController({
    required this.noteRepository,
    this.homeController,
    this.initialNoteId,
  });

  final TextEditingController titleController = TextEditingController();

  final TextEditingController statementController = TextEditingController();

  final Rxn<NoteEntity> note = Rxn<NoteEntity>();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  final RxString errorMessage = ''.obs;

  final RxList<NoteChecklistBlockDraft> checklistBlocks =
      <NoteChecklistBlockDraft>[].obs;

  final Uuid _uuid = const Uuid();

  int? _noteId;
  int _detailLoadGeneration = 0;

  int get noteId {
    final int? value = _noteId;

    if (value == null) {
      throw StateError('A valid note ID was not provided.');
    }

    return value;
  }

  bool get hasLoadedNote {
    final NoteEntity? currentNote = note.value;

    return _noteId != null && currentNote != null && currentNote.id == _noteId;
  }

  bool get isLocked {
    return note.value?.isLocked ?? false;
  }

  bool get canEdit {
    return hasLoadedNote && !isLocked && !isSaving.value;
  }

  List<Map<String, dynamic>> get attachmentBlocks {
    final List<Map<String, dynamic>> result =
        note.value?.content
            .where((Map<String, dynamic> block) {
              return _blockType(block) == 'attachment';
            })
            .map((Map<String, dynamic> block) {
              return Map<String, dynamic>.from(block);
            })
            .toList(growable: false) ??
        <Map<String, dynamic>>[];

    result.sort((Map<String, dynamic> first, Map<String, dynamic> second) {
      return _toInt(
        first['displayOrder'],
      ).compareTo(_toInt(second['displayOrder']));
    });

    return result;
  }

  @override
  void onInit() {
    super.onInit();

    _noteId = _readNoteId();

    if (_noteId == null) {
      errorMessage.value = 'A valid note ID was not provided.';
      return;
    }

    /*
     * GET NOTE DETAIL METHOD IS CALLED HERE.
     */
    getNoteDetail();
  }

  int? _readNoteId() {
    final int? providedId = _parsePositiveId(initialNoteId);

    if (providedId != null) {
      return providedId;
    }

    final dynamic arguments = Get.arguments;

    /*
     * Supports:
     *
     * Get.toNamed(
     *   AppRoutes.noteEditor,
     *   arguments: 10,
     * );
     */
    final int? directId = _parsePositiveId(arguments);

    if (directId != null) {
      return directId;
    }

    /*
     * Supports:
     *
     * Get.toNamed(
     *   AppRoutes.noteEditor,
     *   arguments: {
     *     'noteId': 10,
     *   },
     * );
     */
    if (arguments is Map) {
      final int? argumentId = _parsePositiveId(
        arguments['noteId'] ??
            arguments['NoteId'] ??
            arguments['id'] ??
            arguments['Id'],
      );

      if (argumentId != null) {
        return argumentId;
      }
    }

    return _parsePositiveId(Get.parameters['noteId'] ?? Get.parameters['id']);
  }

  int? _parsePositiveId(dynamic value) {
    final int? parsedId = value is num
        ? value.toInt()
        : int.tryParse(value?.toString().trim() ?? '');

    return parsedId != null && parsedId > 0 ? parsedId : null;
  }

  /*
   * This method loads:
   *
   * GET /api/note/{id}
   */
  Future<void> getNoteDetail() async {
    await _loadNoteDetail();
  }

  Future<bool> _loadNoteDetail() async {
    final int? requestedNoteId = _noteId;

    if (requestedNoteId == null) {
      errorMessage.value = 'A valid note ID was not provided.';
      return false;
    }

    final int loadGeneration = ++_detailLoadGeneration;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final NoteEntity result = await noteRepository.getNoteDetail(
        requestedNoteId,
      );

      if (loadGeneration != _detailLoadGeneration) {
        return false;
      }

      if (result.id != requestedNoteId) {
        throw StateError(
          'The API returned note ${result.id} instead of '
          'the requested note $requestedNoteId.',
        );
      }

      note.value = result;

      titleController.text = result.title;

      statementController.text = _extractTextContent(result.content);

      _loadChecklistBlocks(result.content);

      return true;
    } catch (error) {
      if (loadGeneration == _detailLoadGeneration) {
        errorMessage.value = _cleanError(error);
      }

      return false;
    } finally {
      if (loadGeneration == _detailLoadGeneration) {
        isLoading.value = false;
      }
    }
  }

  /*
   * Refresh method for pull-to-refresh or retry.
   */
  Future<void> reloadNote() {
    return getNoteDetail();
  }

  /*
   * Save edited title and statement.
   *
   * Existing attachment blocks are preserved.
   */
  Future<void> saveChanges() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final int? requestedNoteId = _noteId;

    if (requestedNoteId == null || !hasLoadedNote) {
      errorMessage.value = 'Load the requested note before saving changes.';
      return;
    }

    if (isLocked) {
      errorMessage.value = 'Unlock this note before editing it.';
      return;
    }

    final String title = titleController.text.trim();

    final String statement = statementController.text.trim();

    if (title.isEmpty) {
      errorMessage.value = 'Please enter a note title.';
      return;
    }

    if (title.length > 250) {
      errorMessage.value = 'The note title cannot exceed 250 characters.';
      return;
    }

    try {
      isSaving.value = true;
      errorMessage.value = '';

      final List<Map<String, dynamic>> updatedContent = _buildUpdatedContent(
        statement: statement,
      );

      await noteRepository.saveContent(
        id: requestedNoteId,
        title: title,
        content: updatedContent,
      );

      final NoteEntity current = note.value!;
      note.value = current.copyWith(
        title: title,
        content: updatedContent,
        attachmentCount: updatedContent.where((Map<String, dynamic> block) {
          return _blockType(block) == 'attachment';
        }).length,
        updatedAt: DateTime.now(),
      );

      /*
       * Reload from the server after saving.
       */
      await _loadNoteDetail();

      if (homeController != null) {
        await homeController!.loadAll();
      }

      if (!Get.testMode && Get.context != null) {
        Get.snackbar(
          'Note saved',
          'Your changes were saved successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error) {
      errorMessage.value = _cleanError(error);
    } finally {
      isSaving.value = false;
    }
  }

  List<Map<String, dynamic>> _buildUpdatedContent({required String statement}) {
    final List<Map<String, dynamic>> originalContent =
        note.value?.content.map((Map<String, dynamic> block) {
          return Map<String, dynamic>.from(block);
        }).toList() ??
        <Map<String, dynamic>>[];

    /*
     * Find the old text block so its ID can remain stable.
     */
    Map<String, dynamic>? oldTextBlock;

    for (final Map<String, dynamic> block in originalContent) {
      final String type = block['type']?.toString().trim().toLowerCase() ?? '';

      if (type == 'text') {
        oldTextBlock = block;
        break;
      }
    }

    /* Keep attachment and unknown blocks unchanged. Checklist blocks are
     * rebuilt from the editable drafts below. */
    final List<Map<String, dynamic>> preservedBlocks = originalContent
        .where((Map<String, dynamic> block) {
          final String type = _blockType(block);

          return type != 'text' && type != 'checklist';
        })
        .map((Map<String, dynamic> block) {
          return Map<String, dynamic>.from(block);
        })
        .toList();

    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];

    if (statement.isNotEmpty) {
      final String textBlockId =
          oldTextBlock?['id']?.toString() ?? 'text-$noteId';

      final String blockId =
          oldTextBlock?['blockId']?.toString() ?? textBlockId;

      result.add(<String, dynamic>{
        ...?oldTextBlock,
        'id': textBlockId,
        'blockId': blockId,
        'type': 'text',
        'text': statement,
        'displayOrder': 1,
      });
    }

    for (final NoteChecklistBlockDraft block in checklistBlocks) {
      final Map<String, dynamic> checklist = block.toJson();
      final dynamic items = checklist['items'];

      if (items is List && items.isNotEmpty) {
        result.add(checklist);
      }
    }

    result.addAll(preservedBlocks);

    /*
     * Reassign display order after updating content.
     */
    for (int index = 0; index < result.length; index++) {
      result[index]['displayOrder'] = index + 1;
    }

    return result;
  }

  void addChecklistItem() {
    if (!canEdit) {
      return;
    }

    NoteChecklistBlockDraft block;

    if (checklistBlocks.isEmpty) {
      block = NoteChecklistBlockDraft(
        id: _uuid.v4(),
        original: <String, dynamic>{},
        items: <NoteChecklistItemDraft>[],
      );
      checklistBlocks.add(block);
    } else {
      block = checklistBlocks.first;
    }

    block.items.add(
      NoteChecklistItemDraft(
        id: _uuid.v4(),
        text: '',
        checked: false,
        original: <String, dynamic>{},
      ),
    );
    checklistBlocks.refresh();
  }

  void updateChecklistItem(String blockId, String itemId, String text) {
    if (!canEdit) {
      return;
    }

    final NoteChecklistItemDraft? item = _findChecklistItem(blockId, itemId);

    if (item != null) {
      item.text = text;
    }
  }

  void toggleChecklistItem(String blockId, String itemId, bool checked) {
    if (!canEdit) {
      return;
    }

    final NoteChecklistItemDraft? item = _findChecklistItem(blockId, itemId);

    if (item != null) {
      item.checked = checked;
      checklistBlocks.refresh();
    }
  }

  void removeChecklistItem(String blockId, String itemId) {
    if (!canEdit) {
      return;
    }

    final int blockIndex = checklistBlocks.indexWhere(
      (NoteChecklistBlockDraft block) => block.id == blockId,
    );

    if (blockIndex < 0) {
      return;
    }

    final NoteChecklistBlockDraft block = checklistBlocks[blockIndex];

    block.items.removeWhere((NoteChecklistItemDraft item) => item.id == itemId);

    if (block.items.isEmpty) {
      checklistBlocks.removeAt(blockIndex);
    } else {
      checklistBlocks.refresh();
    }
  }

  Future<bool> uploadAttachment({required String filePath}) async {
    if (!canEdit || filePath.trim().isEmpty) {
      return false;
    }

    final String title = titleController.text.trim();

    if (title.isEmpty) {
      errorMessage.value = 'Please enter a note title.';
      return false;
    }

    try {
      isSaving.value = true;
      errorMessage.value = '';

      final List<Map<String, dynamic>> content = _buildUpdatedContent(
        statement: statementController.text.trim(),
      );

      await noteRepository.saveContent(
        id: noteId,
        title: title,
        content: content,
      );

      final NoteEntity current = note.value!;
      note.value = current.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );

      final String blockId = _uuid.v4();

      await noteRepository.uploadAttachment(
        noteId: noteId,
        filePath: filePath.trim(),
        blockId: blockId,
        displayOrder: content.length + 1,
      );

      final List<Map<String, dynamic>> optimisticContent =
          <Map<String, dynamic>>[
            ...content.map(Map<String, dynamic>.from),
            <String, dynamic>{
              'id': blockId,
              'blockId': blockId,
              'type': 'attachment',
              'displayName': _fileNameFromPath(filePath.trim()),
              'filePath': filePath.trim(),
              'displayOrder': content.length + 1,
            },
          ];
      note.value = note.value!.copyWith(
        content: optimisticContent,
        attachmentCount: optimisticContent.where((Map<String, dynamic> block) {
          return _blockType(block) == 'attachment';
        }).length,
        updatedAt: DateTime.now(),
      );

      await _loadNoteDetail();

      if (homeController != null) {
        await homeController!.loadAll();
      }

      if (!Get.testMode && Get.context != null) {
        Get.snackbar(
          'Attachment uploaded',
          'The file was added to your note.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return true;
    } catch (error) {
      errorMessage.value = _cleanError(error);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> togglePin() {
    final NoteEntity? current = note.value;

    return _updateState(
      isPinned: !(current?.isPinned ?? false),
      isArchived: current?.isArchived ?? false,
      isLocked: current?.isLocked ?? false,
      changedField: NoteStateField.pinned,
    );
  }

  Future<void> toggleArchive() {
    final NoteEntity? current = note.value;

    return _updateState(
      isPinned: current?.isPinned ?? false,
      isArchived: !(current?.isArchived ?? false),
      isLocked: current?.isLocked ?? false,
      changedField: NoteStateField.archived,
    );
  }

  Future<void> toggleLock() {
    final NoteEntity? current = note.value;

    return _updateState(
      isPinned: current?.isPinned ?? false,
      isArchived: current?.isArchived ?? false,
      isLocked: !(current?.isLocked ?? false),
      changedField: NoteStateField.locked,
    );
  }

  Future<void> _updateState({
    required bool isPinned,
    required bool isArchived,
    required bool isLocked,
    required NoteStateField changedField,
  }) async {
    if (!hasLoadedNote || isSaving.value) {
      return;
    }

    try {
      isSaving.value = true;
      errorMessage.value = '';

      await noteRepository.updateState(
        noteId: noteId,
        isPinned: isPinned,
        isArchived: isArchived,
        isLocked: isLocked,
        changedField: changedField,
      );

      final NoteEntity current = note.value!;
      note.value = current.copyWith(
        isPinned: isPinned,
        isArchived: isArchived,
        isLocked: isLocked,
        pinnedAt: isPinned ? current.pinnedAt ?? DateTime.now() : null,
        clearPinnedAt: !isPinned,
        updatedAt: DateTime.now(),
      );

      await _loadNoteDetail();

      if (homeController != null) {
        await homeController!.loadAll();
      }
    } catch (error) {
      errorMessage.value = _cleanError(error);
    } finally {
      isSaving.value = false;
    }
  }

  void _loadChecklistBlocks(List<Map<String, dynamic>> content) {
    final List<NoteChecklistBlockDraft> result = <NoteChecklistBlockDraft>[];

    for (final Map<String, dynamic> block in content) {
      if (_blockType(block) != 'checklist') {
        continue;
      }

      final dynamic rawBlockId = block['id'] ?? block['blockId'];
      final String blockId = rawBlockId?.toString().trim().isNotEmpty == true
          ? rawBlockId.toString()
          : _uuid.v4();
      final List<NoteChecklistItemDraft> items = <NoteChecklistItemDraft>[];
      final dynamic rawItems = block['items'];

      if (rawItems is List) {
        for (final dynamic rawItem in rawItems) {
          if (rawItem is! Map) {
            continue;
          }

          final Map<String, dynamic> item = rawItem.map((
            dynamic key,
            dynamic value,
          ) {
            return MapEntry<String, dynamic>(key.toString(), value);
          });
          final dynamic rawItemId = item['id'] ?? item['itemId'];
          final String itemId = rawItemId?.toString().trim().isNotEmpty == true
              ? rawItemId.toString()
              : _uuid.v4();

          items.add(
            NoteChecklistItemDraft(
              id: itemId,
              text: item['text']?.toString() ?? '',
              checked: _toBool(item['checked']),
              original: item,
            ),
          );
        }
      }

      result.add(
        NoteChecklistBlockDraft(
          id: blockId,
          original: Map<String, dynamic>.from(block),
          items: items,
        ),
      );
    }

    checklistBlocks.assignAll(result);
  }

  NoteChecklistItemDraft? _findChecklistItem(String blockId, String itemId) {
    for (final NoteChecklistBlockDraft block in checklistBlocks) {
      if (block.id != blockId) {
        continue;
      }

      for (final NoteChecklistItemDraft item in block.items) {
        if (item.id == itemId) {
          return item;
        }
      }
    }

    return null;
  }

  String _blockType(Map<String, dynamic> block) {
    return block['type']?.toString().trim().toLowerCase() ?? '';
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text = value?.toString().trim().toLowerCase() ?? '';

    return text == 'true' || text == '1' || text == 'yes';
  }

  String _extractTextContent(List<Map<String, dynamic>> content) {
    final List<String> paragraphs = <String>[];

    for (final Map<String, dynamic> block in content) {
      final String type = block['type']?.toString().trim().toLowerCase() ?? '';

      if (type == 'text') {
        final String text = block['text']?.toString().trim() ?? '';

        if (text.isNotEmpty) {
          paragraphs.add(text);
        }
      }
    }

    return paragraphs.join('\n\n');
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  String _fileNameFromPath(String filePath) {
    final List<String> parts = filePath.replaceAll('\\', '/').split('/');
    final String name = parts.isEmpty ? '' : parts.last.trim();

    return name.isEmpty ? 'Attached file' : name;
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('ApiException: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }

  @override
  void onClose() {
    titleController.dispose();
    statementController.dispose();

    checklistBlocks.clear();

    super.onClose();
  }
}
