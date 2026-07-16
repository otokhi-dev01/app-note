import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:notes/core/constants/api_config.dart';
import 'package:notes/data/models/note_model.dart';
import 'package:notes/data/services/auth_service.dart';
import 'package:notes/data/services/local_storage.dart';
import 'package:notes/data/services/note_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeGetConnect client;
  late NoteApiService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final auth = AuthService(LocalStorage());
    await auth.ready;
    client = _FakeGetConnect();
    service = NoteApiService(
      auth,
      client: client,
      tokenProvider: () => 'note-test-token',
    );
  });

  test('GET notes maps nested envelopes and server field aliases', () async {
    client.enqueue({
      'data': {
        'result': {
          'notes': [
            {
              'note_id': '17',
              'name': 'Project brief',
              'note_content': 'Launch details',
              'dateCreated': 1721120400,
              'modified_at': '2026-07-16T09:15:00Z',
              'is_deleted': 1,
              'deleted_at': '2026-07-16T10:00:00Z',
              'folder': {'id': '4'},
              'is_pinned': 'yes',
              'locked': 1,
              'attachments': [
                {'url': 'https://cdn.example.com/brief.png'},
                {'file_path': '/tmp/sketch.jpg'},
              ],
            },
          ],
        },
      },
    });

    final notes = await service.getNotes(includeDeleted: true);

    expect(client.requests.single.method, 'GET');
    expect(client.requests.single.url, ApiConfig.notesUrl);
    expect(
      client.requests.single.headers?['Authorization'],
      'Bearer note-test-token',
    );
    expect(client.requests.single.query?['includeDeleted'], isTrue);
    expect(client.requests.single.query?['include_deleted'], isTrue);
    expect(notes, hasLength(1));
    expect(notes.single.id, 17);
    expect(notes.single.title, 'Project brief');
    expect(notes.single.content, 'Launch details');
    expect(notes.single.folderId, 4);
    expect(notes.single.isDeleted, isTrue);
    expect(notes.single.deletedAt, isNotNull);
    expect(notes.single.isPinned, isTrue);
    expect(notes.single.isLocked, isTrue);
    expect(notes.single.imagePaths, [
      'https://cdn.example.com/brief.png',
      '/tmp/sketch.jpg',
    ]);
  });

  test('GET note uses the detail URL and maps a nested note object', () async {
    client.enqueue({
      'result': {
        'note': {
          'Id': 23,
          'noteTitle': 'Meeting notes',
          'body': 'Decisions and actions',
          'created_at': '2026-07-15T08:00:00Z',
          'updatedAt': '2026-07-16T08:30:00Z',
          'image_paths': 'one.png|two.png',
        },
      },
    });

    final note = await service.getNote(23);

    expect(client.requests.single.method, 'GET');
    expect(client.requests.single.url, ApiConfig.noteUrl(23));
    expect(note?.id, 23);
    expect(note?.title, 'Meeting notes');
    expect(note?.content, 'Decisions and actions');
    expect(note?.imagePaths, ['one.png', 'two.png']);
  });

  test('POST save-content sends aliases and maps the saved note', () async {
    client.enqueue({
      'data': {
        'record': {
          'noteId': 31,
          'title': 'Quarterly strategy',
          'noteContent': 'Updated plan',
          'createdAt': '2026-07-16T07:00:00Z',
          'updatedAt': '2026-07-16T09:00:00Z',
          'folderId': 8,
        },
      },
    });
    final source = _note(
      id: 31,
      title: 'Quarterly strategy',
      content: 'Updated plan',
      folderId: 8,
      imagePaths: const ['scan.png'],
    );

    final saved = await service.saveContent(source);

    final request = client.requests.single;
    expect(request.method, 'POST');
    expect(request.url, ApiConfig.saveNoteContentUrl);
    expect(request.headers?['Authorization'], 'Bearer note-test-token');
    expect(request.body?['id'], 31);
    expect(request.body?['noteId'], 31);
    expect(request.body?['title'], 'Quarterly strategy');
    expect(request.body?['noteContent'], 'Updated plan');
    expect(request.body?['folder_id'], 8);
    expect(request.body, isNot(contains('attachments')));
    expect(request.body, isNot(contains('imagePaths')));
    expect(saved.id, 31);
    expect(saved.content, 'Updated plan');
  });

  test('save-content success-only response refreshes note detail', () async {
    client
      ..enqueue({'success': true})
      ..enqueue({
        'data': {
          'id': 44,
          'title': 'Synced title',
          'content': 'Server content',
          'created_at': '2026-07-16T07:00:00Z',
          'updated_at': '2026-07-16T10:00:00Z',
        },
      });

    final saved = await service.saveContent(
      _note(id: 44, title: 'Synced title', content: 'Local content'),
    );

    expect(client.requests, hasLength(2));
    expect(client.requests.first.url, ApiConfig.saveNoteContentUrl);
    expect(client.requests.last.method, 'GET');
    expect(client.requests.last.url, ApiConfig.noteUrl(44));
    expect(saved.content, 'Server content');
  });

  test(
    'POST update-state sends state aliases and maps note response',
    () async {
      client.enqueue({
        'result': {
          'item': {
            'id': 51,
            'title': 'Pinned note',
            'content': 'Keep this handy',
            'isPinned': true,
            'folder_id': 3,
          },
        },
      });
      final note = _note(
        id: 51,
        title: 'Pinned note',
        content: 'Keep this handy',
        folderId: 3,
        isPinned: true,
      );

      final updated = await service.updateState(
        note,
        state: 'pinned',
        value: true,
      );

      final request = client.requests.single;
      expect(request.method, 'POST');
      expect(request.url, ApiConfig.updateNoteStateUrl);
      expect(request.headers?['Authorization'], 'Bearer note-test-token');
      expect(request.body?['id'], 51);
      expect(request.body?['note_id'], 51);
      expect(request.body?['state'], 'pinned');
      expect(request.body?['stateName'], 'pinned');
      expect(request.body?['value'], isTrue);
      expect(request.body?['isPinned'], isTrue);
      expect(request.body?['folderId'], 3);
      expect(updated?.id, 51);
      expect(updated?.isPinned, isTrue);
    },
  );

  test('update-state accepts a success-only response', () async {
    client
      ..enqueue({'success': true, 'state': 'locked'})
      ..enqueue({
        'data': {
          'id': 62,
          'title': 'Private',
          'content': 'Secret',
          'isLocked': true,
        },
      });

    final updated = await service.updateState(
      _note(id: 62, title: 'Private', content: 'Secret', isLocked: true),
      state: 'locked',
      value: true,
    );

    expect(client.requests, hasLength(2));
    expect(client.requests.first.url, ApiConfig.updateNoteStateUrl);
    expect(client.requests.last.url, ApiConfig.noteUrl(62));
    expect(updated?.isLocked, isTrue);
  });

  test('save-content accepts an identifier-only create response', () async {
    client.enqueue({
      'data': {'id': 72},
    });

    final saved = await service.saveContent(
      _note(title: 'New note', content: 'Created by the API'),
    );

    expect(saved.id, 72);
    expect(saved.title, 'New note');
    expect(saved.content, 'Created by the API');
  });

  test('non-success API responses expose message and status code', () async {
    client.enqueue({
      'message': 'The note could not be saved.',
    }, statusCode: 422);

    await expectLater(
      service.saveContent(_note(title: 'Invalid', content: '')),
      throwsA(
        isA<NoteApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.message,
              'message',
              'The note could not be saved.',
            ),
      ),
    );
  });
}

NoteModel _note({
  int? id,
  required String title,
  required String content,
  int? folderId,
  List<String> imagePaths = const [],
  bool isPinned = false,
  bool isLocked = false,
}) {
  return NoteModel(
    id: id,
    title: title,
    content: content,
    createdAt: DateTime.utc(2026, 7, 16, 7),
    updatedAt: DateTime.utc(2026, 7, 16, 9),
    imagePaths: imagePaths,
    folderId: folderId,
    isPinned: isPinned,
    isLocked: isLocked,
  );
}

class _Request {
  const _Request({
    required this.method,
    required this.url,
    this.headers,
    this.query,
    this.body,
  });

  final String method;
  final String? url;
  final Map<String, String>? headers;
  final Map<String, dynamic>? query;
  final Map<String, dynamic>? body;
}

class _QueuedResponse {
  const _QueuedResponse(this.body, this.statusCode);

  final dynamic body;
  final int statusCode;
}

class _FakeGetConnect extends GetConnect {
  final List<_QueuedResponse> _responses = [];
  final List<_Request> requests = [];

  void enqueue(dynamic body, {int statusCode = 200}) {
    _responses.add(_QueuedResponse(body, statusCode));
  }

  _QueuedResponse _takeResponse() {
    if (_responses.isEmpty) {
      throw StateError('No fake API response was queued.');
    }
    return _responses.removeAt(0);
  }

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    requests.add(
      _Request(method: 'GET', url: url, headers: headers, query: query),
    );
    final response = _takeResponse();
    return Response<T>(
      statusCode: response.statusCode,
      body: response.body as T?,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    requests.add(
      _Request(
        method: 'POST',
        url: url,
        headers: headers,
        query: query,
        body: Map<String, dynamic>.from(body as Map),
      ),
    );
    final response = _takeResponse();
    return Response<T>(
      statusCode: response.statusCode,
      body: response.body as T?,
    );
  }
}
