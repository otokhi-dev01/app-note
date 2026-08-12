import 'package:get/get.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/folder/views/folder_view.dart';
import '../modules/folder/bindings/folder_binding.dart';
import '../modules/note/views/note_list_view.dart';
import '../modules/note/bindings/note_binding.dart';
import '../modules/note/views/note_detail_view.dart';
import '../modules/search/views/search_view.dart';
import '../modules/search/bindings/search_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/recently_deleted/views/recently_deleted_view.dart';
import '../modules/recently_deleted/bindings/recently_deleted_binding.dart';
import '../modules/archive/views/archive_view.dart';

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
      name: Routes.ARCHIVE,
      page: () => const ArchiveView(),
      binding: NoteBinding(),
    ),
  ];
}
