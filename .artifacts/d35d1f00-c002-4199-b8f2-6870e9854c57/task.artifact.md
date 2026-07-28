# Tasks - Full API Feature Integration

- [ ] **Data Layer**
    - [ ] Update `FolderRepository` to support Trash folders [folder_repository.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/data/repositories/folder_repository.dart)
    - [ ] Audit all `NoteRepository` POST bodies against Postman [note_repository.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/data/repositories/note_repository.dart)
- [ ] **Logic Layer**
    - [ ] Implement `trashFolders` management in `FolderController` [folder_controller.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/modules/folder/folder_controller.dart)
    - [ ] Synchronize Trash state in `NoteListController` [note_list_controller.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/modules/note/note_list_controller.dart)
- [ ] **UI Layer**
    - [ ] Update `TrashView` to show deleted Folders and Notes [trash_view.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/modules/trash/trash_view.dart)
- [ ] **Verification**
    - [ ] Verify full Trash lifecycle (Delete -> Show in Trash -> Restore)
    - [ ] Confirm all creation/update requests are 100% aligned with Postman
