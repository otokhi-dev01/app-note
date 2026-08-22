import 'package:get/get.dart';

import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:Note/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:Note/features/auth/domain/repositories/auth_repository.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/folder/data/datasources/folder_remote_data_source.dart';
import 'package:Note/features/folder/data/repositories/folder_repository_impl.dart';
import 'package:Note/features/folder/data/repositories/folder_repository_router.dart';
import 'package:Note/features/folder/data/repositories/local_folder_repository.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';
import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/note/data/datasources/note_remote_data_source.dart';
import 'package:Note/features/note/data/repositories/local_note_repository.dart';
import 'package:Note/features/note/data/repositories/note_repository_impl.dart';
import 'package:Note/features/note/data/repositories/note_repository_router.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';

/// Wires the object graph bottom-up: storage → client → datasources →
/// repositories → use cases.
///
/// Controllers only ever resolve use cases, so a controller can be built in a
/// test against fakes with no HTTP anywhere in sight.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ── Infrastructure ──────────────────────────────────────────────
    Get.put(SessionStorage(), permanent: true);
    Get.put(GuestModeService(), permanent: true);
    Get.put(ApiClient(), permanent: true);

    // ── Datasources ─────────────────────────────────────────────────
    Get.lazyPut(() => AuthRemoteDataSource(), fenix: true);
    Get.lazyPut(() => FolderRemoteDataSource(), fenix: true);
    Get.lazyPut(() => NoteRemoteDataSource(), fenix: true);

    // ── Repositories ────────────────────────────────────────────────
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        Get.find<AuthRemoteDataSource>(),
        Get.find<SessionStorage>(),
      ),
      fenix: true,
    );
    Get.lazyPut(() => LocalFolderRepository(), fenix: true);
    Get.lazyPut<FolderRepository>(
      () => FolderRepositoryRouter(
        FolderRepositoryImpl(Get.find<FolderRemoteDataSource>()),
        Get.find<LocalFolderRepository>(),
        Get.find<GuestModeService>(),
      ),
      fenix: true,
    );
    Get.lazyPut(
      () => LocalNoteRepository(Get.find<LocalFolderRepository>()),
      fenix: true,
    );
    Get.lazyPut<NoteRepository>(
      () => NoteRepositoryRouter(
        NoteRepositoryImpl(Get.find<NoteRemoteDataSource>()),
        Get.find<LocalNoteRepository>(),
        Get.find<GuestModeService>(),
      ),
      fenix: true,
    );

    _authUseCases();
    _folderUseCases();
    _noteUseCases();
  }

  void _authUseCases() {
    AuthRepository repo() => Get.find<AuthRepository>();
    Get.lazyPut(() => Login(repo()), fenix: true);
    Get.lazyPut(() => Register(repo()), fenix: true);
    Get.lazyPut(() => ForgotPassword(repo()), fenix: true);
    Get.lazyPut(() => Logout(repo()), fenix: true);
    Get.lazyPut(() => DeleteAccount(repo()), fenix: true);
    Get.lazyPut(() => LoadSession(repo()), fenix: true);
  }

  void _folderUseCases() {
    FolderRepository repo() => Get.find<FolderRepository>();
    Get.lazyPut(() => GetFolders(repo()), fenix: true);
    Get.lazyPut(() => SaveFolder(repo()), fenix: true);
    Get.lazyPut(() => DeleteRestoreFolder(repo()), fenix: true);
    Get.lazyPut(() => const BuildFolderHierarchy(), fenix: true);
  }

  void _noteUseCases() {
    NoteRepository repo() => Get.find<NoteRepository>();
    Get.lazyPut(() => GetNotes(repo()), fenix: true);
    Get.lazyPut(() => GetNoteDetail(repo()), fenix: true);
    Get.lazyPut(() => GetTrashNotes(repo()), fenix: true);
    Get.lazyPut(() => SaveNote(repo()), fenix: true);
    Get.lazyPut(() => SaveNoteMetadata(repo()), fenix: true);
    Get.lazyPut(() => SaveNoteContent(repo()), fenix: true);
    Get.lazyPut(() => UpdateNoteState(repo()), fenix: true);
    Get.lazyPut(() => DeleteRestoreNote(repo()), fenix: true);
    Get.lazyPut(() => MoveNotesToFolder(repo()), fenix: true);
    Get.lazyPut(() => UploadAttachment(repo()), fenix: true);
    Get.lazyPut(() => DownloadAttachment(repo()), fenix: true);
    Get.lazyPut(() => DeleteNotePermanently(repo()), fenix: true);
    Get.lazyPut(() => EmptyTrash(repo()), fenix: true);
  }
}
