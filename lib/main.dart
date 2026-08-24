import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:Note/app.dart';

/*
  App: Pii Note App
  Date: 08.24.2026 update by nona in the evening at 8:00pm
  Update by: branch nona_developer
  Update by: branch nona
  Feature: All the feature and the logic and integration with api
 */

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
        light: const GlassThemeVariant(quality: GlassQuality.standard),
        dark: const GlassThemeVariant(quality: GlassQuality.standard),
      ),
      child: const NoteApp(),
    ),
  );
}

bool _initializeDebugMemoryAllocations() {
  // Touching it is the point: this forces the lazy singleton to
  // initialise before the binding does.
  // ignore: unnecessary_statements
  FlutterMemoryAllocations.instance;
  return true;
}
