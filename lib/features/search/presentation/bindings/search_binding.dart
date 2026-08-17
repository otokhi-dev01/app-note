import 'package:get/get.dart';

import 'package:Note/features/folder/domain/repositories/folder_repository.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';
import 'package:Note/features/search/domain/usecases/search_usecases.dart';
import 'package:Note/features/search/presentation/controllers/search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SearchNotesAndFolders(
        Get.find<NoteRepository>(),
        Get.find<FolderRepository>(),
      ),
      fenix: true,
    );
    Get.put(SearchController(search: Get.find<SearchNotesAndFolders>()));
  }
}
