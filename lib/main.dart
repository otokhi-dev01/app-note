import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/data/providers/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'app/data/providers/theme_service.dart';

/*
  App: OTOKHI NOTE APP
  Date: 08.17.2026 update by nona_developer in the evening at 10:00pm
  Update by: branch nona_developer
  Update by: branch nona
  Feature: All the feature and the logic and integration with api  
 */

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Future<void> main() async {
  // Flutter's debug memory-allocation singleton is lazy. On some iOS hot
  // restarts it can otherwise be initialized re-entrantly while the binding
  // creates its first ValueNotifier, causing a LateInitializationError.
  assert(_initializeDebugMemoryAllocations());

  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      theme: GlassThemeData(
        light: const GlassThemeVariant(
          quality: GlassQuality.standard,
        ),
        dark: const GlassThemeVariant(
          quality: GlassQuality.standard,
        ),
      ),
      child: const MyApp(),
    ),
  );
}

bool _initializeDebugMemoryAllocations() {
  FlutterMemoryAllocations.instance;
  return true;
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
