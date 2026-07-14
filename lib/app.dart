
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/app/bindings/initial_binding.dart';
import 'package:notes/app/routes/app_pages.dart';
import 'package:notes/app/routes/app_routes.dart';
import 'package:notes/app/theme/app_theme.dart';

class NoteApp extends StatelessWidget {
  const NoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Clean Notes',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}