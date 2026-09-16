import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:Note/features/profile/data/services/card_camera_session.dart';
import 'package:Note/features/profile/domain/entities/card_scan_recognition.dart';
import 'package:Note/features/profile/domain/entities/credit_card.dart';
import 'package:Note/features/profile/presentation/views/card_camera_view.dart';

const frontText = 'VISA\n4242 4242 4242 4242\nVUTHUL VUN\n08/30';
const backText = 'AUTHORIZED SIGNATURE\n123';

class FakeCameraSession extends CardCameraSession {
  FakeCameraSession({this.initializationError});
  final Object? initializationError;
  bool closed = false;
  bool torch = false;
  String text = frontText;
  Completer<String>? capture;
  ValueChanged<String>? onText;

  @override
  Future<void> initialize() async {
    if (initializationError != null) throw initializationError!;
  }

  @override
  Widget buildPreview() => const ColoredBox(color: Color(0xFF50534B));
  @override
  Future<void> startDetection(ValueChanged<String> callback) async =>
      onText = callback;
  @override
  Future<void> stopDetection() async => onText = null;
  @override
  Future<void> dispose() async {
    closed = true;
    onText = null;
  }

  @override
  Future<void> setTorch(bool enabled) async => torch = enabled;
  @override
  Future<void> focus(Offset point) async {}
  @override
  Future<String> captureText() async =>
      capture != null ? capture!.future : text;
}

void main() {
  testWidgets('Unavailable camera preview does not throw a null error', (
    tester,
  ) async {
    final session = CardCameraSession();
    await tester.pumpWidget(MaterialApp(home: session.buildPreview()));
    expect(tester.takeException(), isNull);
    await session.dispose();
    await tester.pumpWidget(MaterialApp(home: session.buildPreview()));
    expect(tester.takeException(), isNull);
  });

  test(
    'Unavailable camera capture returns a recoverable camera error',
    () async {
      final session = CardCameraSession();
      await expectLater(session.captureText(), throwsA(isA<CameraException>()));
      await session.dispose();
      await expectLater(session.captureText(), throwsA(isA<CameraException>()));
    },
  );

  test('Two sides merge number, unlabelled name, expiry, and back CVV', () {
    final card = CardScanRecognition.parseSides(frontText, backText)!;
    expect(card.cardNumber, '4242424242424242');
    expect(card.cardholderName, 'VUTHUL VUN');
    expect(card.expiryMonth, '08');
    expect(card.expiryYear, '2030');
    expect(card.cvv, '123');
    expect(CardScanRecognition.parseSides('unreadable', '123'), isNull);
    expect(CardScanRecognition.backCandidate('123\n456'), isNull);
    expect(CardScanRecognition.backCandidate('08/2030'), isNull);
    expect(CardScanRecognition.backCandidate('2030'), isNull);
    expect(
      CardScanRecognition.backCandidate('1234', fourDigitCode: true),
      '1234',
    );
    expect(
      CardScanRecognition.parseSides('BANK NAME', frontText)?.cardNumber,
      '4242424242424242',
    );
  });

  test('Preview crop follows cover scaling for portrait and landscape', () {
    expect(
      cardFrameCrop(
        const Size(1000, 2000),
        const Size(400, 800),
        const Rect.fromLTWH(40, 200, 320, 200),
      ),
      const Rect.fromLTWH(100, 500, 800, 500),
    );
    expect(
      cardFrameCrop(
        const Size(2000, 1000),
        const Size(400, 800),
        const Rect.fromLTWH(40, 200, 320, 200),
      ),
      const Rect.fromLTWH(800, 250, 400, 250),
    );
  });

  test('OCR frame conversion handles padded Y and BGRA rows and rotation', () {
    final yBytes = Uint8List.fromList([
      80,
      80,
      80,
      80,
      0,
      0,
      80,
      80,
      80,
      80,
      0,
      0,
    ]);
    final result = img.decodeJpg(
      encodeCardCameraFrame(
        CardCameraFrame(
          bytes: yBytes,
          width: 4,
          height: 2,
          rowStride: 6,
          pixelStride: 1,
          bgra: false,
          rotation: 90,
          viewport: const Size(2, 4),
          frame: const Rect.fromLTWH(0, 0, 2, 4),
        ),
      ),
    )!;
    expect(result.width, 2);
    expect(result.height, 4);
    expect(result.getPixel(0, 0).r, closeTo(80, 3));
    final bgra = Uint8List.fromList([
      0,
      0,
      255,
      255,
      0,
      0,
      255,
      255,
      0,
      0,
      0,
      0,
    ]);
    final red = img.decodeJpg(
      encodeCardCameraFrame(
        CardCameraFrame(
          bytes: bgra,
          width: 2,
          height: 1,
          rowStride: 12,
          pixelStride: 4,
          bgra: true,
          rotation: 0,
          viewport: const Size(2, 1),
          frame: const Rect.fromLTWH(0, 0, 2, 1),
        ),
      ),
    )!;
    expect(red.getPixel(1, 0).r, closeTo(76, 3));
  });

  Future<void> mount(
    WidgetTester tester, {
    required FakeCameraSession Function() factory,
    ValueChanged<CreditCard>? onComplete,
    VoidCallback? onCancel,
    Future<String?> Function()? pick,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CardCameraView(
          createSession: factory,
          pickText: pick ?? () async => null,
          onComplete: onComplete ?? (_) {},
          onCancel: onCancel ?? () {},
          onEnterManually: () {},
          onSideChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('Camera layout and manual two-side capture at $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final camera = FakeCameraSession();
      CreditCard? result;
      await mount(
        tester,
        factory: () => camera,
        onComplete: (card) => result = card,
      );
      expect(find.text('Scan Front Side'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.bySemanticsLabel('Capture front of card'));
      await tester.pumpAndSettle();
      expect(find.text('Scan Back Side'), findsOneWidget);
      camera.text = backText;
      await tester.tap(find.bySemanticsLabel('Capture back of card'));
      await tester.pump();
      expect(result?.cardNumber, '4242424242424242');
      expect(result?.cvv, '123');
      expect(camera.closed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Automatic capture needs consecutive matching frames', (
    tester,
  ) async {
    final camera = FakeCameraSession();
    CreditCard? result;
    await mount(
      tester,
      factory: () => camera,
      onComplete: (card) => result = card,
    );
    camera.onText!(frontText);
    await tester.pump();
    expect(find.text('Scan Front Side'), findsOneWidget);
    camera.onText!('blur');
    camera.onText!(frontText);
    await tester.pump();
    expect(find.text('Scan Front Side'), findsOneWidget);
    camera.onText!(frontText);
    await tester.pumpAndSettle();
    expect(find.text('Scan Back Side'), findsOneWidget);
    camera.onText!(backText);
    camera.onText!(backText);
    await tester.pump();
    expect(result?.cvv, '123');
  });

  testWidgets(
    'Flash, gallery cancellation, gallery front, and retaking front',
    (tester) async {
      final cameras = <FakeCameraSession>[];
      String? selected;
      await mount(
        tester,
        factory: () {
          final camera = FakeCameraSession();
          cameras.add(camera);
          return camera;
        },
        pick: () async => selected,
      );
      await tester.tap(find.byTooltip('Turn flash on'));
      await tester.pump();
      expect(cameras.last.torch, isTrue);
      await tester.tap(find.byTooltip('Choose card photo'));
      await tester.pumpAndSettle();
      expect(cameras.first.closed, isTrue);
      expect(find.text('Scan Front Side'), findsOneWidget);
      selected = frontText;
      await tester.tap(find.byTooltip('Choose card photo'));
      await tester.pumpAndSettle();
      expect(find.text('Scan Back Side'), findsOneWidget);
      await tester.tap(find.byTooltip('Retake front'));
      await tester.pumpAndSettle();
      expect(find.text('Scan Front Side'), findsOneWidget);
      expect(cameras.last.onText, isNotNull);
    },
  );

  testWidgets('Permission error offers settings, gallery, and manual entry', (
    tester,
  ) async {
    await mount(
      tester,
      factory: () => FakeCameraSession(
        initializationError: CameraException('CameraAccessDenied', 'Denied'),
      ),
    );
    expect(find.text('Open Settings'), findsOneWidget);
    expect(find.text('Enter Card Manually'), findsOneWidget);
    expect(find.byTooltip('Choose card photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Camera releases on background and resumes with a fresh session',
    (tester) async {
      final cameras = <FakeCameraSession>[];
      await mount(
        tester,
        factory: () {
          final camera = FakeCameraSession();
          cameras.add(camera);
          return camera;
        },
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(cameras.single.closed, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(cameras.length, 2);
      expect(cameras.last.closed, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(cameras.last.closed, isTrue);
    },
  );

  testWidgets('Finishing OCR after leaving the screen cannot complete a scan', (
    tester,
  ) async {
    final camera = FakeCameraSession()..capture = Completer<String>();
    var completed = false;
    await mount(
      tester,
      factory: () => camera,
      onComplete: (_) => completed = true,
    );
    await tester.tap(find.bySemanticsLabel('Capture front of card'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    camera.capture!.complete(frontText);
    await tester.pump();
    expect(completed, isFalse);
    expect(camera.closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
