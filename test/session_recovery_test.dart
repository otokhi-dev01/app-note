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

dio.ResponseBody signatureRejected() => dio.ResponseBody.fromString(
  '',
  401,
  headers: {
    'www-authenticate': [
      'Bearer error="invalid_token", error_description="The signature is invalid"',
    ],
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
  const secureStorage = FlutterSecureStorage();

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
    'Legacy access-only session signs out without refresh or account verification',
    () async {
      await session.saveSession(
        'legacy-access',
        const UserData(id: 'user-one'),
      );
      adapter.respond = (_) => response({}, 401);
      await rejectedRequest();
      await rejectedRequest('/api/folder');
      expect(adapter.requests.where((r) => r.uri.path == refreshPath), isEmpty);
      expect(
        adapter.requests.where((r) => r.uri.path == sessionsPath),
        isEmpty,
      );
      expect(session.token.value, isNull);
      expect(session.refreshToken.value, isNull);
    },
  );

  test(
    'A Note rejection invalidates access without consulting a valid Chat session',
    () async {
      await session.saveSession('valid-access', const UserData(id: 'user-one'));
      adapter.respond = (request) {
        if (request.uri.path == sessionsPath) {
          return response({'success': true, 'data': []});
        }
        expect(request.uri.host, 'note.piisiit.com');
        return response({}, 401);
      };
      await rejectedRequest();
      await rejectedRequest('/api/folder');
      expect(adapter.requests.map((request) => request.uri.path), [
        '/api/note',
        '/api/folder',
      ]);
      expect(
        adapter.requests.first.headers['Authorization'],
        'Bearer valid-access',
      );
      expect(adapter.requests.last.headers['Authorization'], isNull);
      expect(session.token.value, isNull);
    },
  );

  test(
    'Note signature rejection skips refresh and never replays a folder save',
    () async {
      await session.saveSession(
        'chat-access',
        const UserData(id: 'user-one'),
        refreshToken: 'saved-refresh',
      );
      await secureStorage.write(
        key: 'profile_id_snapshot',
        value: 'saved identity',
      );
      await secureStorage.write(key: 'private_key', value: 'saved key');
      final storedBefore = await secureStorage.readAll();
      final payload = {
        'id': 0,
        'name': 'Work',
        'iconName': 'folder',
        'colorValue': 'blue',
        'sortOrder': 0,
      };
      adapter.respond = (request) {
        expect(request.headers['Authorization'], 'Bearer chat-access');
        expect(request.uri.host, 'note.piisiit.com');
        expect(request.uri.path, '/api/folder/save');
        expect(request.method, 'POST');
        expect(request.data, payload);
        return dio.ResponseBody.fromString(
          '',
          401,
          headers: {
            'www-authenticate': [
              'Bearer error="invalid_token", error_description="The signature is invalid"',
            ],
          },
        );
      };
      await expectLater(
        api.dio.post('/api/folder/save', data: payload),
        throwsA(
          isA<dio.DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(adapter.requests.map((r) => r.uri.path), ['/api/folder/save']);
      expect(session.isLoggedIn, isFalse);
      expect(await secureStorage.readAll(), storedBefore..remove('token'));
      final restarted = SessionStorage();
      await restarted.ready;
      expect(restarted.isLoggedIn, isFalse);
      expect(restarted.refreshToken.value, isNull);
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
      expect(adapter.requests.map((r) => r.uri.path), ['/api/note']);
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
    'Refresh validation rejection invalidates access without account verification',
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
      expect(session.token.value, isNull);
      expect(
        adapter.requests.where((r) => r.uri.path == refreshPath),
        hasLength(1),
      );
      expect(
        adapter.requests.where((r) => r.uri.path == sessionsPath),
        isEmpty,
      );
    },
  );

  test('Rejected refresh removes only the stored access-token key', () async {
    final storedBefore = await secureStorage.readAll();
    adapter.respond = (_) => response({}, 401);
    await rejectedRequest();
    expect(await secureStorage.readAll(), storedBefore..remove('token'));
    await session.loadSession();
    expect(session.isLoggedIn, isFalse);
    expect(session.refreshToken.value, isNull);
    final restarted = SessionStorage();
    await restarted.ready;
    expect(restarted.isLoggedIn, isFalse);
    expect(restarted.refreshToken.value, isNull);
  });

  test(
    'Note rejecting a renewed token is retried once then invalidates access',
    () async {
      adapter.respond = (request) => request.uri.path == refreshPath
          ? response({
              'success': true,
              'data': {'token': 'renewed', 'refreshToken': 'rotated'},
            })
          : response({}, 401);
      await rejectedRequest();
      expect(adapter.requests, hasLength(3));
      expect(session.token.value, isNull);
      expect(await secureStorage.read(key: 'token'), isNull);
      expect(await secureStorage.read(key: 'refresh_token'), 'rotated');
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

  test(
    'No configured refresh endpoint signs out without a refresh call',
    () async {
      await Get.delete<ApiClient>(force: true);
      api = Get.put(ApiClient(refreshTokenEndpoint: null));
      api.dio.httpClientAdapter = adapter;
      adapter.respond = (_) => response({}, 401);
      await rejectedRequest();
      expect(adapter.requests.map((r) => r.uri.path), ['/api/note']);
      expect(session.isLoggedIn, isFalse);
      expect(await secureStorage.read(key: 'token'), isNull);
      expect(await secureStorage.read(key: 'refresh_token'), 'old-refresh');
    },
  );

  for (final status in [404, 405]) {
    test(
      'Refresh HTTP $status disables further attempts in this client',
      () async {
        adapter.respond = (request) =>
            response({}, request.uri.path == refreshPath ? status : 401);
        await rejectedRequest();
        expect(session.isLoggedIn, isFalse);
        await session.saveSession(
          'second-access',
          const UserData(id: 'user-two'),
          refreshToken: 'second-refresh',
        );
        await rejectedRequest('/api/folder');
        expect(adapter.requests.map((r) => r.uri.path), [
          '/api/note',
          refreshPath,
          '/api/folder',
        ]);
        expect(session.isLoggedIn, isFalse);
      },
    );
  }

  test(
    'Login 401 preserves the session even without a requiresAuth flag',
    () async {
      final storedBefore = await secureStorage.readAll();
      final revisionBefore = session.revision;
      adapter.respond = (_) => response({}, 401);
      for (final path in [
        'https://chat.piisiit.com/api/auth/login',
        '/api/auth/login',
      ]) {
        await expectLater(
          api.dio.post(
            path,
            options: dio.Options(headers: {'authorization': 'stale'}),
          ),
          throwsA(isA<dio.DioException>()),
        );
      }
      expect(adapter.requests, hasLength(2));
      for (final request in adapter.requests) {
        expect(
          request.headers.keys.where(
            (key) => key.toLowerCase() == 'authorization',
          ),
          isEmpty,
        );
      }
      expect(session.revision, revisionBefore);
      expect(session.token.value, 'old-access');
      expect(await secureStorage.readAll(), storedBefore);
    },
  );

  test(
    'A stale 401 after a new login cannot replay or revoke the new session',
    () async {
      final started = Completer<void>();
      final finish = Completer<dio.ResponseBody>();
      adapter.respond = (_) {
        started.complete();
        return finish.future;
      };
      final requesting = rejectedRequest();
      await started.future;
      await session.saveSession(
        'second-access',
        const UserData(id: 'user-two'),
        refreshToken: 'second-refresh',
      );
      finish.complete(signatureRejected());
      await requesting;
      expect(adapter.requests, hasLength(1));
      expect(session.token.value, 'second-access');
      expect(session.refreshToken.value, 'second-refresh');
      expect(session.user.value?.id, 'user-two');
      expect(await secureStorage.read(key: 'token'), 'second-access');
    },
  );

  test(
    'Concurrent and repeated signature rejections never refresh or recurse',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      var arrivals = 0;
      adapter.respond = (_) async {
        if (++arrivals == 2) started.complete();
        await release.future;
        return signatureRejected();
      };
      final initialRevision = session.revision;
      final requesting = Future.wait([
        rejectedRequest(),
        rejectedRequest('/api/folder'),
      ]);
      await started.future;
      release.complete();
      await requesting;
      expect(session.revision, initialRevision + 1);
      expect(session.isLoggedIn, isFalse);
      await rejectedRequest();
      expect(adapter.requests.map((r) => r.uri.path), [
        '/api/note',
        '/api/folder',
        '/api/note',
      ]);
      expect(adapter.requests.last.headers['Authorization'], isNull);
    },
  );

  for (final renewed in ['', 'old-access']) {
    test(
      'Refresh returning an ${renewed.isEmpty ? 'empty' : 'unchanged'} token does not retry',
      () async {
        adapter.respond = (request) => request.uri.path == refreshPath
            ? response({
                'success': true,
                'data': {'accessToken': renewed},
              })
            : response({}, 401);
        await rejectedRequest();
        expect(adapter.requests.map((r) => r.uri.path), [
          '/api/note',
          refreshPath,
        ]);
        expect(session.isLoggedIn, isFalse);
      },
    );
  }
}
