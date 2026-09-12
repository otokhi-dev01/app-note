import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/note/data/datasources/note_remote_data_source.dart';
import 'package:Note/features/note/data/repositories/note_repository_impl.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiClient api;
  late _NoteAdapter adapter;
  late NoteRepositoryImpl repository;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({'token': 'chat-login-token'});
    await Get.put(SessionStorage()).loadSession();
    api = Get.put(ApiClient());
    adapter = _NoteAdapter();
    api.dio.httpClientAdapter = adapter;
    repository = NoteRepositoryImpl(NoteRemoteDataSource());
  });

  tearDown(() {
    api.dio.close();
    Get.reset();
  });

  test(
    'create sends content only to the ID confirmed by the metadata response',
    () async {
      adapter.respond = (request) => switch (request.uri.path) {
        '/api/note/save' => {
          'code': 200,
          'data': {'noteId': 42},
        },
        '/api/note/save-content' => {'code': 200},
        '/api/note/42' => {
          'data': {
            'NoteId': 42,
            'FolderId': 7,
            'Title': 'Work',
            'content': [
              {'id': 'text-1', 'type': 'text', 'text': 'Hello'},
            ],
          },
        },
        _ => throw StateError('Unexpected request'),
      };
      final result = await repository.saveNote(
        folderId: 7,
        title: 'Work',
        content: const [TextBlock(id: 'text-1', text: 'Hello')],
      );
      expect(result.valueOrNull?.id, 42);
      expect((result.valueOrNull?.content.single as TextBlock).text, 'Hello');
      expect(adapter.requests.map((request) => request.uri.path), [
        '/api/note/save',
        '/api/note/save-content',
        '/api/note/42',
      ]);
      expect((adapter.requests[1].data as Map)['id'], 42);
    },
  );

  test(
    'create parses supported note ID envelopes without guessing from a list',
    () async {
      for (final body in <Object>[
        {
          'code': 200,
          'data': {'noteId': 42},
        },
        {
          'Success': true,
          'Data': {'NoteId': '42'},
        },
        {
          'code': 200,
          'data': [
            {'NoteId': 42},
          ],
        },
        {
          'data': {
            'Note': {'Id': 42},
          },
        },
        {'data': 42},
        {'NoteId': 42},
      ]) {
        adapter.body = body;
        adapter.requests.clear();
        final result = await repository.saveNoteMetadata(
          folderId: 7,
          title: 'Work',
        );
        expect(result.valueOrNull, 42, reason: '$body');
        final request = adapter.requests.single;
        expect(request.uri.toString(), '${ApiClient.baseUrl}/api/note/save');
        expect(request.headers['Authorization'], 'Bearer chat-login-token');
        expect(request.data, {'folderId': 7, 'title': 'Work'});
      }
    },
  );

  test(
    'HTTP 200 metadata errors stop creation and updates with the server message',
    () async {
      for (final body in [
        {
          'code': 400,
          'message': 'Folder not found',
          'data': {'NoteId': 42},
        },
        {
          'Success': false,
          'Message': 'Folder not found',
          'Data': {'NoteId': 42},
        },
      ]) {
        adapter.body = body;
        for (final id in [0, 42]) {
          adapter.requests.clear();
          final result = await repository.saveNoteMetadata(
            folderId: 7,
            title: 'Work',
            noteId: id,
          );
          expect(result.failureOrNull, isA<ServerFailure>());
          expect(result.failureOrNull?.message, 'Folder not found');
          expect(adapter.requests, hasLength(1));
        }
      }
    },
  );

  test(
    'an unconfirmed create never selects another note to overwrite',
    () async {
      for (final body in [
        null,
        {'code': 200},
        {
          'data': [
            {'NoteId': 41},
            {'NoteId': 42},
          ],
        },
      ]) {
        adapter.body = body;
        adapter.requests.clear();
        final result = await repository.saveNoteMetadata(
          folderId: 7,
          title: 'Work',
        );
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(adapter.requests, hasLength(1));
      }
    },
  );

  test('an acknowledged update can keep its existing ID', () async {
    adapter.body = {'code': 200};
    final result = await repository.saveNoteMetadata(
      folderId: 7,
      title: 'Work',
      noteId: 42,
    );
    expect(result.valueOrNull, 42);
    expect((adapter.requests.single.data as Map)['noteId'], 42);
  });

  test(
    'content is sent to the created note and body validation errors are returned',
    () async {
      const content = [TextBlock(id: 'text-1', text: 'Hello')];
      adapter.body = {'code': 200};
      final saved = await repository.saveNoteContent(
        noteId: 42,
        title: 'Work',
        content: content,
      );
      expect(saved.isOk, isTrue);
      final request = adapter.requests.single;
      expect(
        request.uri.toString(),
        '${ApiClient.baseUrl}/api/note/save-content',
      );
      expect(request.data, {
        'id': 42,
        'title': 'Work',
        'content': [
          {'id': 'text-1', 'type': 'text', 'text': 'Hello'},
        ],
      });
      adapter.body = {
        'code': 400,
        'message': 'Validation failed',
        'errors': {
          'Title': ['Title is too long'],
        },
      };
      final failed = await repository.saveNoteContent(
        noteId: 42,
        title: 'Work',
        content: content,
      );
      expect(failed.failureOrNull?.message, 'Title is too long');
    },
  );

  test('Note authorization errors preserve the Chat session', () async {
    adapter.statusCode = 401;
    adapter.body = {'message': 'Unauthorized'};
    final result = await repository.saveNoteMetadata(
      folderId: 7,
      title: 'Work',
    );
    expect(result.failureOrNull, isA<UnauthorizedFailure>());
    expect(Get.find<SessionStorage>().token.value, 'chat-login-token');
  });
}

class _NoteAdapter implements HttpClientAdapter {
  Object? body;
  Object? Function(RequestOptions)? respond;
  int statusCode = 200;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(respond == null ? body : respond!(options)),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
