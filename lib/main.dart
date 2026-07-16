import 'package:flutter/material.dart';
import 'package:notes/app.dart';
import 'package:notes/data/services/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialThemeMode = await LocalStorage().getThemeMode();

  runApp(NoteApp(initialThemeMode: initialThemeMode));
}
