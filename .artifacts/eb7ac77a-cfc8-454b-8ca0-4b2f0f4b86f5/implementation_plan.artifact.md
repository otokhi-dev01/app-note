# Comprehensive UI Redesign based on Design Overview

The goal is to update the entire app UI to match the new 8-screen design overview. This includes reorganizing navigation, redesigning core screens (Notes, Note Editor, Search), and implementing a new unified aesthetic.

## User Review Required

> [!IMPORTANT]
> The bottom navigation will be reordered to: **Notes**, **Folders**, **Add (+)**, **Search**, and **Settings**.
> I will create a new **Search** screen as part of the main navigation.
> The **Recent** section in the Notes screen will show a horizontal list of recently edited notes.

## Proposed Changes

### Main Navigation

#### [MODIFY] [notched_navigation_bar.dart](file:///Users/macbook/Documents/Flutter/app/app-note/lib/feature/main/presentation/widgets/notched_navigation_bar.dart)
- Update order and icons: Notes (doc_text), Folders (folder), Add (plus), Search (search), Settings (gear).
- Update active tab indicator (pill-shaped) to match the screenshot.

#### [MODIFY] [main_view.dart](file:///Users/macbook/Documents/Flutter/app/app-note/lib/feature/main/presentation/view/main_view.dart)
- Reorder screens in `PageView`: `NoteListView`, `FolderListView`, `SearchView`, `ProfileView`.

### Notes Screen

#### [MODIFY] [note_list_content_widget.dart](file:///Users/macbook/Documents/Flutter/app/app-note/lib/feature/notes/presentation/widgets/note_list/note_list_content_widget.dart)
- Implement **Pinned** section with modern cards.
- Implement **Recent** horizontal list section.
- Add "Filter" icon to the top right of the navigation bar to trigger the new Filter Bottom Sheet.

### Note Editor Screen

#### [MODIFY] [note_editor_view.dart](file:///Users/macbook/Documents/Flutter/app/app-note/lib/feature/notes/presentation/view/note_editor_view.dart)
- Minimalist top bar with Pin, Reminders, and More icons.
- Add pill-shaped "Work" (folder/tag) indicator below the title.

#### [MODIFY] [editor_toolbar_widget.dart](file:///Users/macbook/Documents/Flutter/app/app-note/lib/feature/notes/presentation/widgets/create_note/editor_toolbar_widget.dart)
- Redesign the bottom toolbar with icons for Format (Aa), List, Checklist, Image, and Attachment.

### New Features

#### [NEW] `search_view.dart`
- Implement the Search screen with Recent Searches (chips) and Suggestions.

#### [NEW] `filter_bottom_sheet.dart`
- Implement the dark-themed filter/tags sheet from the design.

## Verification Plan

### Manual Verification
- Verify the new navigation order and icons.
- Verify the Notes screen layout (Pinned & Recent).
- Verify the Search screen functionality and UI.
- Verify the Note Editor's new toolbar and tag display.
- Verify the Filter Bottom Sheet triggers from the Notes screen.
