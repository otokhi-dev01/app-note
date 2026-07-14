import 'package:get/get.dart';
import 'package:notes/presentation/modules/detail/detail_binding.dart';
import 'package:notes/presentation/modules/detail/detail_view.dart';
import 'package:notes/presentation/modules/editor/editor_binding.dart';
import 'package:notes/presentation/modules/editor/editor_view.dart';
import 'package:notes/presentation/modules/home/home_binding.dart';
import 'package:notes/presentation/modules/home/home_view.dart';
import 'package:notes/presentation/modules/auth/login_view.dart';
import 'package:notes/presentation/modules/auth/signup_view.dart';
import 'package:notes/presentation/modules/auth/auth_binding.dart';
import 'package:notes/presentation/modules/splash/splash_view.dart';
import 'package:notes/presentation/modules/splash/splash_binding.dart';
import '../../presentation/modules/settings/settings_binding.dart';
import '../../presentation/modules/settings/settings_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
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
  ];
}
