import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/profile/data/repositories/profile_repository_impl.dart';

dio.ResponseBody response(Object body, [int status = 200]) =>
    dio.ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );

class _Adapter implements dio.HttpClientAdapter {
  final requests = <dio.RequestOptions>[];
  late FutureOr<dio.ResponseBody> Function(dio.RequestOptions) respond;
  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SessionStorage session;
  late ApiClient api;
  late _Adapter adapter;
  const refreshPath = '/api/auth/refresh-token';
  const sessionsPath = '/api/auth/sessions';

  setUp(() async {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({});
    session = Get.put(SessionStorage());
    await session.ready;
    await session.saveSession(
      'old-access',
      const UserData(id: 'user-one'),
      refreshToken: 'old-refresh',
    );
    api = Get.put(ApiClient());
    adapter = _Adapter();
    api.dio.httpClientAdapter = adapter;
  });
  tearDown(() => Get.reset());

  Future<void> rejectedRequest([String path = '/api/note']) async {
    await expectLater(api.dio.get(path), throwsA(isA<dio.DioException>()));
  }

  test(
    'Concurrent 401s send one documented refresh request and persist rotated tokens',
    () async {
      adapter.respond = (request) async {
        if (request.uri.path == refreshPath) {
          expect(request.uri.host, 'chat.piisiit.com');
          expect(request.data, {'refreshToken': 'old-refresh'});
          expect(request.headers['Authorization'], isNull);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return response({
            'success': true,
            'data': {
              'accessToken': 'new-access',
              'refreshToken': 'new-refresh',
            },
          });
        }
        return request.headers['Authorization'] == 'Bearer new-access'
            ? response({'data': []})
            : response({}, 401);
      };
      await Future.wait([api.dio.get('/api/note'), api.dio.get('/api/folder')]);
      expect(
        adapter.requests.where((r) => r.uri.path == refreshPath),
        hasLength(1),
      );
      expect(adapter.requests, hasLength(5));
      final restarted = SessionStorage();
      await restarted.ready;
      expect(restarted.token.value, 'new-access');
      expect(restarted.refreshToken.value, 'new-refresh');
      expect(restarted.user.value?.id, 'user-one');
    },
  );

  test(
    'A nonrotating refresh response preserves the saved refresh token',
    () async {
      adapter.respond = (request) {
        if (request.uri.path == refreshPath) {
          return response({
            'Success': true,
            'Data': {'Token': 'new-access'},
          });
        }
        return response(
          {},
          request.headers['Authorization'] == 'Bearer new-access' ? 200 : 401,
        );
      };
      await api.dio.get('/api/note');
      expect(session.refreshToken.value, 'old-refresh');
      expect(
        (await ProfileRepositoryImpl(session).updateName('Updated')).isOk,
        isTrue,
      );
      final restarted = SessionStorage();
      await restarted.ready;
      expect(restarted.refreshToken.value, 'old-refresh');
      expect(restarted.user.value?.fullName, 'Updated');
    },
  );

  test(
    'Legacy access-only session skips refresh and verifies the documented endpoint',
    () async {
      await session.saveSession(
        'legacy-access',
        const UserData(id: 'user-one'),
      );
      adapter.respond = (request) => response({
        'Success': true,
        'Data': [],
      }, request.uri.path == sessionsPath ? 200 : 401);
      await rejectedRequest();
      await rejectedRequest('/api/folder');
      expect(adapter.requests.where((r) => r.uri.path == refreshPath), isEmpty);
      expect(
        adapter.requests.where((r) => r.uri.path == sessionsPath),
        hasLength(1),
      );
      expect(session.token.value, 'legacy-access');
      expect(session.refreshToken.value, isNull);
    },
  );

  test(
    'Expired legacy session returns to login without an empty refresh request',
    () async {
      await session.saveSession('legacy-access', const UserData());
      adapter.respond = (_) => response({}, 401);
      await rejectedRequest();
      await session.loadSession();
      expect(session.isLoggedIn, isFalse);
      expect(adapter.requests.map((r) => r.uri.path), [
        '/api/note',
        sessionsPath,
      ]);
    },
  );

  test(
    'Refresh outage preserves credentials and backs off repeated recovery',
    () async {
      adapter.respond = (request) =>
          response({}, request.uri.path == refreshPath ? 503 : 401);
      await rejectedRequest();
      await rejectedRequest('/api/folder');
      expect(session.token.value, 'old-access');
      expect(session.refreshToken.value, 'old-refresh');
      expect(
        adapter.requests.where((r) => r.uri.path == refreshPath),
        hasLength(1),
      );
    },
  );

  test(
    'Refresh validation failure verifies account and does not loop or erase a valid login',
    () async {
      adapter.respond = (request) => response(
        {'success': true},
        request.uri.path == refreshPath
            ? 400
            : request.uri.path == sessionsPath
            ? 200
            : 401,
      );
      await rejectedRequest();
      await rejectedRequest();
      expect(session.token.value, 'old-access');
      expect(
        adapter.requests.where((r) => r.uri.path == refreshPath),
        hasLength(1),
      );
      expect(
        adapter.requests.where((r) => r.uri.path == sessionsPath),
        hasLength(1),
      );
    },
  );

  test('Rejected refresh clears both credentials', () async {
    adapter.respond = (_) => response({}, 401);
    await rejectedRequest();
    await session.loadSession();
    expect(session.isLoggedIn, isFalse);
    expect(session.refreshToken.value, isNull);
    final restarted = SessionStorage();
    await restarted.ready;
    expect(restarted.isLoggedIn, isFalse);
    expect(restarted.refreshToken.value, isNull);
  });

  test(
    'Note rejecting a renewed token is retried only once and preserves the account',
    () async {
      adapter.respond = (request) => request.uri.path == refreshPath
          ? response({
              'success': true,
              'data': {'token': 'renewed', 'refreshToken': 'rotated'},
            })
          : response({}, 401);
      await rejectedRequest();
      expect(adapter.requests, hasLength(3));
      expect(session.token.value, 'renewed');
      await rejectedRequest('/api/folder');
      expect(adapter.requests, hasLength(4));
    },
  );

  test(
    'A refresh completing after sign-out cannot resurrect the account',
    () async {
      final started = Completer<void>();
      final finish = Completer<dio.ResponseBody>();
      adapter.respond = (request) {
        if (request.uri.path == refreshPath) {
          started.complete();
          return finish.future;
        }
        return response({}, 401);
      };
      final requesting = rejectedRequest();
      await started.future;
      await session.clearSession();
      finish.complete(
        response({
          'success': true,
          'data': {'token': 'stale', 'refreshToken': 'stale-refresh'},
        }),
      );
      await requesting;
      expect(session.isLoggedIn, isFalse);
      expect(session.refreshToken.value, isNull);
    },
  );

  test(
    'A new login does not share an older account recovery or get signed out by it',
    () async {
      final started = Completer<void>();
      final oldResult = Completer<dio.ResponseBody>();
      adapter.respond = (request) {
        if (request.uri.path == refreshPath) {
          if ((request.data as Map)['refreshToken'] == 'old-refresh') {
            started.complete();
            return oldResult.future;
          }
          expect(request.data, {'refreshToken': 'second-refresh'});
          return response({
            'success': true,
            'data': {
              'token': 'second-renewed',
              'refreshToken': 'second-rotated',
            },
          });
        }
        return response(
          {},
          request.headers['Authorization'] == 'Bearer second-renewed'
              ? 200
              : 401,
        );
      };
      final oldRequest = rejectedRequest();
      await started.future;
      await session.saveSession(
        'second-access',
        const UserData(id: 'user-two'),
        refreshToken: 'second-refresh',
      );
      await api.dio.get('/api/note');
      oldResult.complete(response({}, 401));
      await oldRequest;
      expect(session.token.value, 'second-renewed');
      expect(session.refreshToken.value, 'second-rotated');
      expect(session.user.value?.id, 'user-two');
    },
  );
}
