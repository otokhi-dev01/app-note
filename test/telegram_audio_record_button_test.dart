import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/features/note/presentation/widgets/telegram_audio_record_button.dart';

class _FakeRecorder implements TelegramAudioRecorder {
  int starts = 0;
  int stops = 0;
  int cancels = 0;

  @override
  Future<void> cancel() async => cancels++;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start(String path) async => starts++;

  @override
  Future<String?> stop() async {
    stops++;
    return '/tmp/telegram_voice_test.m4a';
  }
}

Widget _app({
  required _FakeRecorder recorder,
  required TelegramRecordingCallback onRecorded,
}) {
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('en', 'US'),
    home: Scaffold(
      body: Center(
        child: TelegramAudioRecordButton(
          semanticLabel: 'Record audio',
          minimumDuration: Duration.zero,
          recorderFactory: () => recorder,
          pathBuilder: () async => '/tmp/telegram_voice_test.m4a',
          onRecorded: onRecorded,
        ),
      ),
    ),
  );
}

void main() {
  tearDown(Get.reset);

  testWidgets('hold and release records inline and saves once', (tester) async {
    final recorder = _FakeRecorder();
    var saves = 0;
    await tester.pumpWidget(
      _app(recorder: recorder, onRecorded: (_) async => saves++),
    );

    await tester.longPress(find.byType(TelegramAudioRecordButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(recorder.stops, 1);
    expect(recorder.cancels, 0);
    expect(saves, 1);
    expect(find.byType(TelegramAudioRecordButton), findsOneWidget);
  });

  testWidgets('dragging left cancels without saving', (tester) async {
    final recorder = _FakeRecorder();
    var saves = 0;
    await tester.pumpWidget(
      _app(recorder: recorder, onRecorded: (_) async => saves++),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(TelegramAudioRecordButton)),
    );
    await tester.pump(
      kLongPressTimeout + kPressTimeout + const Duration(milliseconds: 100),
    );
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('Slide left to cancel'), findsOneWidget);
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));

    expect(recorder.starts, 1);
    expect(recorder.stops, 0);
    expect(recorder.cancels, 1);
    expect(saves, 0);
    expect(find.byType(TelegramAudioRecordButton), findsOneWidget);
  });
}
