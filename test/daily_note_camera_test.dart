import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/features/daily_note/data/daily_note_store.dart';
import 'package:Note/features/daily_note/presentation/daily_note_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late File capture;
  late GetStorage storage;
  late DailyNoteStore store;
  final day = DateTime(2026, 2, 3);
  DailyNote note({List<String> photos = const []}) => DailyNote(
    id: 'daily-camera',
    date: day,
    title: 'Photo journal',
    startMinute: 540,
    endMinute: 600,
    color: 0xFF49B8AB,
    photoPaths: photos,
  );

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('daily-camera-test-');
    storage = GetStorage(directory.path.split('/').last, directory.path);
    await storage.initStorage;
    store = DailyNoteStore(
      storage: storage,
      owner: 'guest',
      documentsDirectory: () async => directory,
    );
    capture = await File('${directory.path}/capture.png').writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=',
      ),
    );
  });

  tearDown(() async {
    Get.reset();
    await directory.delete(recursive: true);
  });

  test('old daily notes still load without photos', () {
    final json = note().toJson()..remove('photoPaths');
    expect(DailyNote.fromJson(json).photoPaths, isEmpty);
  });

  test(
    'saved camera photos survive temporary file deletion and reopen',
    () async {
      final bytes = await capture.readAsBytes();
      await store.save(note(photos: [capture.path]));
      final savedPath = store.read().single.photoPaths.single;
      expect(savedPath, isNot(capture.path));
      await capture.delete();
      final reopened = DailyNoteStore(
        storage: storage,
        owner: 'guest',
        documentsDirectory: () async => directory,
      );
      final saved = reopened.read().single;
      expect(await File(saved.photoPaths.single).readAsBytes(), bytes);
      await reopened.save(saved);
      expect(reopened.read().single.photoPaths, [savedPath]);
      await reopened.save(note());
      expect(File(savedPath).existsSync(), isFalse);
    },
  );

  test('deleting a note cleans up only its saved photo copies', () async {
    await store.save(note(photos: [capture.path]));
    final path = store.read().single.photoPaths.single;
    await store.delete('daily-camera');
    expect(File(path).existsSync(), isFalse);
    expect(capture.existsSync(), isTrue);
  });

  test(
    'failed photo import preserves the previous note and removes partial copies',
    () async {
      await store.save(note());
      await expectLater(
        store.save(
          note(photos: [capture.path, '${directory.path}/missing.jpg']),
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(store.read().single.photoPaths, isEmpty);
      final photos = Directory('${directory.path}/daily_note_photos/guest');
      expect(await photos.list().toList(), isEmpty);
    },
  );

  Future<void> openEditor(
    WidgetTester tester,
    ImagePicker picker,
    DailyNoteStore target,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => DailyNoteEditor(
                  store: target,
                  date: day,
                  note: note(),
                  initialMinute: 540,
                  imagePicker: picker,
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'camera capture previews, removes and saves a photo with the draft',
    (tester) async {
      final picker = _CameraPicker()..result = XFile(capture.path);
      final target = _RecordingStore(storage);
      await openEditor(tester, picker, target);
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(picker.source, ImageSource.camera);
      expect(find.byTooltip('Remove photo'), findsOneWidget);
      expect(target.saved, isNull);
      await tester.tap(find.bySemanticsLabel('View photo 1'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.byTooltip('Cancel').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove photo'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove photo'), findsNothing);
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(target.saved!.photoPaths, [capture.path]);
      expect(find.text('Open editor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'camera cancellation and denied permission keep the editor usable',
    (tester) async {
      final picker = _CameraPicker();
      final target = _RecordingStore(storage);
      await openEditor(tester, picker, target);
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove photo'), findsNothing);
      picker.error = PlatformException(code: 'camera_access_denied');
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(
        find.text('Allow camera access in Settings to take a photo.'),
        findsOneWidget,
      );
      expect(target.saved, isNull);
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(target.saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}

class _RecordingStore extends DailyNoteStore {
  DailyNote? saved;
  _RecordingStore(GetStorage storage) : super(storage: storage, owner: 'guest');
  @override
  Future<void> save(DailyNote note) async {
    saved = note;
  }
}

class _CameraPicker extends ImagePicker {
  XFile? result;
  PlatformException? error;
  ImageSource? source;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    if (error != null) throw error!;
    return result;
  }
}
