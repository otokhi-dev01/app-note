import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/app/routes/app_pages.dart';
import 'package:note_app/app/routes/app_routes.dart';
import 'package:note_app/core/network/api_endpoints.dart';

void main() {
  test('configured app routes are unique', () {
    final List<String> routeNames = AppPages.pages
        .map((page) => page.name)
        .toList(growable: false);

    expect(routeNames.toSet(), hasLength(routeNames.length));
    expect(
      routeNames,
      containsAll(<String>[
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.home,
        AppRoutes.createFolder,
        AppRoutes.createNote,
        AppRoutes.noteEditor,
      ]),
    );
  });

  test('API paths match the integrated endpoint collection', () {
    expect(ApiEndpoints.login, '/api/auth/login');
    expect(ApiEndpoints.register, '/api/auth/register');
    expect(ApiEndpoints.folders, '/api/folder');
    expect(ApiEndpoints.saveFolder, '/api/folder/save');
    expect(ApiEndpoints.deleteRestoreFolder, '/api/folder/delete-restore');
    expect(ApiEndpoints.notes, '/api/note');
    expect(ApiEndpoints.noteDetail(12), '/api/note/12');
    expect(ApiEndpoints.saveNote, '/api/note/save');
    expect(ApiEndpoints.saveContent, '/api/note/save');
    expect(ApiEndpoints.legacySaveContent, '/api/note/save-content');
    expect(ApiEndpoints.noteAttachment, '/api/note/attachment');
    expect(ApiEndpoints.updateNoteState, '/api/note/update-state');
  });
}
