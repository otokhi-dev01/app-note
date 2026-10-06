import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:Note/core/di/injector.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/features/folder/data/repositories/local_folder_repository.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/routes/note_navigation.dart';

// Simulator smoke tests never contact the production API or use the user's
// secure-storage session. Preferences and guest records use a temporary box.
class _OfflineAdapter implements dio.HttpClientAdapter {
  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return dio.ResponseBody.fromString(
      '{"success":true,"data":[]}',
      200,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  // Match main.dart's debug initialization before creating the binding.
  assert(() {
    // ignore: unnecessary_statements
    FlutterMemoryAllocations.instance;
    return true;
  }());
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Guest editor and main screens run on the simulator', (
    tester,
  ) async {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details, forceReport: true);
      previousErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    final temporary = await Directory.systemTemp.createTemp('app_note_smoke_');
    GetStorage('GetStorage', temporary.path);
    await GetStorage.init();
    // Uses the plugin's in-memory testing platform, not the simulator Keychain.
    FlutterSecureStorage.setMockInitialValues({});
    Get.testMode = true;
    final api = Get.put(ApiClient(), permanent: true);
    api.dio.httpClientAdapter = _OfflineAdapter();
    Get.put(GuestModeService(), permanent: true).enable();
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
    await tester.pumpWidget(
      LiquidGlassWidgets.wrap(
        brightnessResolver: Theme.maybeBrightnessOf,
        child: GetMaterialApp(
          initialBinding: InitialBinding(),
          initialRoute: Routes.FOLDER,
          getPages: AppPages.routes,
          scaffoldMessengerKey: AppSnackbar.messengerKey,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          localizationsDelegates:
              quill.FlutterQuillLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('en', 'US'), Locale('km', 'KH')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final folder = (await Get.find<LocalFolderRepository>().saveFolder(
      id: 0,
      name: 'Smoke notes',
      iconName: 'folder',
      colorValue: 'blue',
    )).valueOrNull!;
    unawaited(NoteNavigation.toNewNote<void>(folder) ?? Future<void>.value());
    await tester.pumpAndSettle();
    final tag = (Get.arguments as Map)['instanceTag'] as String;
    final editor = Get.find<NoteDetailController>(tag: tag);
    editor.titleController.text = 'Simulator note';
    final block = editor.blocks.whereType<TextBlock>().first;
    editor
        .getQuillController(block.id, block.text)
        .replaceText(
          0,
          0,
          'Created on simulator',
          const TextSelection.collapsed(offset: 20),
        );
    await editor.saveNote(silent: true);
    expect(editor.currentNote.value?.title, 'Simulator note');
    final savedNote = editor.currentNote.value!;
    Get.back<void>();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    unawaited(NoteNavigation.toDetail<void>(savedNote) ?? Future<void>.value());
    await tester.pumpAndSettle();
    final reopenTag = (Get.arguments as Map)['instanceTag'] as String;
    expect(
      Get.find<NoteDetailController>(tag: reopenTag).titleController.text,
      'Simulator note',
    );
    Get.back<void>();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final route in [
      Routes.NOTE_LIST,
      Routes.SEARCH,
      Routes.DAILY_NOTE,
      Routes.ARCHIVE,
      Routes.RECENTLY_DELETED,
      Routes.PROFILE,
      Routes.MY_CARDS,
      Routes.CARD_SCAN,
      Routes.IDENTITY_SCAN,
      Routes.PASSPORT_SCAN,
      Routes.APPEARANCE,
      Routes.NOTE_PREFERENCES,
      Routes.HELP_CENTER,
      Routes.NOTIFICATIONS,
      Routes.DEVICE,
      Routes.LANGUAGE,
      Routes.PERMISSIONS,
      Routes.PRIVACY_POLICY,
      Routes.CONTACT_US,
      Routes.PRIVACY_SECURITY,
      Routes.ACCOUNT,
      Routes.DELETE_ACCOUNT,
      Routes.LOGIN,
      Routes.REGISTER,
      Routes.FORGOT_PASSWORD,
    ]) {
      unawaited(
        Get.toNamed<void>(
              route,
              arguments: route == Routes.NOTE_LIST
                  ? {'folderId': folder, 'folderName': 'Smoke notes'}
                  : null,
            ) ??
            Future<void>.value(),
      );
      await tester.pumpAndSettle();
      expect(Get.currentRoute, route);
      expect(tester.takeException(), isNull, reason: 'Opening $route');
      Get.back<void>();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Closing $route');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    Get.reset();
    await GetStorage().erase();
    await temporary.delete(recursive: true);
  });
}
