import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/models/note_model.dart';
import '../../data/models/content_block_model.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/pin_dialog.dart';

class NoteController extends GetxController {
  final NoteRepository _repository = NoteRepository();
  final _uuid = const Uuid();
  final _picker = ImagePicker();

  final note = Rxn<NoteModel>();
  final isLoading = false.obs;
  
  final titleController = TextEditingController();
  final blocks = <ContentBlockModel>[].obs;

  void initNote(int? id) async {
    if (id == null) {
      note.value = null;
      titleController.clear();
      blocks.value = [
        ContentBlockModel(id: _uuid.v4(), type: 'text', text: '')
      ];
    } else {
      isLoading.value = true;
      try {
        final detail = await _repository.getNoteDetail(id);
        if (detail != null) {
          if (detail.isLocked) {
            _showUnlockDialog(detail);
          } else {
            _loadNoteData(detail);
          }
        }
      } finally {
        isLoading.value = false;
      }
    }
  }

  void _loadNoteData(NoteModel detail) {
    note.value = detail;
    titleController.text = detail.title;
    blocks.value = detail.content ?? [
      ContentBlockModel(id: _uuid.v4(), type: 'text', text: '')
    ];
  }

  void _showUnlockDialog(NoteModel detail) {
    Get.dialog(PinDialog(onConfirm: (pin) {
      if (pin == '1234') { // Mock PIN
        _loadNoteData(detail);
      } else {
        UIHelpers.showSnackBar('Error', 'Invalid PIN', isError: true);
        Get.back();
      }
    }));
  }

  void addTextBlock() {
    blocks.add(ContentBlockModel(id: _uuid.v4(), type: 'text', text: ''));
  }

  void addChecklistBlock() {
    blocks.add(ContentBlockModel(
      id: _uuid.v4(), 
      type: 'checklist', 
      items: [ChecklistItemModel(id: _uuid.v4(), text: '', checked: false)]
    ));
  }

  Future<void> addImageBlock() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final blockId = _uuid.v4();
      blocks.add(ContentBlockModel(
        id: blockId,
        type: 'attachment',
        displayName: image.name,
        text: image.path,
      ));
      
      // If note exists, upload immediately
      if (note.value?.id != null) {
        await _repository.uploadAttachment(
          noteId: note.value!.id!,
          filePath: image.path,
          blockId: blockId,
        );
      }
    }
  }

  Future<void> addFileBlock() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = result.files.first;
      final blockId = _uuid.v4();
      blocks.add(ContentBlockModel(
        id: blockId,
        type: 'attachment',
        displayName: file.name,
        text: file.path,
      ));

      if (note.value?.id != null && file.path != null) {
        await _repository.uploadAttachment(
          noteId: note.value!.id!,
          filePath: file.path!,
          blockId: blockId,
        );
      }
    }
  }

  void updateTextBlock(int index, String text) {
    final oldBlock = blocks[index];
    blocks[index] = ContentBlockModel(
      id: oldBlock.id,
      type: 'text',
      text: text,
    );
  }

  void toggleChecklistItem(int blockIndex, int itemIndex) {
    final block = blocks[blockIndex];
    if (block.items == null) return;
    
    final items = List<ChecklistItemModel>.from(block.items!);
    final oldItem = items[itemIndex];
    items[itemIndex] = ChecklistItemModel(
      id: oldItem.id,
      text: oldItem.text,
      checked: !oldItem.checked,
    );

    blocks[blockIndex] = ContentBlockModel(
      id: block.id,
      type: 'checklist',
      items: items,
    );
  }

  Future<void> saveNote() async {
    if (titleController.text.isEmpty) return;
    
    isLoading.value = true;
    try {
      final noteId = note.value?.id ?? 0;
      final savedId = await _repository.saveNote(noteId, 2, titleController.text);
      
      final idToSave = note.value?.id ?? savedId ?? 0;
      if (idToSave != 0) {
        await _repository.saveContent(
          idToSave, 
          titleController.text, 
          blocks.map((e) => e.toJson()).toList()
        );
        UIHelpers.showSnackBar('Success', 'Note saved');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> togglePin() async {
    if (note.value == null) return;
    final newState = !note.value!.isPinned;
    await _repository.updateNoteState(id: note.value!.id!, isPinned: newState);
    note.value = NoteModel.fromJson({
      ...note.value!.toJson(),
      'IsPinned': newState,
    });
  }
}
