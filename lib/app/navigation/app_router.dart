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
import 'package:get/get.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: () => SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => SignupView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.editor,
      page: () => EditorView(),
      binding: EditorBinding(),
    ),
    GetPage(
      name: AppRoutes.detail,
      page: () => DetailView(),
      binding: DetailBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.media,
      page: () => MediaGalleryView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.tags,
      page: () => TagsManagerView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.calendar,
      page: () => NoteCalendarView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.categories,
      page: () => SmartCategoriesView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.storage,
      page: () => StorageManagementView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => NoteHistoryView(),
      binding: HomeBinding(),
    ),
  ];
}
