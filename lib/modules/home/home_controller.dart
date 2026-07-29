import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/user_model.dart';
import '../../core/utils/app_logger.dart';
import 'package:otokhi_note/modules/note/note_list_controller.dart';
import '../folder/folder_controller.dart';

class HomeController extends GetxController {
  final FolderRepository _folderRepository = FolderRepository();
  final NoteRepository _noteRepository = NoteRepository();
  final AuthRepository _authRepository = AuthRepository();

  final currentIndex = 0.obs;
  late PageController pageController;
  
  final isLoading = false.obs;
  final folders = <FolderModel>[].obs;
  final pinnedNotes = <NoteModel>[].obs;
  final recentNotes = <NoteModel>[].obs;
  final user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: currentIndex.value);
    fetchData();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      // Fetch user profile
      final fetchedUser = await _authRepository.getProfile();
      if (fetchedUser != null) {
        user.value = fetchedUser;
      }

      final fetchedData = await _folderRepository.getFolders();
      folders.value = fetchedData['folder'] ?? [];

      final allNotes = await _noteRepository.getAllNotes();
      final notes = allNotes['note'] ?? [];
      
      // Sort pinned notes by pinnedAt or createdAt (descending)
      pinnedNotes.value = notes.where((n) => n.isPinned).toList()
        ..sort((a, b) => (b.pinnedAt ?? b.createdAt ?? DateTime.now())
            .compareTo(a.pinnedAt ?? a.createdAt ?? DateTime.now()));

      // Recent notes (not pinned) sorted by updatedAt
      recentNotes.value = notes.where((n) => !n.isPinned).toList()
        ..sort((a, b) => (b.updatedAt ?? b.createdAt ?? DateTime.now())
            .compareTo(a.updatedAt ?? a.createdAt ?? DateTime.now()));

      // Synchronize other controllers if they exist
      if (Get.isRegistered<NoteListController>()) {
        final noteListController = Get.find<NoteListController>();
        // Only refresh the active list to avoid unnecessary API calls
        if (currentIndex.value == 2) { // Pinned Tab
          noteListController.fetchPinnedNotes();
        }
      }
      if (Get.isRegistered<FolderController>()) {
        Get.find<FolderController>().fetchFolders();
      }
    } catch (e) {
      AppLogger.error('Home data fetch error', error: e);
      Get.snackbar('Error', 'Failed to load data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changePage(int index) {
    if (currentIndex.value == index) return;
    HapticFeedback.lightImpact();
    
    // We update the index here to make the bottom bar react instantly
    currentIndex.value = index;
    
    // Animate the PageView to the selected tab
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
  }
}
