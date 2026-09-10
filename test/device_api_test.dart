import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/settings/data/datasources/device_remote_data_source.dart';
import 'package:Note/features/settings/data/repositories/device_repository_impl.dart';
import 'package:Note/features/settings/domain/entities/account_device.dart';
import 'package:Note/features/settings/domain/repositories/device_repository.dart';
import 'package:Note/features/settings/domain/usecases/get_devices.dart';
import 'package:Note/features/settings/presentation/controllers/device_controller.dart';
import 'package:Note/features/settings/presentation/views/settings_feature_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SessionStorage session;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    await GetStorage.init();
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    session = Get.put(SessionStorage());
    await session.loadSession();
  });
  tearDown(Get.reset);

  testWidgets(
    'device screen renders loading, retry, empty, and device details',
    (tester) async {
      session.token.value = 'token';
      final guestMode = Get.put(GuestModeService());
      guestMode.isGuestMode.value = false;
      final repository = _DevicesRepository();
      Get.put(
        DeviceController(
          getDevices: GetDevices(repository),
          session: session,
          guestMode: guestMode,
        ),
      );
      await tester.pumpWidget(
        LiquidGlassWidgets.wrap(
          brightnessResolver: Theme.maybeBrightnessOf,
          theme: GlassThemeData(
            light: const GlassThemeVariant(quality: GlassQuality.standard),
            dark: const GlassThemeVariant(quality: GlassQuality.standard),
          ),
          child: GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const DeviceSettingsView(),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repository.requests[0].complete(const Err(NetworkFailure()));
      await tester.pumpAndSettle();
      expect(find.text('No internet connection.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      repository.requests[1].complete(const Ok([]));
      await tester.pumpAndSettle();
      expect(find.text('No devices found.'), findsOneWidget);
      await tester.tap(find.byTooltip('Refresh devices'));
      await tester.pump();
      repository.requests[2].complete(
        const Ok([
          AccountDevice(
            id: 'phone',
            name: 'My iPhone',
            platform: 'iOS',
            appVersion: '1.0.2',
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('My iPhone'), findsOneWidget);
      expect(find.text('iOS • App 1.0.2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'GET devices uses the Chat URL, bearer token, and no request body',
    () async {
      session.token.value = 'test-token';
      final api = Get.put(ApiClient());
      final adapter = _DeviceAdapter();
      api.dio.httpClientAdapter = adapter;
      addTearDown(() => api.dio.close());
      final getDevices = GetDevices(
        DeviceRepositoryImpl(DeviceRemoteDataSource(api)),
      );
      final result = await getDevices(const NoParams());
      expect(result.failureOrNull, isNull);
      expect(result.valueOrNull?.single.name, 'My iPhone');
      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.toString(), 'https://chat.piisiit.com/devices');
      expect(request.data, isNull);
      expect(request.headers['Accept'], '*/*');
      expect(request.headers['Authorization'], 'Bearer test-token');

      adapter.status = 500;
      adapter.body = {'Success': false, 'Message': 'Devices unavailable'};
      expect(
        (await getDevices(const NoParams())).failureOrNull?.message,
        'Devices unavailable',
      );
    },
  );

  test('parses device lists and Chat envelopes including empty lists', () {
    final row = {
      'id': 4,
      'clientDeviceId': 'installation-id',
      'deviceName': 'My iPhone',
      'platform': 'iOS',
      'deviceModel': 'iPhone17,3',
      'appVersion': '1.0.2',
      'isCurrentDevice': true,
    };
    for (final body in [
      [row],
      {
        'success': true,
        'data': [row],
      },
      {
        'Success': true,
        'Data': [row],
      },
      {
        'data': {
          'devices': [row],
        },
      },
    ]) {
      final device = DeviceRemoteDataSource.parseDevices(body).single;
      expect(device.id, '4');
      expect(device.clientDeviceId, 'installation-id');
      expect(device.name, 'My iPhone');
      expect(device.platform, 'iOS');
      expect(device.model, 'iPhone17,3');
      expect(device.appVersion, '1.0.2');
      expect(device.isCurrent, isTrue);
    }
    expect(DeviceRemoteDataSource.parseDevices({'Data': []}), isEmpty);
    final device = DeviceRemoteDataSource.parseDevices([
      {'DeviceId': 'abc', 'DeviceName': 'Mac', 'Platform': 'macOS'},
    ]).single;
    expect(device.id, 'abc');
    expect(device.name, 'Mac');
  });

  test(
    'server failures and malformed responses cannot look like no devices',
    () {
      for (final body in [
        {'Success': false, 'Data': [], 'Message': 'Unauthorized'},
        {'code': 500, 'data': []},
        {'data': null},
        {
          'data': [42],
        },
        {
          'data': [{}],
        },
        '<html>Server error</html>',
      ]) {
        expect(
          () => DeviceRemoteDataSource.parseDevices(body),
          throwsA(isA<ServerException>()),
        );
      }
    },
  );

  test(
    'guest and signed-out sessions do not request account devices',
    () async {
      final guestMode = GuestModeService();
      final repository = _DevicesRepository();
      final controller = DeviceController(
        getDevices: GetDevices(repository),
        session: session,
        guestMode: guestMode,
      );
      await controller.load();
      session.token.value = 'token';
      guestMode.isGuestMode.value = true;
      await controller.load();
      expect(repository.requests, isEmpty);
      expect(controller.isLoading.value, isFalse);
      expect(controller.devices, isEmpty);
    },
  );

  test(
    'refresh ignores stale responses and clears devices on logout',
    () async {
      session.token.value = 'token';
      final repository = _DevicesRepository();
      final controller = Get.put(
        DeviceController(
          getDevices: GetDevices(repository),
          session: session,
          guestMode: GuestModeService(),
          clientDeviceId: 'installation-id',
        ),
      );
      expect(controller.isLoading.value, isTrue);
      final refresh = controller.load();
      repository.requests[1].complete(
        const Ok([AccountDevice(id: 'new', clientDeviceId: 'installation-id')]),
      );
      await refresh;
      repository.requests[0].complete(const Ok([AccountDevice(id: 'old')]));
      await Future<void>.delayed(Duration.zero);
      expect(controller.devices.single.id, 'new');
      expect(controller.isCurrent(controller.devices.single), isTrue);
      expect(
        controller.isCurrent(const AccountDevice(id: 'installation-id')),
        isFalse,
      );

      final retry = controller.load();
      repository.requests[2].complete(const Err(NetworkFailure()));
      await retry;
      expect(controller.error.value, 'No internet connection.');
      final pending = controller.load();
      session.token.value = null;
      await Future<void>.delayed(Duration.zero);
      repository.requests[3].complete(const Ok([AccountDevice(id: 'private')]));
      await pending;
      expect(controller.devices, isEmpty);
      expect(controller.error.value, isNull);
      expect(controller.isLoading.value, isFalse);
    },
  );
}

class _DevicesRepository implements DeviceRepository {
  final requests = <Completer<Result<List<AccountDevice>>>>[];

  @override
  Future<Result<List<AccountDevice>>> getDevices() {
    final request = Completer<Result<List<AccountDevice>>>();
    requests.add(request);
    return request.future;
  }
}

class _DeviceAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object body = {
    'Success': true,
    'Data': [
      {'id': 1, 'deviceName': 'My iPhone', 'platform': 'iOS'},
    ],
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
