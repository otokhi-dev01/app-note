import 'package:get/get.dart';

import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';
import 'package:Note/features/search/domain/usecases/search_usecases.dart';
import 'package:Note/features/search/presentation/controllers/search_controller.dart';
import 'package:Note/features/search/data/datasources/user_search_remote_data_source.dart';
import 'package:Note/features/search/data/repositories/user_search_repository_impl.dart';
import 'package:Note/features/search/domain/repositories/user_search_repository.dart';

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
    Get.lazyPut(
      () => UserSearchRemoteDataSource(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<UserSearchRepository>(
      () => UserSearchRepositoryImpl(Get.find<UserSearchRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut(
      () => SearchUsers(Get.find<UserSearchRepository>()),
      fenix: true,
    );
    Get.put(
      SearchController(
        search: Get.find<SearchNotesAndFolders>(),
        searchUsers: Get.find<SearchUsers>(),
        session: Get.find<SessionStorage>(),
      ),
    );
  }
}
