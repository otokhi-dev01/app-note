import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Note/features/profile/data/services/identity_image_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.kimchheang.otokhi-note/media');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final export = IdentityCardExport(
    bytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
    fileName: 'identity_card.png',
  );

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('Downloads go to the photo library on ${platform.name}', () async {
      debugDefaultTargetPlatformOverride = platform;
      final completion = Completer<String>();
      final received = Completer<MethodCall>();
      messenger.setMockMethodCallHandler(channel, (call) {
        received.complete(call);
        return completion.future;
      });
      var saved = false;
      final future = IdentityImageService.save(export).then((value) {
        saved = true;
        return value;
      });
      final call = await received.future;
      expect(call.method, 'savePhoto');
      expect(call.arguments['fileName'], 'identity_card.png');
      expect(call.arguments['bytes'], export.bytes);
      expect(saved, isFalse);
      completion.complete('saved-photo-id');
      expect(await future, 'saved-photo-id');
    });
  }

  for (final code in ['PHOTO_PERMISSION_DENIED', 'PHOTO_SAVE_FAILED']) {
    test('$code propagates without reporting a successful save', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: code);
      });
      await expectLater(
        IdentityImageService.save(export),
        throwsA(
          isA<PlatformException>().having((error) => error.code, 'code', code),
        ),
      );
    });
  }

  test('An unconfirmed native save is treated as a failure', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    await expectLater(
      IdentityImageService.save(export),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'PHOTO_SAVE_FAILED',
        ),
      ),
    );
  });
}
