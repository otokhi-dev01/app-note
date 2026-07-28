import 'package:get/get.dart';
import 'app_routes.dart';
import '../../modules/splash/splash_view.dart';
import '../../modules/splash/splash_binding.dart';
import '../../modules/onboarding/onboarding_view.dart';
import '../../modules/auth/login_view.dart';
import '../../modules/auth/register_view.dart';
import '../../modules/home/home_view.dart';
import '../../modules/home/home_binding.dart';
import '../../modules/folder/folder_list_view.dart';
import '../../modules/folder/folder_detail_view.dart';
import '../../modules/folder/folder_controller.dart';
import '../../modules/note/note_editor_view.dart';
import '../../modules/note/note_list_view.dart';
import '../../modules/note/note_binding.dart';
import '../../modules/note/pinned_notes_view.dart';
import '../../modules/note/locked_notes_view.dart';
import '../../modules/archive/archive_view.dart';
import '../../modules/trash/trash_view.dart';
import '../../modules/search/search_view.dart';
import '../../modules/profile/profile_view.dart';
import '../../modules/settings/settings_view.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.folderList,
      page: () => const FolderListView(),
      binding: BindingsBuilder(() => Get.lazyPut(() => FolderController())),
    ),
    GetPage(
      name: AppRoutes.folderDetail,
      page: () => const FolderDetailView(),
    ),
    GetPage(
      name: AppRoutes.noteEditor,
      page: () => const NoteEditorView(),
      binding: NoteBinding(),
    ),
    GetPage(
      name: AppRoutes.noteList,
      page: () => const NoteListView(),
    ),
    GetPage(
      name: AppRoutes.pinned,
      page: () => const PinnedNotesView(),
    ),
    GetPage(
      name: '/locked-notes',
      page: () => const LockedNotesView(),
    ),
    GetPage(
      name: AppRoutes.archive,
      page: () => const ArchiveView(),
    ),
    GetPage(
      name: AppRoutes.trash,
      page: () => const TrashView(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchView(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
    ),
  ];
}
