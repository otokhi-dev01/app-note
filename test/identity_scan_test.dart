import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/id_information_storage.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/profile/data/services/card_camera_session.dart';
import 'package:Note/features/profile/domain/entities/identity_document.dart';
import 'package:Note/features/profile/domain/entities/identity_scan_recognition.dart';
import 'package:Note/features/profile/domain/entities/mrz_reader.dart';
import 'package:Note/features/profile/domain/entities/identity_printed_text_reader.dart';
import 'package:Note/features/profile/data/services/identity_printed_text_service.dart';
import 'package:Note/features/profile/presentation/views/identity_details_edit_view.dart';
import 'package:identity_ocr/identity_ocr.dart';
import 'package:image/image.dart' as img;
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/repositories/identity_repository.dart';
import 'package:Note/features/profile/domain/repositories/profile_repository.dart';
import 'package:Note/features/profile/domain/usecases/identity_usecases.dart';
import 'package:Note/features/profile/domain/usecases/profile_usecases.dart';
import 'package:Note/features/profile/presentation/controllers/identity_scan_controller.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/features/profile/presentation/views/identity_camera_view.dart';

const _front = 'KINGDOM OF CAMBODIA\nIDENTITY CARD\n123456789\n12.08.1974';
const _mrz =
    'I<UTOD231458907<<<<<<<<<<<<<<<\n'
    '7408122F1204159UTO<<<<<<<<<<<6\n'
    'ERIKSSON<<ANNA<MARIA<<<<<<<<<<<';

class _Camera extends CardCameraSession {
  ValueChanged<String>? onText;
  Completer<String>? pending;
  int captures = 0;
  bool closed = false;
  @override
  Future<void> initialize() async {}
  @override
  Widget buildPreview() => const SizedBox.expand();
  @override
  Future<void> startDetection(ValueChanged<String> callback) async =>
      onText = callback;
  @override
  Future<void> stopDetection() async => onText = null;
  @override
  Future<String> capturePhoto() async {
    captures++;
    await stopDetection();
    return pending != null ? pending!.future : 'photo-$captures.jpg';
  }

  @override
  Future<void> dispose() async {
    closed = true;
    onText = null;
  }
}

class _IdentityRepo implements IdentityRepository {
  int scans = 0;
  @override
  Future<Result<NationalIdCard>> scanNationalId({
    required String frontImagePath,
    required String backImagePath,
  }) async {
    scans++;
    return const Err(ServerFailure('Unavailable'));
  }

  @override
  Future<Result<void>> uploadDocument(IdentityDocument document) =>
      throw StateError('A scan must not upload automatically');
}

class _ProfileRepo implements ProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FailingStorage extends IdInformationStorage {
  bool fail = true;
  @override
  Future<void> save({
    required String ownerKey,
    required String idNumber,
    required String name,
    required DateTime? dateOfBirth,
    String placeOfBirth = '',
    String currentAddress = '',
    DateTime? expiryDate,
    NationalIdCard? scannedCard,
  }) {
    if (fail) throw const FileSystemException('Storage unavailable');
    return super.save(
      ownerKey: ownerKey,
      idNumber: idNumber,
      name: name,
      dateOfBirth: dateOfBirth,
      placeOfBirth: placeOfBirth,
      currentAddress: currentAddress,
      expiryDate: expiryDate,
      scannedCard: scannedCard,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory fixtureDirectory;
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('identity_scan_test_');
    fixtureDirectory = dir;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir.path,
        );
    await GetStorage.init();
  });
  tearDownAll(() async {
    if (fixtureDirectory.existsSync()) {
      await fixtureDirectory.delete(recursive: true);
    }
  });
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    Get.reset();
  });

  test('Automatic detection rejects blur, wrong side and corrupt MRZ', () {
    expect(IdentityScanRecognition.candidate(_front, front: true), isNotNull);
    expect(
      IdentityScanRecognition.candidate(
        'Receipt 123456789 12.08.1974',
        front: true,
      ),
      isNull,
    );
    expect(IdentityScanRecognition.candidate(_mrz, front: true), isNull);
    expect(IdentityScanRecognition.candidate(_front, front: false), isNull);
    expect(IdentityScanRecognition.candidate(_mrz, front: false), isNotNull);
    expect(
      IdentityScanRecognition.candidate(
        _mrz.replaceFirst('7408122', '7408120'),
        front: false,
      ),
      isNull,
    );
    expect(
      MrzReader.parse(
        _mrz,
      )!.copyWith(dateOfBirth: '31-02-2000').dateOfBirthAsDate,
      isNull,
    );
  });

  Future<void> mount(
    WidgetTester tester,
    _Camera camera,
    List<String> front,
    List<String> back,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IdentityCameraView(
          createSession: (_) => camera,
          onFrontCaptured: front.add,
          onBackCaptured: back.add,
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Stable front and back frames capture once per side', (
    tester,
  ) async {
    final camera = _Camera();
    final front = <String>[], back = <String>[];
    await mount(tester, camera, front, back);
    final staleFrontCallback = camera.onText!;
    camera.onText!(_front);
    camera.onText!('blur');
    camera.onText!(_front);
    await tester.pump();
    expect(front, isEmpty);
    camera.onText!(_front);
    await tester.pump();
    expect(front, ['photo-1.jpg']);
    staleFrontCallback(_front);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();
    camera.onText!(_mrz);
    camera.onText!(_mrz);
    await tester.pump();
    expect(back, ['photo-2.jpg']);
    expect(camera.captures, 2);
    expect(camera.closed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Leaving during capture cannot accept a late photo', (
    tester,
  ) async {
    final camera = _Camera()..pending = Completer<String>();
    final front = <String>[], back = <String>[];
    await mount(tester, camera, front, back);
    camera.onText!(_front);
    camera.onText!(_front);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    camera.pending!.complete('late.jpg');
    await tester.pump();
    expect(front, isEmpty);
    expect(back, isEmpty);
    expect(camera.closed, isTrue);
    expect(tester.takeException(), isNull);
  });

  ProfileController profile(
    SessionStorage session, {
    IdInformationStorage idStorage = const IdInformationStorage(),
  }) {
    Get.put(GuestModeService());
    final repository = _ProfileRepo();
    return Get.put(
      ProfileController(
        updateUserName: UpdateUserName(repository),
        updateProfileImage: UpdateProfileImage(repository),
        session: session,
        idStorage: idStorage,
      ),
    );
  }

  test(
    'MRZ scan saves profile immediately and survives storage reload',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final details = profile(session);
      final repository = _IdentityRepo();
      final scan = IdentityScanController(
        ScanNationalId(repository),
        recognizePrintedText: (_) async => '',
        recognizeText: (_) async => _mrz,
        iosLicenseKey: '',
        androidLicenseKey: '',
      );
      await scan.onStartScan();
      scan.onFrontCaptured('front.jpg');
      await scan.onBackCaptured('back.jpg');
      expect(repository.scans, 0);
      expect(scan.savedToProfile.value, isTrue);
      expect(details.userIdNumber.value, 'D23145890');
      expect(details.userIdName.value, 'ERIKSSON ANNA MARIA');
      expect(details.userDateOfBirth.value, DateTime(1974, 8, 12));
      final stored = await const IdInformationStorage().read('id:one');
      expect(stored.idNumber, details.userIdNumber.value);
      expect(stored.name, details.userIdName.value);
      expect(stored.expiryDate, DateTime(2012, 4, 15));
    },
  );

  test(
    'A new partial ID does not inherit another card details or invent DOB',
    () async {
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final details = profile(session);
      await details.applyScannedIdInformation(
        idNumber: 'old',
        name: 'OLD NAME',
        dateOfBirth: DateTime(1990),
        currentAddress: 'Old address',
      );
      await details.applyScannedIdInformation(
        idNumber: 'new',
        name: 'NEW NAME',
      );
      expect(details.userDateOfBirth.value, isNull);
      expect(details.userCurrentAddress.value, isEmpty);
      final stored = await const IdInformationStorage().read('id:one');
      expect(stored.dateOfBirth, isNull);
      expect(stored.currentAddress, isEmpty);
    },
  );

  test(
    'Changing account during OCR prevents saving to either profile',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      profile(session);
      final ocr = Completer<String>();
      final scan = IdentityScanController(
        ScanNationalId(_IdentityRepo()),
        recognizePrintedText: (_) async => '',
        recognizeText: (_) => ocr.future,
        iosLicenseKey: '',
        androidLicenseKey: '',
      );
      await scan.onStartScan();
      scan.onFrontCaptured('front.jpg');
      final pending = scan.onBackCaptured('back.jpg');
      session.user.value = const UserData(id: 'two');
      ocr.complete(_mrz);
      await pending;
      expect(scan.savedToProfile.value, isFalse);
      expect(scan.card.value, isNull);
      expect(
        (await const IdInformationStorage().read('id:one')).idNumber,
        isEmpty,
      );
      expect(
        (await const IdInformationStorage().read('id:two')).idNumber,
        isEmpty,
      );
    },
  );
  test(
    'Save failure keeps the scan and allows retry without rescanning',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final storage = _FailingStorage();
      final details = profile(session, idStorage: storage);
      final scan = IdentityScanController(
        ScanNationalId(_IdentityRepo()),
        recognizePrintedText: (_) async => '',
        recognizeText: (_) async => _mrz,
        iosLicenseKey: '',
        androidLicenseKey: '',
      );
      await scan.onStartScan();
      scan.onFrontCaptured('front.jpg');
      await scan.onBackCaptured('back.jpg');
      expect(scan.savedToProfile.value, isFalse);
      expect(scan.card.value?.idNumber, 'D23145890');
      expect(details.userIdNumber.value, isEmpty);
      storage.fail = false;
      // The public save operation used by the retry path accepts the retained scan.
      final card = scan.card.value!;
      expect(
        await details.applyScannedIdInformation(
          idNumber: card.idNumber,
          name: card.nameLatin,
          dateOfBirth: card.dateOfBirthAsDate,
          expectedOwnerKey: 'id:one',
        ),
        isTrue,
      );
      expect((await storage.read('id:one')).idNumber, 'D23145890');
    },
  );
  const printedFront =
      'គោត្តនាមនិងនាម៖ សុខ សុភា\n'
      'ថ្ងៃខែឆ្នាំកំណើត៖ 12.08.1974\n'
      'ទីកន្លែងកំណើត៖ ភូមិថ្មី\nឃុំថ្មី ខេត្តកណ្ដាល\n'
      'ភេទ៖ ស្រី';
  const printedBack =
      'អាសយដ្ឋានបច្ចុប្បន្ន៖ សង្កាត់ទឹកល្អក់\n'
      'ខណ្ឌទួលគោក រាជធានីភ្នំពេញ\n'
      'សុពលភាព៖ 15.04.2032';

  test(
    'Printed Khmer fields include multiline addresses and stop at next label',
    () {
      final mrz = MrzReader.parse(_mrz)!;
      final front = IdentityPrintedTextReader.enrich(mrz, printedFront);
      final card = IdentityPrintedTextReader.enrich(front, printedBack);
      expect(card.nameKhmer, 'សុខ សុភា');
      expect(card.placeOfBirthKhmer, 'ភូមិថ្មី ឃុំថ្មី ខេត្តកណ្ដាល');
      expect(
        card.currentAddressKhmer,
        'សង្កាត់ទឹកល្អក់ ខណ្ឌទួលគោក រាជធានីភ្នំពេញ',
      );
      expect(card.dateOfBirth, mrz.dateOfBirth);
      expect(card.idNumber, mrz.idNumber);
      final spaced = IdentityPrintedTextReader.enrich(
        mrz,
        'ទី កន្លែង កំណើត៖ កណ្ដាល\nភេទ៖ ប្រុស',
      );
      expect(spaced.placeOfBirthKhmer, 'កណ្ដាល');
      final english = IdentityPrintedTextReader.enrich(
        mrz,
        'Place of Birth: Kandal\nCurrent Address: Phnom Penh\n$_mrz',
      );
      expect(english.placeOfBirthEnglish, 'Kandal');
      expect(english.currentAddressEnglish, 'Phnom Penh');
    },
  );

  test(
    'Both scanned addresses persist and restore on Khmer ID screen',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final details = profile(session);
      var printed = true;
      IdentityScanController controller() => IdentityScanController(
        ScanNationalId(_IdentityRepo()),
        recognizeText: (_) async => _mrz,
        recognizePrintedText: (path) async => !printed
            ? ''
            : path == 'front.jpg'
            ? printedFront
            : printedBack,
        iosLicenseKey: '',
        androidLicenseKey: '',
      );
      var scan = Get.put(controller());
      await scan.onStartScan();
      scan.onFrontCaptured('front.jpg');
      await scan.onBackCaptured('back.jpg');
      expect(details.userPlaceOfBirth.value, contains('ខេត្តកណ្ដាល'));
      expect(details.userCurrentAddress.value, contains('រាជធានីភ្នំពេញ'));
      final saved = await const IdInformationStorage().readCard('id:one');
      expect(saved?.nameKhmer, 'សុខ សុភា');
      expect(saved?.placeOfBirthKhmer, scan.card.value?.placeOfBirthKhmer);
      await Get.delete<IdentityScanController>();
      scan = Get.put(controller());
      expect(scan.savedToProfile.value, isTrue);
      expect(scan.card.value?.currentAddressKhmer, contains('រាជធានីភ្នំពេញ'));
      expect(
        await scan.saveCorrections(
          scan.card.value!.copyWith(
            placeOfBirthKhmer: 'ខេត្តសៀមរាប',
            currentAddressKhmer: 'រាជធានីភ្នំពេញ',
          ),
        ),
        isTrue,
      );
      expect(details.userPlaceOfBirth.value, 'ខេត្តសៀមរាប');
      expect(details.userCurrentAddress.value, 'រាជធានីភ្នំពេញ');
      printed = false;
      await scan.onStartScan();
      scan.onFrontCaptured('front.jpg');
      await scan.onBackCaptured('back.jpg');
      expect(scan.card.value?.placeOfBirthKhmer, 'ខេត្តសៀមរាប');
      // A profile edit must also update the already-open card screen.
      await details.applyScannedIdInformation(
        idNumber: 'D23145890',
        name: 'ERIKSSON ANNA MARIA',
        placeOfBirth: 'Battambang',
        currentAddress: 'Kampot',
      );
      expect(scan.card.value?.displayPlaceOfBirth, 'Battambang');
      expect(scan.card.value?.displayCurrentAddress, 'Kampot');
      expect(scan.card.value?.nameKhmer, 'សុខ សុភា');
      expect(
        await scan.saveCorrections(
          scan.card.value!.copyWith(currentAddressEnglish: ''),
        ),
        isTrue,
      );
      expect(details.userCurrentAddress.value, isEmpty);
      await Get.delete<IdentityScanController>();
      await Get.delete<ProfileController>();
      final restoredProfile = profile(session);
      final restoredScan = Get.put(controller());
      await expectLater(
        restoredProfile.identityCard.stream,
        emits(isA<NationalIdCard>()),
      );
      expect(restoredScan.card.value?.placeOfBirthEnglish, 'Battambang');
      expect(restoredScan.card.value?.displayCurrentAddress, isEmpty);
      expect(restoredScan.card.value?.nameKhmer, 'សុខ សុភា');
    },
  );

  test('Saved photo previews survive temporary photo deletion', () async {
    final dir = await Directory.systemTemp.createTemp('id_photos_');
    final front = await File('${dir.path}/front.jpg').writeAsBytes([1, 2, 3]);
    final card = MrzReader.parse(_mrz)!.copyWith(
      frontImagePath: front.path,
      placeOfBirthKhmer: 'កណ្ដាល',
      currentAddressKhmer: 'ភ្នំពេញ',
    );
    const storage = IdInformationStorage();
    await storage.save(
      ownerKey: 'id:photos',
      idNumber: card.idNumber,
      name: card.nameLatin,
      dateOfBirth: card.dateOfBirthAsDate,
      scannedCard: card,
    );
    await dir.delete(recursive: true);
    final restored = (await storage.readCard('id:photos'))!;
    expect(await File(restored.frontImagePath!).readAsBytes(), [1, 2, 3]);
    expect(restored.currentAddressKhmer, 'ភ្នំពេញ');
    expect((await storage.readCard('id:other')), isNull);
  });

  testWidgets(
    'Card editor saves separate Khmer birth place and current address',
    (tester) async {
      NationalIdCard? saved;
      await tester.pumpWidget(
        GetMaterialApp(
          home: IdentityDetailsEditView(
            card: MrzReader.parse(_mrz)!,
            onSave: (card) async {
              saved = card;
              return false;
            },
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('identity_birth_place_khmer')),
        'កណ្ដាល',
      );
      await tester.enterText(
        find.byKey(const ValueKey('identity_address_khmer')),
        'ភ្នំពេញ',
      );
      final save = find.widgetWithText(FilledButton, 'identity_save_details');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(saved?.placeOfBirthKhmer, 'កណ្ដាល');
      expect(saved?.currentAddressKhmer, 'ភ្នំពេញ');
      expect(find.byType(IdentityDetailsEditView), findsOneWidget);
    },
  );

  test(
    'Offline OCR prepares both bundled models and removes its working photo',
    () async {
      final dir = await Directory.systemTemp.createTemp('id_ocr_input_');
      final source = await File(
        '${dir.path}/input.png',
      ).writeAsBytes(img.encodePng(img.Image(width: 20, height: 10)));
      String? workingPhoto;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(IdentityOcr.channel, (call) async {
            final args = Map<String, dynamic>.from(call.arguments);
            workingPhoto = args['path'];
            expect(File(workingPhoto!).existsSync(), isTrue);
            for (final lang in ['khm', 'eng']) {
              expect(
                File(
                  '${args['dataPath']}/tessdata/$lang.traineddata',
                ).lengthSync(),
                greaterThan(1000000),
              );
            }
            return printedFront;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(IdentityOcr.channel, null),
      );
      expect(
        await IdentityPrintedTextService.recognize(source.path),
        printedFront,
      );
      expect(File(workingPhoto!).existsSync(), isFalse);
      expect(source.existsSync(), isTrue);
      await dir.delete(recursive: true);
    },
  );
}
