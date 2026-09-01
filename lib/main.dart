import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:Note/app.dart';

/*
  App: Pii Note App
  Date: 09.01.2026 update by nona in the evening at 8:00pm
  Update by: branch nona
  Feature:
 */

Future<void> main() async {
  assert(_initializeDebugMemoryAllocations());

  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);

  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      theme: GlassThemeData(
        light: const GlassThemeVariant(quality: GlassQuality.standard),
        dark: const GlassThemeVariant(quality: GlassQuality.standard),
      ),
      child: const NoteApp(),
    ),
  );
}

bool _initializeDebugMemoryAllocations() {
  // ignore: unnecessary_statements
  FlutterMemoryAllocations.instance;
  return true;
}
