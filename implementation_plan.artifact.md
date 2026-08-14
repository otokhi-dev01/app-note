# iOS-Style Folder List Implementation Plan

Refactor the folder list and structural organization to match the native iOS Notes app appearance using the `cupertino_native_better` package.

## Proposed Changes

### [Feature] Folder Module

#### [MODIFY] [FolderView](file:///Users/yornnona/Documents/Apps/app-note/lib/app/modules/folder/views/folder_view.dart)
- Import `cupertino_native_better`.
- Replace existing `Column` and `LiquidGlassContainer` based list with `CupertinoNativeListSection` (inset grouped style).
- Organize folders into sections: "iCloud", "Shared", and "On My iPhone".
- Integrate section expansion/collapse logic with the new UI components.

#### [MODIFY] [FolderTile](file:///Users/yornnona/Documents/Apps/app-note/lib/app/modules/folder/widgets/folder_tile.dart)
- Replace `ListTile` with `CupertinoNativeListTile` for a more native feel.
- Ensure leading icons, titles, and trailing counts/icons are correctly mapped.
- Support edit mode (reordering and contextual actions).

#### [MODIFY] [FolderAllNotesTile](file:///Users/yornnona/Documents/Apps/app-note/lib/app/modules/folder/widgets/folder_all_notes_tile.dart)
- Refactor to use `CupertinoNativeListTile`.
- Ensure consistency with individual folder tiles.

#### [MODIFY] [FolderSectionHeader](file:///Users/yornnona/Documents/Apps/app-note/lib/app/modules/folder/widgets/folder_section_header.dart)
- Update or replace with `CupertinoNativeHeader` for a native look.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no compilation errors.

### Manual Verification
- Open the Folders screen.
- Verify sections are grouped correctly (iCloud, On My iPhone).
- Verify the list has the "inset grouped" look typical of iOS 15+.
- Test tapping on folders to navigate to note lists.
- Test "Edit" mode to ensure contextual actions work.
