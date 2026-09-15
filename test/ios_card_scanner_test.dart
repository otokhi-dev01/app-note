import 'dart:io';

import 'package:Note/features/profile/data/services/ios_card_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const camera = MethodChannel('cunning_document_scanner');
  const media = MethodChannel('com.kimchheang.otokhi-note/media');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory directory;
  late List<String> paths;
  var cancelled = false;
  var unreadable = false;
  var recognitionFails = false;
  var recognitionCalls = 0;

  setUp(() async {
    cancelled = unreadable = recognitionFails = false;
    recognitionCalls = 0;
    directory = await Directory.systemTemp.createTemp('card-scanner-test-');
    paths = [
      for (final side in ['front', 'back']) '${directory.path}/$side.jpg',
    ];
    for (final path in paths) {
      await File(path).writeAsBytes([0]);
    }
    messenger.setMockMethodCallHandler(camera, (call) async {
      expect(call.method, 'getPictures');
      expect(call.arguments['noOfPages'], 2);
      expect(call.arguments['scannerSource'], 'camera');
      return cancelled ? null : paths;
    });
    messenger.setMockMethodCallHandler(media, (call) async {
      recognitionCalls++;
      expect(call.method, 'recognizeText');
      if (recognitionFails)
        throw PlatformException(code: 'TEXT_RECOGNITION_FAILED');
      if (unreadable) return 'No readable card';
      return call.arguments['path'] == paths.first
          ? '4242 4242 4242 4242\n08/30'
          : 'CARDHOLDER NAME: JANE DOE\nCVC 123';
    });
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(camera, null);
    messenger.setMockMethodCallHandler(media, null);
    await directory.delete(recursive: true);
  });

  test(
    'reads both camera captures and deletes only the returned temporary files',
    () async {
      final unrelated = await File(
        '${directory.path}/keep.jpg',
      ).writeAsBytes([0]);
      final card = await IosCardScanner().scan();
      expect(card!.cardNumber, '4242424242424242');
      expect(card.cardholderName, 'JANE DOE');
      expect(card.cvv, '123');
      expect(recognitionCalls, 2);
      for (final path in paths) {
        expect(await File(path).exists(), isFalse);
      }
      expect(await unrelated.exists(), isTrue);
    },
  );

  test('cancellation does not start recognition', () async {
    cancelled = true;
    expect(await IosCardScanner().scan(), isNull);
    expect(recognitionCalls, 0);
  });

  test(
    'an unreadable card allows retry and removes temporary captures',
    () async {
      unreadable = true;
      await expectLater(
        IosCardScanner().scan(),
        throwsA(isA<CardTextNotFoundException>()),
      );
      for (final path in paths) {
        expect(await File(path).exists(), isFalse);
      }
    },
  );

  test('native recognition failure still removes temporary captures', () async {
    recognitionFails = true;
    await expectLater(
      IosCardScanner().scan(),
      throwsA(isA<PlatformException>()),
    );
    for (final path in paths) {
      expect(await File(path).exists(), isFalse);
    }
  });
}
