import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/features/daily_note/data/daily_note_store.dart';
import 'package:Note/features/daily_note/presentation/daily_note_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late GetStorage storage;
  late DailyNoteStore store;
  final day = DateTime(2026, 2, 3);

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
  });

  DailyNote entry(String id, int start, int end, {DateTime? date}) => DailyNote(
    id: id,
    date: date ?? day,
    title: id,
    startMinute: start,
    endMinute: end,
    color: 0xFF49B8AB,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('daily-note-test-');
    storage = GetStorage(directory.path.split('/').last, directory.path);
    await storage.initStorage;
    store = DailyNoteStore(storage: storage, owner: 'guest');
  });

  tearDown(() async {
    Get.reset();
    await directory.delete(recursive: true);
  });

  test(
    'entries survive reopening, update by id, and stay isolated by owner',
    () async {
      await store.save(entry('Run', 540, 570));
      final reopened = DailyNoteStore(storage: storage, owner: 'guest');
      expect(reopened.read().single.title, 'Run');
      await reopened.save(entry('Run', 600, 660));
      expect(reopened.read(), hasLength(1));
      expect(reopened.read().single.startMinute, 600);
      final account = DailyNoteStore(storage: storage, owner: 'account_123');
      expect(account.read(), isEmpty);
      await account.save(entry('Work', 600, 660));
      await reopened.delete('Run');
      expect(reopened.read(), isEmpty);
      expect(account.read().single.title, 'Work');
    },
  );

  test('invalid time ranges do not overwrite saved entries', () async {
    await store.save(entry('Run', 540, 570));
    for (final range in [(-1, 60), (600, 600), (600, 599), (1380, 1441)]) {
      await expectLater(
        store.save(entry('Run', range.$1, range.$2)),
        throwsArgumentError,
      );
    }
    expect(store.read().single.startMinute, 540);
  });

  test('overlap groups use columns and touching endpoints share a column', () {
    final layout = layoutDailyNotes([
      entry('A', 540, 660),
      entry('B', 570, 600),
      entry('C', 600, 690),
      entry('D', 690, 720),
    ]);
    expect(layout.map((item) => item.columns), [2, 2, 2, 1]);
    expect(layout.map((item) => item.column), [0, 1, 1, 0]);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: DailyNoteView(store: store, initialDate: day),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('guest can create, edit, and delete a daily note', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const ValueKey('daily-timeline')), findsOneWidget);
    await tester.tap(find.byTooltip('Add daily note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a title.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('daily-note-title')),
      'Morning planning',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.read().single.title, 'Morning planning');
    expect(find.text('Morning planning'), findsOneWidget);
    await tester.tap(find.text('Morning planning'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('daily-note-title')),
      'Plan the release',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.read(), hasLength(1));
    expect(find.text('Plan the release'), findsOneWidget);
    await tester.tap(find.text('Plan the release'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
    await tester.pumpAndSettle();
    expect(store.read(), isEmpty);
    expect(find.text('A little space to plan your day.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'date navigation, search and list view show only matching entries',
    (tester) async {
      await store.save(entry('Morning run', 540, 570));
      await store.save(entry('Day prep', 575, 675));
      await store.save(
        entry('Tomorrow task', 540, 600, date: DateTime(2026, 2, 4)),
      );
      await open(tester);
      expect(find.text('Morning run'), findsOneWidget);
      expect(find.text('Tomorrow task'), findsNothing);
      await tester.tap(find.byTooltip('Search this day'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'run');
      await tester.pumpAndSettle();
      expect(find.text('Morning run'), findsOneWidget);
      expect(find.text('Day prep'), findsNothing);
      await tester.tap(find.byTooltip('Search this day'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('List view'));
      await tester.pumpAndSettle();
      expect(find.text('Day prep'), findsOneWidget);
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();
      expect(find.text('Tomorrow task'), findsOneWidget);
      expect(find.text('Day prep'), findsNothing);
      await tester.tap(find.byTooltip('Next week'));
      await tester.pumpAndSettle();
      expect(find.text('Tomorrow task'), findsNothing);
      await tester.tap(find.byTooltip('Previous week'));
      await tester.pumpAndSettle();
      expect(find.text('Tomorrow task'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('swiping the day content moves one day at a time', (
    tester,
  ) async {
    await store.save(entry('Today entry', 540, 570));
    await store.save(
      entry('Next day entry', 540, 570, date: DateTime(2026, 2, 4)),
    );
    await open(tester);
    expect(find.text('Today entry'), findsOneWidget);
    expect(find.text('Next day entry'), findsNothing);

    // A leftward swipe (negative velocity) moves forward one day, the same
    // sign convention the week strip already uses for whole weeks.
    await tester.fling(
      find.byKey(const ValueKey('daily-timeline')),
      const Offset(-300, 0),
      800,
    );
    await tester.pumpAndSettle();
    expect(find.text('Next day entry'), findsOneWidget);
    expect(find.text('Today entry'), findsNothing);

    await tester.fling(
      find.byKey(const ValueKey('daily-timeline')),
      const Offset(300, 0),
      800,
    );
    await tester.pumpAndSettle();
    expect(find.text('Today entry'), findsOneWidget);
    expect(find.text('Next day entry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact dark timeline handles overlapping notes and larger text',
    (tester) async {
      await store.save(entry('Run', 540, 570));
      await store.save(entry('Plan', 545, 600));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: DailyNoteView(store: store, initialDate: day),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Add daily note'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('daily-note-title')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
