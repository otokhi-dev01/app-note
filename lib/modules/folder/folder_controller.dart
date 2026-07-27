import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/note_model.dart';
import '../../app/theme/colors.dart';
import '../../core/utils/app_logger.dart';

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
    selectedFolder.value = folder;
    nameController.text = folder.name;
    
    // Map color/icon back to indices
    int colorIdx = AppColors.folderColors.indexWhere(
      (c) => c.toARGB32().toString() == folder.colorValue
    );
    selectedColorIndex.value = colorIdx != -1 ? colorIdx : 0;
    selectedIconIndex.value = int.tryParse(folder.iconName ?? '0') ?? 0;
  }

  Future<void> createFolder() async {
    if (nameController.text.isEmpty) return;
    
    final folderToSave = FolderModel(
      id: selectedFolder.value?.id,
      name: nameController.text,
      colorValue: AppColors.folderColors[selectedColorIndex.value].toARGB32().toString(),
      iconName: selectedIconIndex.value.toString(),
    );

    isLoading.value = true;
    try {
      await _folderRepository.saveFolder(folderToSave);
      nameController.clear();
      selectedFolder.value = null;
      Get.back();
      fetchFolders();
    } catch (e) {
      if (e is dio.DioException) {
        AppLogger.error('Folder creation failed', error: e.response?.data);
        Get.snackbar('Error', 'Failed to create folder: ${e.response?.data?['message'] ?? e.message}');
      } else {
        AppLogger.error('Folder creation error', error: e);
        Get.snackbar('Error', 'An unexpected error occurred');
      }
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
