import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/note_model.dart';
import '../../app/theme/colors.dart';

class FolderController extends GetxController {
  final FolderRepository _folderRepository = FolderRepository();
  final NoteRepository _noteRepository = NoteRepository();

  final folders = <FolderModel>[].obs;
  final isLoading = false.obs;
  
  final nameController = TextEditingController();
  final selectedColorIndex = 0.obs;
  final selectedIconIndex = 0.obs;

  final folderNotes = <NoteModel>[].obs;
  final selectedFolder = Rxn<FolderModel>();

  @override
  void onInit() {
    super.onInit();
    fetchFolders();
  }

  Future<void> fetchFolders() async {
    isLoading.value = true;
    try {
      folders.value = await _folderRepository.getFolders();
    } finally {
      isLoading.value = false;
    }
  }

  void selectFolder(FolderModel folder, {bool navigate = true}) async {
    selectedFolder.value = folder;
    if (navigate) {
      Get.toNamed('/folder-detail', arguments: {
        'folder': folder,
        'heroTag': 'list_folder_${folder.id}',
      });
    }
    
    // Fetch notes for this folder
    isLoading.value = true;
    try {
      final allNotes = await _noteRepository.getAllNotes();
      final notes = allNotes['note'] ?? [];
      folderNotes.value = notes.where((n) => n.folderId == folder.id).toList();
    } finally {
      isLoading.value = false;
    }
  }

  void openEditFolder(FolderModel folder) {
    nameController.text = folder.name;
    // Map color/icon back if possible
    _showFolderSheet(isEdit: true, folderId: folder.id);
  }

  void _showFolderSheet({bool isEdit = false, int? folderId}) {
    // This logic is called from the View. 
    // I'll provide a helper method to be used in FolderListView.
  }

  Future<void> createFolder() async {
    if (nameController.text.isEmpty) return;
    
    final newFolder = FolderModel(
      name: nameController.text,
      colorValue: AppColors.folderColors[selectedColorIndex.value].toARGB32().toString(),
      iconName: selectedIconIndex.value.toString(),
    );

    isLoading.value = true;
    try {
      await _folderRepository.saveFolder(newFolder);
      nameController.clear();
      Get.back();
      fetchFolders();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteFolder(int id) async {
    isLoading.value = true;
    try {
      await _folderRepository.deleteRestoreFolder(id, true);
      fetchFolders();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restoreFolder(int id) async {
    isLoading.value = true;
    try {
      await _folderRepository.deleteRestoreFolder(id, false);
      fetchFolders();
    } finally {
      isLoading.value = false;
    }
  }
}
