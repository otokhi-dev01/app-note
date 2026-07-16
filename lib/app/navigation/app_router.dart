import 'package:get/get.dart';
import 'package:notes/features/notes/presentation/detail/detail_binding.dart';
import 'package:notes/features/notes/presentation/detail/detail_view.dart';
import 'package:notes/features/notes/presentation/editor/editor_binding.dart';
import 'package:notes/features/notes/presentation/editor/editor_view.dart';
import 'package:notes/features/notes/presentation/home/home_binding.dart';
import 'package:notes/features/notes/presentation/home/home_view.dart';
import 'package:notes/features/auth/presentation/bindings/auth_binding.dart';
import 'package:notes/features/auth/presentation/pages/login_view.dart';
import 'package:notes/features/auth/presentation/pages/signup_view.dart';
import 'package:notes/features/library/presentation/library.dart';
import 'package:notes/features/settings/presentation/bindings/settings_binding.dart';
import 'package:notes/features/settings/presentation/pages/settings_view.dart';
import 'package:notes/features/startup/presentation/bindings/splash_binding.dart';
import 'package:notes/features/startup/presentation/pages/splash_view.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.editor,
      page: () => const EditorView(),
      binding: EditorBinding(),
    ),
    GetPage(
      name: AppRoutes.detail,
      page: () => const DetailView(),
      binding: DetailBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.media,
      page: () => const MediaGalleryView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.tags,
      page: () => const TagsManagerView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.calendar,
      page: () => const NoteCalendarView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.categories,
      page: () => const SmartCategoriesView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.storage,
      page: () => const StorageManagementView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => const NoteHistoryView(),
      binding: HomeBinding(),
    ),
  ];
}
