import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:Note/core/services/share_intent_service.dart';
import 'package:Note/routes/app_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = ShareIntentService.instance;
  late Directory directory;
  late File document;
  late StreamController<List<SharedMediaFile>> shares;
  late ReceiveSharingIntent originalReceiver;
  late List<List<String>> openedNotes;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('pii-share-');
    document = File('${directory.path}/Meeting notes.pdf')
      ..writeAsStringSync('%PDF-1.4\n');
    shares = StreamController<List<SharedMediaFile>>.broadcast();
    originalReceiver = ReceiveSharingIntent.instance;
    openedNotes = [];
  });

  tearDown(() async {
    service.dispose();
    await shares.close();
    ReceiveSharingIntent.instance = originalReceiver;
    Get.reset();
    directory.deleteSync(recursive: true);
  });

  Future<void> launch(
    WidgetTester tester, {
    String route = Routes.SPLASH,
    List<SharedMediaFile> initial = const [],
  }) async {
    ReceiveSharingIntent.setMockValues(
      initialMedia: initial,
      mediaStream: shares.stream,
    );
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: route,
        routingCallback: (routing) => service.onRouteChanged(routing?.current),
        getPages: [
          for (final name in [
            Routes.SPLASH,
            Routes.ONBOARDING,
            Routes.LOGIN,
            Routes.FOLDER,
          ])
            GetPage(
              name: name,
              page: () => Scaffold(body: Text(name)),
            ),
          GetPage(
            name: Routes.NOTE_DETAIL,
            page: () {
              final arguments = Get.arguments as Map;
              openedNotes.add(List<String>.from(arguments['sharedFilePaths']));
              return const Scaffold(body: Text('Shared document note'));
            },
          ),
        ],
      ),
    );
    service.start();
    await tester.pumpAndSettle();
  }

  SharedMediaFile shared(String path) =>
      SharedMediaFile(path: path, type: SharedMediaType.file);

  testWidgets('cold-start document survives splash navigation', (tester) async {
    await launch(tester, initial: [shared(document.path)]);
    expect(Get.currentRoute, Routes.SPLASH);
    expect(openedNotes, isEmpty);

    unawaited(Get.offAllNamed(Routes.FOLDER));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.NOTE_DETAIL);
    expect(openedNotes, [
      [document.path],
    ]);
  });

  testWidgets('first-time share waits for onboarding and sign-in', (
    tester,
  ) async {
    await launch(tester, initial: [shared(document.path)]);
    unawaited(Get.offAllNamed(Routes.ONBOARDING));
    await tester.pumpAndSettle();
    unawaited(Get.toNamed(Routes.LOGIN));
    await tester.pumpAndSettle();
    expect(openedNotes, isEmpty);

    unawaited(Get.offAllNamed(Routes.FOLDER));
    await tester.pumpAndSettle();
    expect(openedNotes, [
      [document.path],
    ]);
  });

  testWidgets('warm share accepts file URLs and multiple documents once', (
    tester,
  ) async {
    final second = File('${directory.path}/Budget.xlsx')
      ..writeAsStringSync('data');
    await launch(tester, route: Routes.FOLDER);
    service.start(); // Repeated initialization must not duplicate listeners.
    shares.add([
      shared(document.uri.toString()),
      shared(document.path),
      shared(second.path),
      shared('${directory.path}/missing.pdf'),
      SharedMediaFile(path: document.path, type: SharedMediaType.text),
    ]);
    await tester.pumpAndSettle();
    expect(openedNotes, [
      [document.path, second.path],
    ]);
  });

  testWidgets('another share can open a new note while an editor is open', (
    tester,
  ) async {
    await launch(tester, route: Routes.FOLDER);
    shares.add([shared(document.path)]);
    await tester.pumpAndSettle();
    shares.add([shared(document.path)]);
    await tester.pumpAndSettle();
    expect(openedNotes, [
      [document.path],
      [document.path],
    ]);
  });

  testWidgets('unavailable files and links do not open empty notes', (
    tester,
  ) async {
    await launch(tester, route: Routes.FOLDER);
    shares.add([
      shared('${directory.path}/missing.pdf'),
      SharedMediaFile(path: 'https://example.com', type: SharedMediaType.url),
    ]);
    await tester.pumpAndSettle();
    expect(openedNotes, isEmpty);
    expect(Get.currentRoute, Routes.FOLDER);
  });
}
