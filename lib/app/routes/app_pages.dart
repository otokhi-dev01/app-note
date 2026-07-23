import 'package:get/get.dart';

import '../../feature/auth/presentation/binding/login_binding.dart';
import '../../feature/auth/presentation/binding/register_binding.dart';
import '../../feature/auth/presentation/view/login_view.dart';
import '../../feature/auth/presentation/view/register_view.dart';
import '../../feature/folders/presentation/binding/create_folder_binding.dart';
import '../../feature/folders/presentation/binding/recently_deleted_folders_binding.dart';
import '../../feature/folders/presentation/view/create_folder_view.dart';
import '../../feature/folders/presentation/view/recently_deleted_folders_view.dart';
import '../../feature/main/presentation/view/main_view.dart';
import '../../feature/notes/presentation/bindings/create_note_binding.dart';
import '../../feature/notes/presentation/bindings/home_binding.dart';
import '../../feature/notes/presentation/bindings/note_editor_binding.dart';
import '../../feature/notes/presentation/view/create_note_view.dart';
import '../../feature/notes/presentation/view/note_editor_view.dart';
import '../../feature/recycle_bin/presentation/bindings/recycle_bin_binding.dart';
import '../../feature/recycle_bin/presentation/views/recycle_bin_view.dart';
import '../controllers/splash_controller.dart';
import '../views/splash_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.put<SplashController>(SplashController(authRepository: Get.find()));
      }),
    ),

    GetPage<dynamic>(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const MainView(),
      binding: HomeBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.createFolder,
      page: () => const CreateFolderView(),
      binding: CreateFolderBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.recentlyDeletedFolders,
      page: () => const RecentlyDeletedFoldersView(),
      binding: RecentlyDeletedFoldersBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.createNote,
      page: () => const CreateNoteView(),
      binding: CreateNoteBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.archive,
      page: () => const RecycleBinView(isArchiveMode: true),
      binding: RecycleBinBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.noteEditor,
      page: () => const NoteEditorView(),
      binding: NoteEditorBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.recycleBin,
      page: () => const RecycleBinView(),
      binding: RecycleBinBinding(),
    ),
  ];
}
