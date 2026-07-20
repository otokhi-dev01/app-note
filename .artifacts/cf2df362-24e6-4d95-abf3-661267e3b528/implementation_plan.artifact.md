# Implementation Plan - Folder Creation & Recycle Bin Integration

This plan focuses on improving the folder creation process and properly integrating the Recycle Bin feature into the user profile.

## User Review Required

> [!IMPORTANT]
> - I will be updating the `HomeController.createFolder` method signature, which might affect other call sites if they exist.
> - The Recycle Bin menu will be re-enabled in the Profile view, moved from the logout dialog to a standard menu item for better accessibility.

## Proposed Changes

### Notes Feature

#### [MODIFY] [home_controller.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/notes/presentation/controllers/home_controller.dart)
- Update `createFolder` to accept optional `iconName`, `colorValue`, and `sortOrder`.
- Use the provided values when calling `folderRepository.saveFolder`.

### Folders Feature

#### [MODIFY] [create_folder_controller.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/folders/presentation/controller/create_folder_controller.dart)
- Pass `selectedIcon.value` and `selectedColor.value` to `homeController.createFolder`.

### Profile Feature

#### [MODIFY] [profile_view.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/profile/presentation/views/profile_view.dart)
- Re-enable the "Recycle Bin" menu tile.
- Move it from the `_confirmLogout` dialog to the first `_ProfileMenuCard` in the main view.

## Verification Plan

### Automated Tests
- I will run `flutter test` if applicable to ensure no regressions in business logic. (Currently not specified).

### Manual Verification
- **Create Folder**: Open the "Create Folder" screen, choose a custom icon and color, and verify the folder is created correctly in the home screen.
- **Recycle Bin**: Navigate to the Profile screen, click on "Recycle Bin", and verify it opens correctly and shows deleted folders/archived notes.
- **Restore**: Test restoring a folder and a note from the Recycle Bin.
