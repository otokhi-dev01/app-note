import 'package:get/get.dart';
import 'package:Note/features/splash/presentation/views/splash_view.dart';
import 'package:Note/features/splash/presentation/bindings/splash_binding.dart';
import 'package:Note/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:Note/features/onboarding/presentation/bindings/onboarding_binding.dart';
import 'package:Note/features/auth/presentation/views/login_view.dart';
import 'package:Note/features/auth/presentation/bindings/auth_binding.dart';
import 'package:Note/features/auth/presentation/views/register_view.dart';
import 'package:Note/features/folder/presentation/views/folder_view.dart';
import 'package:Note/features/folder/presentation/bindings/folder_binding.dart';
import 'package:Note/features/note/presentation/views/note_list_view.dart';
import 'package:Note/features/note/presentation/bindings/note_binding.dart';
import 'package:Note/features/note/presentation/views/note_detail_view.dart';
import 'package:Note/features/note/presentation/views/create_note_view.dart';
import 'package:Note/features/search/presentation/views/search_view.dart';
import 'package:Note/features/search/presentation/bindings/search_binding.dart';
import 'package:Note/features/profile/presentation/views/profile_view.dart';
import 'package:Note/features/settings/presentation/views/appearance_view.dart';
import 'package:Note/features/settings/presentation/bindings/appearance_binding.dart';
import 'package:Note/features/settings/presentation/views/help_center_view.dart';
import 'package:Note/features/settings/presentation/views/settings_feature_views.dart';
import 'package:Note/features/auth/presentation/views/forgot_password_view.dart';
import 'package:Note/features/settings/presentation/views/note_preferences_view.dart';
import 'package:Note/features/settings/presentation/bindings/note_preferences_binding.dart';
import 'package:Note/features/settings/presentation/views/account_view.dart';
import 'package:Note/features/settings/presentation/views/delete_account_view.dart';
import 'package:Note/features/settings/presentation/bindings/account_binding.dart';
import 'package:Note/features/trash/presentation/views/recently_deleted_view.dart';
import 'package:Note/features/trash/presentation/bindings/recently_deleted_binding.dart';
import 'package:Note/features/archive/presentation/views/archive_view.dart';

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
      // Captured once, here, rather than re-read from Get.arguments on every
      // widget rebuild: this closure runs exactly once per push, while this
      // route is unambiguously the current one — see NoteNavigation and
      // NoteBinding for why every push needs its own controller tag.
      page: () {
        final args = Get.arguments;
        final tag = args is Map ? args['instanceTag']?.toString() : null;
        final noteId = args is Map ? args['noteId'] : null;
        return (noteId == null || noteId == 0)
            ? CreateNoteView(tag: tag)
            : NoteDetailView(tag: tag);
      },
      binding: NoteBinding(),
    ),
    GetPage(
      name: Routes.SEARCH,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(name: Routes.PROFILE, page: () => const ProfileView()),
    GetPage(
      name: Routes.APPEARANCE,
      page: () => const AppearanceView(),
      binding: AppearanceBinding(),
    ),
    GetPage(name: Routes.HELP_CENTER, page: () => const HelpCenterView()),
    GetPage(
      name: Routes.NOTIFICATIONS,
      page: () => const NotificationSettingsView(),
    ),
    GetPage(name: Routes.DEVICE, page: () => const DeviceSettingsView()),
    GetPage(name: Routes.LANGUAGE, page: () => const LanguageSettingsView()),
    GetPage(name: Routes.PERMISSIONS, page: () => const PermissionsView()),
    GetPage(name: Routes.PRIVACY_POLICY, page: () => const PrivacyPolicyView()),
    GetPage(name: Routes.CONTACT_US, page: () => const ContactUsView()),
    GetPage(
      name: Routes.PRIVACY_SECURITY,
      page: () => const PrivacySecurityView(),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
    ),
    GetPage(
      name: Routes.NOTE_PREFERENCES,
      page: () => const NotePreferencesView(),
      binding: NotePreferencesBinding(),
    ),
    GetPage(
      name: Routes.ACCOUNT,
      page: () => const AccountView(),
      binding: AccountBinding(),
    ),
    GetPage(
      name: Routes.DELETE_ACCOUNT,
      page: () => const DeleteAccountView(),
      binding: AccountBinding(),
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
