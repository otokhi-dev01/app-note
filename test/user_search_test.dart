import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';
import 'package:Note/features/search/data/datasources/user_search_remote_data_source.dart';
import 'package:Note/features/search/data/repositories/user_search_repository_impl.dart';
import 'package:Note/features/search/domain/entities/search_results.dart';
import 'package:Note/features/search/domain/entities/search_user.dart';
import 'package:Note/features/search/domain/repositories/user_search_repository.dart';
import 'package:Note/features/search/domain/usecases/search_usecases.dart';
import 'package:Note/features/search/presentation/controllers/search_controller.dart'
    as sc;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  test(
    'user search sends keyword to Chat with the current session token',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final session = Get.put(SessionStorage());
      await session.loadSession();
      session.token.value = 'test-token';
      final api = Get.put(ApiClient());
      final adapter = _SearchAdapter();
      api.dio.httpClientAdapter = adapter;
      addTearDown(() => api.dio.close());
      final search = SearchUsers(
        UserSearchRepositoryImpl(UserSearchRemoteDataSource(api)),
      );

      final result = await search('  alice  ');
      expect(result.failureOrNull, isNull);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.single.displayName, 'Alice');
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(
        request.uri.toString(),
        'https://chat.piisiit.com/api/users/search',
      );
      expect(request.data, {'keyword': 'alice'});
      expect(request.headers['Accept'], '*/*');
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(request.contentType, 'application/json');

      expect((await search('  ')).valueOrNull, isEmpty);
      expect(adapter.requests, hasLength(1));
    },
  );

  test('parses list and nested user envelopes, including empty results', () {
    final row = {'userId': 7, 'account': 'alice', 'fullName': 'Alice'};
    for (final body in [
      [row],
      {
        'code': 200,
        'data': [row],
      },
      {
        'data': {
          'users': [row],
        },
      },
    ]) {
      final user = UserSearchRemoteDataSource.parseUsers(body).single;
      expect(user.id, '7');
      expect(user.account, 'alice');
      expect(user.displayName, 'Alice');
    }
    expect(UserSearchRemoteDataSource.parseUsers({'data': []}), isEmpty);
  });

  test(
    'server errors and malformed responses are not empty success results',
    () {
      for (final body in [
        {'code': 400, 'message': 'Search unavailable', 'data': []},
        {'unexpected': 'response'},
        {
          'data': [null],
        },
      ]) {
        expect(
          () => UserSearchRemoteDataSource.parseUsers(body),
          throwsA(isA<ServerException>()),
        );
      }
    },
  );

  testWidgets(
    'debounces users and ignores older responses and cleared queries',
    (tester) async {
      final repository = _PendingUsers();
      final session = SessionStorage()..token.value = 'test-token';
      final controller = Get.put(
        sc.SearchController(
          search: _EmptyNoteSearch(),
          searchUsers: SearchUsers(repository),
          session: session,
        ),
      );
      controller.changeScope(sc.SearchScope.users);
      controller.onSearchChanged('a');
      await tester.pump(const Duration(milliseconds: 100));
      controller.onSearchChanged('alice');
      await tester.pump(const Duration(milliseconds: 301));
      expect(repository.calls.keys, ['alice']);

      controller.onSearchChanged('bob');
      await tester.pump(const Duration(milliseconds: 301));
      repository.calls['bob']!.complete(
        const Ok([SearchUser(id: '2', account: 'bob', fullName: 'Bob')]),
      );
      await tester.pump();
      repository.calls['alice']!.complete(
        const Ok([SearchUser(id: '1', account: 'alice', fullName: 'Alice')]),
      );
      await tester.pump();
      expect(controller.userResults.single.account, 'bob');

      controller.onSearchChanged('carol');
      await tester.pump(const Duration(milliseconds: 301));
      controller.clearSearch();
      repository.calls['carol']!.complete(
        const Ok([SearchUser(id: '3', account: 'carol', fullName: 'Carol')]),
      );
      await tester.pump(const Duration(milliseconds: 301));
      expect(controller.userResults, isEmpty);
      expect(controller.isLoadingUsers.value, isFalse);
    },
  );

  testWidgets('notes mode and signed-out users do not call user search', (
    tester,
  ) async {
    final repository = _PendingUsers();
    final controller = Get.put(
      sc.SearchController(
        search: _EmptyNoteSearch(),
        searchUsers: SearchUsers(repository),
        session: SessionStorage(),
      ),
    );
    controller.onSearchChanged('private note');
    await tester.pump(const Duration(milliseconds: 301));
    expect(repository.calls, isEmpty);
    controller.changeScope(sc.SearchScope.users);
    controller.onSearchChanged('alice');
    await tester.pump(const Duration(milliseconds: 301));
    expect(repository.calls, isEmpty);
    expect(controller.isLoadingUsers.value, isFalse);
  });
}

class _SearchAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'code': 200,
        'data': [
          {'id': '7', 'account': 'alice', 'fullName': 'Alice'},
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _PendingUsers implements UserSearchRepository {
  final calls = <String, Completer<Result<List<SearchUser>>>>{};

  @override
  Future<Result<List<SearchUser>>> search(String keyword) {
    final completer = Completer<Result<List<SearchUser>>>();
    calls[keyword] = completer;
    return completer.future;
  }
}

class _EmptyNoteSearch extends SearchNotesAndFolders {
  _EmptyNoteSearch() : super(_UnusedNotes(), _UnusedFolders());

  @override
  Future<Result<SearchResults>> call(String query) async =>
      const Ok(SearchResults.empty());
}

class _UnusedNotes implements NoteRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedFolders implements FolderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
