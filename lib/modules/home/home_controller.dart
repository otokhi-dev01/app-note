import 'package:get/get.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/user_model.dart';
import '../../core/utils/app_logger.dart';

class HomeController extends GetxController {
  final FolderRepository _folderRepository = FolderRepository();
  final NoteRepository _noteRepository = NoteRepository();
  final AuthRepository _authRepository = AuthRepository();

  final currentIndex = 0.obs;
  
  final isLoading = false.obs;
  final folders = <FolderModel>[].obs;
  final pinnedNotes = <NoteModel>[].obs;
  final recentNotes = <NoteModel>[].obs;
  final user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      // Fetch user profile
      final fetchedUser = await _authRepository.getProfile();
      if (fetchedUser != null) {
        user.value = fetchedUser;
      }

      final fetchedFolders = await _folderRepository.getFolders();
      folders.value = fetchedFolders;

      final allNotes = await _noteRepository.getAllNotes();
      final notes = allNotes['note'] ?? [];
      
      pinnedNotes.value = notes.where((n) => n.isPinned).toList();
      recentNotes.value = notes.where((n) => !n.isPinned).toList();
    } catch (e) {
      AppLogger.error('Home data fetch error', error: e);
      Get.snackbar('Error', 'Failed to load data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changePage(int index) {
    currentIndex.value = index;
  }
}
