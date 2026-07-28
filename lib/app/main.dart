import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'theme/app_theme.dart';
import 'translations/app_translations.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

  /*
    date : 28.07.2026
    Today, I was updated the new feature
    by branch nona_developer
    name: otokhi_note App
   */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize services
  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => ApiService().init());
  await Get.putAsync(() => AuthService().init());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();
    final savedLocale = storage.languageCode != null 
        ? Locale(storage.languageCode!, storage.countryCode) 
        : Get.deviceLocale;

    return GetMaterialApp(
      title: 'otokhi_note',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      translations: AppTranslations(),
      locale: savedLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
    );
  }
}
