import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/app/di/app_binding.dart';
import 'package:notes/app/navigation/app_router.dart';
import 'package:notes/app/navigation/app_routes.dart';
import 'package:notes/app/theme/app_theme.dart';
import 'package:notes/core/constants/app_strings.dart';
import 'package:notes/features/auth/data/datasources/local_storage.dart';

class NoteApp extends StatelessWidget {
  const NoteApp({
    super.key,
    this.initialThemeMode = ThemeMode.system,
    this.localStorage,
  });

  final ThemeMode initialThemeMode;
  final LocalStorage? localStorage;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      getPages: AppRouter.pages,
      initialBinding: AppBinding(localStorage: localStorage),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: initialThemeMode,
    );
  }
}
