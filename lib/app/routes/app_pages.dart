import 'package:get/get.dart';
import '../modules/splash/splash_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/onboarding/onboarding_view.dart';
import '../modules/onboarding/onboarding_binding.dart';
import '../modules/auth/login_view.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/register_view.dart';
import '../modules/folder/folder_view.dart';
import '../modules/folder/folder_binding.dart';
import '../modules/note/note_list_view.dart';
import '../modules/note/note_binding.dart';
import '../modules/note/note_detail_view.dart';
import '../modules/search/search_view.dart';
import '../modules/search/search_binding.dart';
import '../modules/profile/profile_view.dart';
import '../modules/profile/profile_binding.dart';
import '../modules/recently_deleted/recently_deleted_view.dart';
import '../modules/recently_deleted/recently_deleted_binding.dart';
import '../modules/trash/trash_view.dart';
import '../modules/trash/trash_binding.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.ONBOARDING,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.FOLDER,
      page: () => const FolderView(),
      binding: FolderBinding(),
    ),
    GetPage(
      name: Routes.NOTE_LIST,
      page: () => const NoteListView(),
      binding: NoteBinding(),
    ),
    GetPage(
      name: Routes.NOTE_DETAIL,
      page: () => const NoteDetailView(),
      binding: NoteBinding(),
    ),
    GetPage(
      name: Routes.SEARCH,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.RECENTLY_DELETED,
      page: () => const RecentlyDeletedView(),
      binding: RecentlyDeletedBinding(),
    ),
    GetPage(
      name: Routes.TRASH,
      page: () => const TrashView(),
      binding: TrashBinding(),
    ),
  ];
}
