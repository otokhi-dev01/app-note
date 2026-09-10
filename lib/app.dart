import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/di/injector.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/services/share_intent_service.dart';
import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/core/storage/theme_storage.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/routes/app_pages.dart';

/// The application widget: themes, routes, and the root dependency graph.
/// Bootstrapping (bindings init, storage, the glass runtime) stays in
/// `main.dart`; everything the app *is* lives here.
class NoteApp extends StatefulWidget {
  const NoteApp({super.key});

  @override
  State<NoteApp> createState() => _NoteAppState();
}

class _NoteAppState extends State<NoteApp> {
  @override
  void initState() {
    super.initState();
    // Deferred to the first post-frame callback so GetX's navigator is
    // mounted before a cold-start share tries to push the note route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShareIntentService.instance.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Reads the saved light/dark preference, falling back to the system value.
    final themeStorage = ThemeStorage();

    return GetMaterialApp(
      title: 'Pii Note',
      debugShowCheckedModeBanner: false,
      enableLog: kDebugMode,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      routingCallback: (routing) =>
          ShareIntentService.instance.onRouteChanged(routing?.current),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeStorage.theme,
      translations: AppTranslations(),
      locale: LanguagePreferences().locale,
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
