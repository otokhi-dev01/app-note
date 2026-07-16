import 'package:flutter/material.dart';
import 'package:notes/app/app.dart';
import 'package:notes/features/auth/data/datasources/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localStorage = LocalStorage();
  final initialThemeMode = await localStorage.getThemeMode();

  runApp(
    NoteApp(initialThemeMode: initialThemeMode, localStorage: localStorage),
  );
}
