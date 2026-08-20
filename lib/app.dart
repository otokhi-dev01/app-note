import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/storage/language_preferences.dart';
import 'package:Note/core/storage/theme_storage.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/routes/app_pages.dart';

/// The application widget: themes, routes, and the root dependency graph.
///
/// Bootstrapping (bindings init, storage, the glass runtime) stays in
/// `main.dart`; everything the app *is* lives here.
class NoteApp extends StatelessWidget {
  const NoteApp({super.key});

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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeStorage.theme,
      translations: AppTranslations(),
      locale: LanguagePreferences().locale,
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
