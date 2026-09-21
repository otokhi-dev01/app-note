import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/id_information_storage.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/profile/data/services/card_camera_session.dart';
import 'package:Note/features/profile/data/services/identity_image_service.dart';
import 'package:Note/features/profile/presentation/views/identity_image_view.dart';
import 'package:Note/features/profile/presentation/views/profile_view.dart';
import 'package:Note/routes/app_pages.dart';
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
import 'package:Note/features/profile/presentation/views/identity_scan_view.dart';

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
    expect(
      IdentityScanRecognition.candidate('PASSPORT\n$_front', front: true),
      isNull,
    );
    expect(
      IdentityScanRecognition.candidate('$_front\nBROKEN<<MRZ', front: true),
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

  testWidgets('Front-only identity camera retries and never switches to back', (
    tester,
  ) async {
    final camera = _Camera();
    final front = <String>[], back = <String>[];
    var validations = 0;
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: IdentityCameraView(
          singleSideFront: true,
          createSession: (_) => camera,
          validateCapture: (_) async => ++validations > 1,
          onFrontCaptured: front.add,
          onBackCaptured: back.add,
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    camera.onText!(_mrz);
    camera.onText!(_mrz);
    await tester.pump();
    expect(camera.captures, 0);
    camera.onText!(_front);
    camera.onText!(_front);
    await tester.pumpAndSettle();
    expect(front, isEmpty);
    expect(back, isEmpty);
    expect(camera.closed, isFalse);
    expect(find.text('identity_front_scan_retry'.tr), findsOneWidget);
    camera.onText!(_front);
    camera.onText!(_front);
    await tester.pump();
    expect(front, ['photo-2.jpg']);
    expect(back, isEmpty);
    expect(camera.closed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back-only identity camera detects only the selected side', (
    tester,
  ) async {
    final camera = _Camera();
    final front = <String>[], back = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: IdentityCameraView(
          singleSideFront: false,
          createSession: (_) => camera,
          validateCapture: (_) async => true,
          onFrontCaptured: front.add,
          onBackCaptured: back.add,
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    camera.onText!(_front);
    camera.onText!(_front);
    await tester.pump();
    expect(camera.captures, 0);
    camera.onText!(_mrz);
    camera.onText!(_mrz);
    await tester.pump();
    expect(front, isEmpty);
    expect(back, ['photo-1.jpg']);
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

  test('Adding identities preserves full old snapshots and photos', () async {
    const storage = IdInformationStorage();
    final dir = await Directory.systemTemp.createTemp('id_collection_');
    final photo = await File('${dir.path}/front.jpg').writeAsBytes([4, 5, 6]);
    final original = MrzReader.parse(_mrz)!.copyWith(
      nameKhmer: 'សុខ សុភា',
      placeOfBirthKhmer: 'កណ្ដាល',
      currentAddressEnglish: 'Phnom Penh',
      frontImagePath: photo.path,
      backImagePath: photo.path,
      validityYears: 7,
      chipIntegrityPercent: 98,
    );
    await storage.save(
      ownerKey: 'id:one',
      idNumber: original.idNumber,
      name: original.nameLatin,
      dateOfBirth: original.dateOfBirthAsDate,
      expiryDate: original.expiryDateAsDate,
      scannedCard: original,
    );
    // Simulate the exact single-card format used before collections existed.
    final key =
        'profile_id_${base64Url.encode(utf8.encode('id:one')).replaceAll('=', '')}_snapshot';
    const secure = FlutterSecureStorage();
    final oldSnapshot =
        jsonDecode((await secure.read(key: key))!) as Map<String, dynamic>;
    oldSnapshot.remove('cards');
    await secure.write(key: key, value: jsonEncode(oldSnapshot));
    final expectedCard = (await storage.readCard('id:one'))!.toJson();
    final expectedProfile = await storage.read('id:one');
    await storage.save(
      ownerKey: 'id:one',
      idNumber: 'second',
      name: 'SECOND',
      dateOfBirth: DateTime(2000),
    );
    await dir.delete(recursive: true);
    final cards = await const IdInformationStorage().readCards('id:one');
    expect(cards.map((card) => card.idNumber), [original.idNumber, 'second']);
    expect(cards.first.toJson(), expectedCard);
    expect(await File(cards.first.frontImagePath!).readAsBytes(), [4, 5, 6]);
    expect(await File(cards.first.backImagePath!).readAsBytes(), [4, 5, 6]);
    expect(await storage.readCards('id:other'), isEmpty);
    await storage.selectCard('id:one', original.idNumber);
    expect(await storage.read('id:one'), expectedProfile);
    await storage.deleteCard('id:one', 'second');
    expect((await storage.readCards('id:one')).single.toJson(), expectedCard);
    expect(File(cards.first.frontImagePath!).existsSync(), isTrue);
    await storage.deleteCard('id:one', original.idNumber);
    expect(await storage.readCards('id:one'), isEmpty);
    expect(await storage.readCard('id:one'), isNull);
  });

  test('Legacy profile remains selectable after adding another card', () async {
    final prefix =
        'profile_id_${base64Url.encode(utf8.encode('guest')).replaceAll('=', '')}_';
    FlutterSecureStorage.setMockInitialValues({
      '${prefix}number': 'legacy',
      '${prefix}name': 'OLD NAME',
      '${prefix}date_of_birth': '1990-01-02',
      '${prefix}place_of_birth': 'Kandal',
      '${prefix}current_address': 'Phnom Penh',
      '${prefix}expiry_date': '2030-01-02',
    });
    const storage = IdInformationStorage();
    final old = await storage.read('guest');
    await storage.save(
      ownerKey: 'guest',
      idNumber: 'new',
      name: 'NEW NAME',
      dateOfBirth: null,
    );
    expect((await storage.readCards('guest')).length, 2);
    await storage.selectCard('guest', 'legacy');
    expect(await storage.read('guest'), old);
  });

  test(
    'Rescanning an older identity preserves its fields without duplicates',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final details = profile(session);
      final original = MrzReader.parse(_mrz)!.copyWith(
        nameKhmer: 'សុខ សុភា',
        placeOfBirthKhmer: 'កណ្ដាល',
        currentAddressEnglish: 'Old address',
      );
      await details.applyScannedIdInformation(
        idNumber: original.idNumber,
        name: original.nameLatin,
        scannedCard: original,
      );
      await details.applyScannedIdInformation(
        idNumber: 'second',
        name: 'SECOND',
      );
      final scan = Get.put(
        IdentityScanController(
          ScanNationalId(_IdentityRepo()),
          recognizeText: (_) async => _mrz,
          recognizePrintedText: (_) async => '',
          iosLicenseKey: '',
          androidLicenseKey: '',
        ),
      );
      await scan.onAddIdentity();
      scan.onFrontCaptured('front.jpg');
      await scan.onBackCaptured('back.jpg');
      expect(details.identityCards.length, 2);
      expect(scan.card.value?.currentAddressEnglish, 'Old address');
      expect(scan.card.value?.nameKhmer, original.nameKhmer);
      await scan.onSelectIdentity('second');
      expect(scan.card.value?.nameLatin, 'SECOND');
      await scan.onDeleteInfo();
      expect(details.identityCards.single.idNumber, original.idNumber);
      expect(scan.card.value?.idNumber, original.idNumber);
      session.user.value = const UserData(id: 'two');
      expect(details.identityCards, isEmpty);
      expect(scan.card.value, isNull);
    },
  );

  Future<NationalIdCard> seedImageCard(ProfileController details) async {
    final front = await File(
      '${fixtureDirectory.path}/front.png',
    ).writeAsBytes(img.encodePng(img.Image(width: 160, height: 100)));
    final back = await File(
      '${fixtureDirectory.path}/back.png',
    ).writeAsBytes(img.encodePng(img.Image(width: 200, height: 125)));
    final card = MrzReader.parse(_mrz)!.copyWith(
      nameKhmer: 'សុខ សុភា',
      placeOfBirthKhmer: 'កណ្ដាល',
      currentAddressEnglish: 'Saved address',
      frontImagePath: front.path,
      backImagePath: back.path,
    );
    await details.applyScannedIdInformation(
      idNumber: card.idNumber,
      name: card.nameLatin,
      dateOfBirth: card.dateOfBirthAsDate,
      expiryDate: card.expiryDateAsDate,
      scannedCard: card,
    );
    return details.identityCard.value!;
  }

  test(
    'Replacing each image preserves other images, fields, and identities',
    () async {
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final details = profile(session);
      await details.applyScannedIdInformation(idNumber: 'other', name: 'OTHER');
      final original = await seedImageCard(details);
      final replacement = await File(
        '${fixtureDirectory.path}/replacement.png',
      ).writeAsBytes(img.encodePng(img.Image(width: 320, height: 200)));
      final scan = Get.put(
        IdentityScanController(
          ScanNationalId(_IdentityRepo()),
          scanCardImage: () async => replacement.path,
          recognizeText: (_) async => _front,
        ),
      );
      await scan.onScanImage(front: true);
      final updatedFront = details.identityCard.value!;
      expect(updatedFront.frontImagePath, isNot(original.frontImagePath));
      expect(
        updatedFront.toJson(),
        original.copyWith(frontImagePath: updatedFront.frontImagePath).toJson(),
      );
      expect(
        await File(updatedFront.frontImagePath!).readAsBytes(),
        await replacement.readAsBytes(),
      );
      await scan.onScanImage(front: false);
      final updatedBack = details.identityCard.value!;
      expect(updatedBack.backImagePath, isNot(original.backImagePath));
      expect(
        updatedBack.toJson(),
        updatedFront
            .copyWith(backImagePath: updatedBack.backImagePath)
            .toJson(),
      );
      expect(details.identityCards.length, 2);
      expect(details.identityCards.first.nameLatin, 'OTHER');
      await replacement.delete();
      final restored = (await const IdInformationStorage().readCard('id:one'))!;
      expect(restored.toJson(), updatedBack.toJson());
      expect(File(restored.frontImagePath!).existsSync(), isTrue);
      expect(File(restored.backImagePath!).existsSync(), isTrue);
      expect(scan.savedToProfile.value, isTrue);
    },
  );

  test(
    'Front scan retries wrong-side and unreadable captures before saving',
    () async {
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final details = profile(session);
      final original = await seedImageCard(details);
      var captures = 0;
      var reads = 0;
      final texts = [_mrz, 'A blurred receipt', _front];
      final scan = Get.put(
        IdentityScanController(
          ScanNationalId(_IdentityRepo()),
          scanCardImage: () async {
            expect(details.identityCard.value!.toJson(), original.toJson());
            captures++;
            return original.frontImagePath;
          },
          recognizeText: (_) async => texts[reads++],
          recognizePrintedText: (_) async => texts[reads - 1],
        ),
      );
      await scan.onScanImage(front: true);
      expect(captures, 3);
      expect(scan.savedToProfile.value, isTrue);
      expect(scan.card.value!.backImagePath, original.backImagePath);
      expect(scan.isLoading.value, isFalse);
    },
  );

  test(
    'Front retry can be cancelled without replacing the saved photo',
    () async {
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final details = profile(session);
      final original = await seedImageCard(details);
      var captures = 0;
      final scan = Get.put(
        IdentityScanController(
          ScanNationalId(_IdentityRepo()),
          scanCardImage: () async =>
              ++captures == 1 ? original.backImagePath : null,
          recognizeText: (_) async => _mrz,
          recognizePrintedText: (_) async => _mrz,
        ),
      );
      await scan.onScanImage(front: true);
      expect(captures, 2);
      expect(details.identityCard.value!.toJson(), original.toJson());
      expect(scan.card.value!.toJson(), original.toJson());
      expect(scan.isLoading.value, isFalse);
    },
  );

  test('Front scan saves a new card without requiring the back', () async {
    final session = SessionStorage()..user.value = const UserData(id: 'one');
    final details = profile(session);
    final photo = await File(
      '${fixtureDirectory.path}/front-only.png',
    ).writeAsBytes(img.encodePng(img.Image(width: 160, height: 100)));
    var captures = 0;
    final repo = _IdentityRepo();
    final scan = Get.put(
      IdentityScanController(
        ScanNationalId(repo),
        scanCardImage: () async {
          captures++;
          return photo.path;
        },
        recognizeText: (_) async =>
            throw const FormatException('OCR unavailable'),
        recognizePrintedText: (_) async => _front,
      ),
    );
    await scan.onScanImage(front: true);
    expect(captures, 1);
    expect(scan.currentStep.value, IdentityScanStep.main);
    expect(scan.imagePath(front: true), isNot(photo.path));
    expect(scan.hasImage(front: true), isTrue);
    expect(scan.hasImage(front: false), isFalse);
    expect(details.identityCard.value!.idNumber, '123456789');
    expect(scan.savedToProfile.value, isTrue);
    final bytes = await photo.readAsBytes();
    await photo.delete();
    final restored = (await const IdInformationStorage().readCard('id:one'))!;
    expect(await File(restored.frontImagePath!).readAsBytes(), bytes);
    expect(restored.backImagePath, isNull);
    expect(restored.dateOfBirth, isEmpty);
    await Get.delete<IdentityScanController>();
    final reopened = Get.put(IdentityScanController(ScanNationalId(repo)));
    expect(reopened.hasImage(front: true), isTrue);
    expect(reopened.savedToProfile.value, isTrue);
    expect(repo.scans, 0);
    session.user.value = const UserData(id: 'two');
    expect(reopened.imagePath(front: true), isNull);
  });

  test(
    'Saved front downloads immediately and accepts a back image later',
    () async {
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final details = profile(session);
      final frontPhoto = await File(
        '${fixtureDirectory.path}/draft-front.png',
      ).writeAsBytes(img.encodePng(img.Image(width: 160, height: 100)));
      final backPhoto = await File(
        '${fixtureDirectory.path}/draft-back.png',
      ).writeAsBytes(img.encodePng(img.Image(width: 160, height: 100)));
      var captures = 0;
      final exports = <IdentityCardExport>[];
      final scan = Get.put(
        IdentityScanController(
          ScanNationalId(_IdentityRepo()),
          scanCardImage: () async =>
              ++captures == 1 ? frontPhoto.path : backPhoto.path,
          recognizeText: (path) async =>
              path == frontPhoto.path ? _front : _mrz,
          recognizePrintedText: (_) async => '',
          saveExport: (export) async {
            exports.add(export);
            return null;
          },
        ),
      );
      await scan.onScanImage(front: true);
      expect(details.identityCard.value!.idNumber, '123456789');
      expect(scan.savedToProfile.value, isTrue);
      await scan.onDownloadCard(front: true);
      expect(exports.single.fileName, 'identity_front.png');
      expect(exports.single.bytes, await frontPhoto.readAsBytes());
      await scan.onDownloadCard();
      expect(exports.last.fileName, 'identity_card.pdf');
      expect(latin1.decode(exports.last.bytes), startsWith('%PDF-'));
      await scan.onScanImage(front: false);
      expect(captures, 2);
      expect(scan.savedToProfile.value, isTrue);
      expect(details.identityCard.value!.idNumber, '123456789');
      expect(scan.hasImage(front: true), isTrue);
      expect(scan.hasImage(front: false), isTrue);
      expect(scan.isLoading.value, isFalse);
    },
  );

  test('New front save failure can be retried without a back scan', () async {
    final session = SessionStorage()..user.value = const UserData(id: 'one');
    final storage = _FailingStorage()..fail = true;
    final details = profile(session, idStorage: storage);
    final photo = await File(
      '${fixtureDirectory.path}/new-front-retry.png',
    ).writeAsBytes(img.encodePng(img.Image(width: 160, height: 100)));
    final scan = Get.put(
      IdentityScanController(
        ScanNationalId(_IdentityRepo()),
        scanCardImage: () async => photo.path,
        recognizeText: (_) async => _front,
      ),
    );
    await scan.onScanImage(front: true);
    expect(scan.savedToProfile.value, isFalse);
    expect(details.identityCard.value, isNull);
    expect(scan.card.value!.frontImagePath, photo.path);
    storage.fail = false;
    await scan.onSaveCard();
    expect(scan.savedToProfile.value, isTrue);
    expect((await storage.readCard('id:one'))!.backImagePath, isNull);
    expect(scan.hasImage(front: true), isTrue);
  });

  test('Front validation cannot save after the account changes', () async {
    final session = SessionStorage()..user.value = const UserData(id: 'one');
    final details = profile(session);
    final original = await seedImageCard(details);
    final reading = Completer<String>();
    final started = Completer<void>();
    final scan = Get.put(
      IdentityScanController(
        ScanNationalId(_IdentityRepo()),
        scanCardImage: () async => original.frontImagePath,
        recognizeText: (_) {
          started.complete();
          return reading.future;
        },
      ),
    );
    final pending = scan.onScanImage(front: true);
    await started.future;
    session.user.value = const UserData(id: 'two');
    reading.complete(_front);
    await pending;
    expect(scan.card.value, isNull);
    expect(await const IdInformationStorage().readCard('id:two'), isNull);
    expect(
      (await const IdInformationStorage().readCard('id:one'))!.toJson(),
      original.toJson(),
    );
    expect(scan.isLoading.value, isFalse);
  });

  test(
    'Cancelled and late photo scans cannot overwrite a saved identity',
    () async {
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final details = profile(session);
      final original = await seedImageCard(details);
      Completer<String?>? result;
      final scan = Get.put(
        IdentityScanController(
          ScanNationalId(_IdentityRepo()),
          scanCardImage: () async => result?.future,
        ),
      );
      await scan.onScanImage(front: true);
      expect(scan.card.value?.toJson(), original.toJson());
      expect(scan.savedToProfile.value, isTrue);
      result = Completer<String?>();
      final pending = scan.onScanImage(front: false);
      session.user.value = const UserData(id: 'two');
      result.complete(original.frontImagePath);
      await pending;
      expect(scan.card.value, isNull);
      expect(
        (await const IdInformationStorage().readCard('id:one'))!.toJson(),
        original.toJson(),
      );
      expect(await const IdInformationStorage().readCard('id:two'), isNull);
      expect(scan.isLoading.value, isFalse);
    },
  );

  test(
    'Failed image save preserves stored photos and can be retried',
    () async {
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final storage = _FailingStorage()..fail = false;
      final details = profile(session, idStorage: storage);
      final original = await seedImageCard(details);
      final replacement = await File(
        '${fixtureDirectory.path}/retry.png',
      ).writeAsBytes(img.encodePng(img.Image(width: 300, height: 190)));
      final scan = Get.put(
        IdentityScanController(
          ScanNationalId(_IdentityRepo()),
          scanCardImage: () async => replacement.path,
        ),
      );
      storage.fail = true;
      await scan.onScanImage(front: false);
      expect(scan.savedToProfile.value, isFalse);
      expect(scan.card.value?.backImagePath, replacement.path);
      expect((await storage.readCard('id:one'))!.toJson(), original.toJson());
      storage.fail = false;
      await scan.onSaveCard();
      expect(scan.savedToProfile.value, isTrue);
      final restored = (await storage.readCard('id:one'))!;
      expect(restored.frontImagePath, original.frontImagePath);
      expect(
        await File(restored.backImagePath!).readAsBytes(),
        await replacement.readAsBytes(),
      );
    },
  );

  test(
    'Downloads preserve image bytes and export a printable identity record',
    () async {
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final details = profile(session);
      final original = await seedImageCard(details);
      final exports = <IdentityCardExport>[];
      final scan = Get.put(
        IdentityScanController(
          ScanNationalId(_IdentityRepo()),
          saveExport: (export) async {
            exports.add(export);
            return null; // Cancelling the destination must not change saved data.
          },
        ),
      );
      await scan.onDownloadCard(front: true);
      await scan.onDownloadCard(front: false);
      await scan.onDownloadCard();
      expect(exports.map((item) => item.fileName), [
        'identity_front.png',
        'identity_back.png',
        'identity_card.pdf',
      ]);
      expect(
        exports[0].bytes,
        await File(original.frontImagePath!).readAsBytes(),
      );
      expect(
        exports[1].bytes,
        await File(original.backImagePath!).readAsBytes(),
      );
      final artifactPath = Platform.environment['IDENTITY_PDF_REVIEW_PATH'];
      if (artifactPath != null) {
        await File(artifactPath).writeAsBytes(exports[2].bytes);
      }
      final pdf = latin1.decode(exports[2].bytes);
      expect(pdf, startsWith('%PDF-'));
      // Both images retain their source pixel dimensions in the exported PDF.
      expect(pdf, contains('/Width 160'));
      expect(pdf, contains('/Height 100'));
      expect(pdf, contains('/Width 200'));
      expect(pdf, contains('/Height 125'));
      expect(pdf, contains('/FontFile2'));
      expect(pdf, contains('/ToUnicode'));

      expect(
        (await const IdInformationStorage().readCard('id:one'))!.toJson(),
        original.toJson(),
      );
      expect(scan.isLoading.value, isFalse);
    },
  );

  testWidgets('Camera action opens the identity scanner and cancels cleanly', (
    tester,
  ) async {
    final session = SessionStorage()..user.value = const UserData(id: 'one');
    final details = profile(session);
    await tester.runAsync(() => seedImageCard(details));
    final original = details.identityCard.value!;
    final scan = Get.put(
      IdentityScanController(ScanNationalId(_IdentityRepo())),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(),
      ),
    );
    final capture = scan.onScanImage(front: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final camera = tester.widget<IdentityCameraView>(
      find.byType(IdentityCameraView),
    );
    expect(camera.singleSideFront, isTrue);
    expect(camera.validateCapture, isNotNull);
    camera.onCancel();
    await tester.pumpAndSettle();
    await capture;
    expect(find.byType(IdentityCameraView), findsNothing);
    expect(scan.isLoading.value, isFalse);
    expect(details.identityCard.value!.toJson(), original.toJson());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Image taps scan a side and expand opens the full-image viewer', (
    tester,
  ) async {
    final session = SessionStorage()..user.value = const UserData(id: 'one');
    final details = profile(session);
    await tester.runAsync(() => seedImageCard(details));
    var captures = 0;
    final scan = Get.put(
      IdentityScanController(
        ScanNationalId(_IdentityRepo()),
        scanCardImage: () async {
          captures++;
          return null;
        },
      ),
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const IdentityScanView(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('identity_scan_front')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('identity_scan_back')));
    await tester.pumpAndSettle();
    expect(captures, 2);
    expect(scan.savedToProfile.value, isTrue);
    await tester.tap(find.byKey(const ValueKey('identity_view_back')));
    await tester.pumpAndSettle();
    expect(find.byType(IdentityImageView), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    final fullImage = tester.widget<Image>(find.byType(Image));
    expect(fullImage.fit, BoxFit.contain);
    expect(
      (fullImage.image as FileImage).file.path,
      scan.card.value?.backImagePath,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Card tabs publish all selected information on the profile screen',
    (tester) async {
      final session = SessionStorage()..user.value = const UserData(id: 'one');
      final details = profile(session);
      late NationalIdCard first;
      late NationalIdCard second;
      await tester.runAsync(() async {
        first = await seedImageCard(details);
        final other = first.copyWith(
          idNumber: 'SECOND-ID',
          nameLatin: 'SECOND PERSON',
          nameKhmer: 'ចាន់ ដារ៉ា',
          dateOfBirth: '03-04-1995',
          expiryDate: '04-05-2035',
          placeOfBirthKhmer: 'សៀមរាប',
          placeOfBirthEnglish: 'Siem Reap',
          currentAddressKhmer: 'ភ្នំពេញ',
          currentAddressEnglish:
              'A long second address with the full village, commune, district and province',
          mrzLines: ['SECOND CARD MRZ'],
          frontImagePath: first.backImagePath,
          backImagePath: first.frontImagePath,
        );
        await details.applyScannedIdInformation(
          idNumber: other.idNumber,
          name: other.nameLatin,
          dateOfBirth: other.dateOfBirthAsDate,
          expiryDate: other.expiryDateAsDate,
          scannedCard: other,
        );
        second = details.identityCard.value!;
      });
      // Observers must never receive a selected card with stale profile fields.
      final profileWorker = ever(details.identityCard, (card) {
        if (card == null) return;
        expect(details.userIdNumber.value, card.idNumber);
        expect(details.userIdName.value, card.nameLatin);
        expect(details.userDateOfBirth.value, card.dateOfBirthAsDate);
        expect(details.userPlaceOfBirth.value, card.displayPlaceOfBirth);
        expect(details.userCurrentAddress.value, card.displayCurrentAddress);
        expect(details.userIdExpiryDate.value, card.expiryDateAsDate);
      });
      addTearDown(profileWorker.dispose);
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const ProfileView(),
          getPages: [
            GetPage(
              name: Routes.IDENTITY_SCAN,
              page: () => const IdentityScanView(),
              binding: BindingsBuilder(() {
                Get.put(
                  IdentityScanController(ScanNationalId(_IdentityRepo())),
                );
              }),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      for (final (index, expected) in [first, second].indexed) {
        final link = find.text('Khmer National Identity Card');
        await tester.ensureVisible(link);
        await tester.pumpAndSettle();
        await tester.tap(link);
        await tester.pumpAndSettle();
        final scan = Get.find<IdentityScanController>();
        await tester.runAsync(() async {
          final selected = Completer<void>();
          final worker = ever(scan.isLoading, (busy) {
            if (!busy && !selected.isCompleted) selected.complete();
          });
          await tester.tap(
            find.byKey(ValueKey('identity_card_tab_${expected.idNumber}')),
          );
          await selected.future;
          worker.dispose();
        });
        await tester.pumpAndSettle();
        Get.back<void>();
        await tester.pumpAndSettle();
        final section = find.byKey(
          const ValueKey('profile_identity_information'),
        );
        for (final value in [
          'Card ${index + 1}',
          expected.idNumber,
          expected.nameLatin,
          expected.nameKhmer,
          expected.displayPlaceOfBirth,
          expected.displayCurrentAddress,
          expected.mrzLines.join('\n'),
          details.formattedDateOfBirth,
          details.formattedIdExpiryDate,
        ]) {
          expect(
            find.descendant(of: section, matching: find.text(value)),
            findsOneWidget,
          );
        }
        final address = tester.widget<Text>(
          find.descendant(
            of: section,
            matching: find.text(expected.displayCurrentAddress),
          ),
        );
        expect(address.maxLines, isNull);
        for (final front in [true, false]) {
          final image = tester.widget<Image>(
            find.byKey(
              ValueKey('profile_identity_${front ? 'front' : 'back'}'),
            ),
          );
          expect(
            (image.image as FileImage).file.path,
            front ? expected.frontImagePath : expected.backImagePath,
          );
        }
        await tester.runAsync(() async {
          final restored = await const IdInformationStorage().readCard(
            'id:one',
          );
          expect(restored?.toJson(), expected.toJson());
          final stored = await const IdInformationStorage().read('id:one');
          expect(stored.idNumber, expected.idNumber);
          expect(stored.currentAddress, expected.displayCurrentAddress);
        });
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Add starts a scan and cancellation keeps saved cards', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final session = SessionStorage()..user.value = const UserData(id: 'one');
    final details = profile(session);
    await tester.runAsync(() async {
      await details.applyScannedIdInformation(idNumber: 'first', name: 'FIRST');
      await details.applyScannedIdInformation(
        idNumber: 'second',
        name: 'SECOND',
      );
    });
    final scan = Get.put(
      IdentityScanController(
        ScanNationalId(_IdentityRepo()),
        iosLicenseKey: '',
        androidLicenseKey: '',
      ),
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const IdentityScanView(),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('identity_add_button')));
    expect(scan.currentStep.value, IdentityScanStep.scanning);
    // Cancel before pumping the native camera widget.
    scan.onCancelCamera();
    await tester.pumpAndSettle();
    expect(scan.card.value?.idNumber, 'second');
    expect(details.identityCards.length, 2);
    expect(find.text('Card 1'), findsOneWidget);
    expect(find.text('Card 2'), findsOneWidget);
    final firstTab = find.byKey(const ValueKey('identity_card_tab_first'));
    final secondTab = find.byKey(const ValueKey('identity_card_tab_second'));
    expect(tester.widget<ChoiceChip>(secondTab).selected, isTrue);
    await tester.runAsync(() async {
      final selected = Completer<void>();
      final worker = ever(scan.isLoading, (busy) {
        if (!busy && !selected.isCompleted) selected.complete();
      });
      await tester.tap(firstTab);
      await selected.future;
      worker.dispose();
    });
    await tester.pumpAndSettle();
    expect(scan.card.value?.idNumber, 'first');
    expect(tester.widget<ChoiceChip>(firstTab).selected, isTrue);
    expect(find.text('FIRST'), findsOneWidget);
    await tester.runAsync(() async {
      final selected = Completer<void>();
      final worker = ever(scan.isLoading, (busy) {
        if (!busy && !selected.isCompleted) selected.complete();
      });
      await tester.tap(secondTab);
      await selected.future;
      worker.dispose();
    });
    await tester.pumpAndSettle();
    expect(scan.card.value?.idNumber, 'second');
    expect(find.text('SECOND'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
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
