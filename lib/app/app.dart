import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_theme.dart';
import 'bindings/app_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class PiisiitNoteApp extends StatelessWidget {
  const PiisiitNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Piisiit Note',
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
    );
  }
}