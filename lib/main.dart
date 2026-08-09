import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/data/providers/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'app/data/providers/theme_service.dart';

/*
  App: Otokhi Notes
  Date: 08.09.2026 update by nona_developer in the morning at 12:00am
  Update by: branch nona_developer
  Update by: branch nona
  Feature: dark mode and light mode, rebranding to Otokhi

 */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure we use the ThemeService to load the saved preference or system default
    final themeService = ThemeService();
    
    return GetMaterialApp(
      title: "Otokhi Note",
      debugShowCheckedModeBanner: false,
      enableLog: kDebugMode,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeService.theme,
    );
  }
}
