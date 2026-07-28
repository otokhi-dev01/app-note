# Implementation Plan - Full API Feature Integration

This plan finalizes the integration of all API features described in the Postman collection, with a focus on Trash Folder management and global data synchronization.

## Proposed Changes

### [Data Layer]

#### [MODIFY] [folder_repository.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/data/repositories/folder_repository.dart)
- Update `getFolders` to return a `Map<String, List<FolderModel>>` containing both active `folder` and `trash` lists from the API response.

#### [MODIFY] [note_repository.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/data/repositories/note_repository.dart)
- Double-check and ensure all `POST` request keys match the Postman collection:
    - `saveNote`: `noteId`, `folderId`, `title`.
    - `updateNoteState`: `id`, `isPinned`, `isArchived`, `isLocked`.
    - `uploadAttachment`: `Id`, `BlockId`, `DisplayOrder`, `File`.

### [Logic Layer]

#### [MODIFY] [folder_controller.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/modules/folder/folder_controller.dart)
- Add a `trashFolders` observable list.
- Update `fetchFolders` to populate both `folders` and `trashFolders`.

#### [MODIFY] [note_list_controller.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/modules/note/note_list_controller.dart)
- Add a `trashFolders` observable list (synchronized with `FolderController`).
- Refine `fetchTrashNotes` to ensure it captures all metadata required for the "Days Left" logic.

### [UI Layer]

#### [MODIFY] [trash_view.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/modules/trash/trash_view.dart)
- Update the UI to display two sections: **Folders** and **Notes**.
- Use `FolderCard` (in horizontal or list mode) for deleted folders in the trash.
- Ensure the "Clear Trash" action handles both notes and folders if supported by the endpoint (or call both).

## Verification Plan

### Manual Verification
- **Trash Sync**: Delete a folder and a note. Navigate to Trash and verify both appear with correct "Days Left" badges.
- **Restore Logic**: Restore a folder from Trash and verify it reappears in the Folders list instantly.
- **Attachment Check**: Upload an image to a note and verify it appears in the Attachment List with the correct size and name.
- **State Sync**: Pin a note and verify the change reflects on the Dashboard and Pinned screen immediately.
