import 'package:get/get.dart';
import 'package:notes/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:notes/features/auth/data/datasources/local_storage.dart';
import 'package:notes/features/auth/domain/repositories/auth_repository.dart';
import 'package:notes/features/notes/data/datasources/database_service.dart';
import 'package:notes/features/notes/data/repositories/note_repository_impl.dart';
import 'package:notes/features/notes/data/repositories/local_attachment_file_repository.dart';
import 'package:notes/features/notes/data/datasources/remote/folder_api_service.dart';
import 'package:notes/features/notes/data/datasources/remote/note_api_service.dart';
import 'package:notes/features/notes/domain/repositories/note_repository.dart';
import 'package:notes/features/notes/domain/repositories/attachment_file_repository.dart';
import 'package:notes/features/notes/domain/repositories/folder_repository.dart';
import 'package:notes/features/library/application/attachment_size_query.dart';
import 'package:notes/features/library/data/queries/local_attachment_size_query.dart';
import 'package:notes/features/search/data/repositories/shared_preferences_recent_search_repository.dart';
import 'package:notes/features/search/domain/repositories/recent_search_repository.dart';
import 'package:notes/features/settings/data/repositories/local_theme_repository.dart';
import 'package:notes/features/settings/domain/repositories/theme_repository.dart';

class AppBinding extends Bindings {
  AppBinding({LocalStorage? localStorage})
    : _localStorage = localStorage ?? LocalStorage();

  final LocalStorage _localStorage;

  @override
  void dependencies() {
    Get.put<DatabaseService>(DatabaseService(), permanent: true);
    Get.put<LocalStorage>(_localStorage, permanent: true);

    final authService = AuthService(_localStorage);
    Get.put<AuthService>(authService, permanent: true);
    Get.put<AuthRepository>(authService, permanent: true);
    Get.put<RecentSearchRepository>(
      SharedPreferencesRecentSearchRepository(),
      permanent: true,
    );
    Get.put<ThemeRepository>(
      LocalThemeRepository(_localStorage),
      permanent: true,
    );
    Get.put<AttachmentSizeQuery>(
      const LocalAttachmentSizeQuery(),
      permanent: true,
    );
    Get.put<AttachmentFileRepository>(
      const LocalAttachmentFileRepository(),
      permanent: true,
    );

    Get.put<FolderApiService>(FolderApiService(authService), permanent: true);
    Get.put<NoteApiService>(NoteApiService(authService), permanent: true);

    Get.lazyPut<NoteRepository>(
      () => NoteRepositoryImpl(
        Get.find<DatabaseService>(),
        Get.find<AuthRepository>(),
        Get.find<FolderApiService>(),
        Get.find<NoteApiService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<FolderRepository>(
      () => Get.find<NoteRepository>(),
      fenix: true,
    );
  }
}
