# Modern Liquid Glass Note List Screen Plan

I will transform the Home/Note List screen into the **Modern Liquid Glass** style. This will ensure visual consistency across all major screens in the app.

## User Review Required

> [!IMPORTANT]
> - **Search & Filter**: The search field and folder filter chips will be redesigned as floating glass elements.
> - **Note Cards**: Note cards will now feature the deep-blur glass effect and responsive press animations.
> - **Performance**: Similar to the Folder screen, this adds more `BackdropFilter` usage.

## Proposed Changes

### Note List UI Refactor

#### [MODIFY] [note_list_view.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/notes/presentation/view/note_list_view.dart)
- Import `AppLiquidBackgroundWidget` and `AppGlassSurface`.
- Wrap the list content in a `Stack` with the liquid background.

#### [MODIFY] [note_list_content_widget.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/notes/presentation/widgets/note_list/note_list_content_widget.dart)
- Update `CupertinoSliverNavigationBar` to be transparent.
- Refine padding for glass elements.

#### [MODIFY] [note_row_widget.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/notes/presentation/widgets/note_list/note_row_widget.dart)
- Replace the `Container` with `AppGlassSurface`.
- Implement a "squishy" press scale animation.
- Improve typography and icon contrast on glass.

#### [MODIFY] [note_search_field_widget.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/notes/presentation/widgets/note_list/note_search_field_widget.dart)
- Redesign as a floating glass capsule.

#### [MODIFY] [folder_filter_chip_widget.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/notes/presentation/widgets/note_list/folder_filter_chip_widget.dart)
- Update chips to use a translucent glass background with primary-colored highlights when selected.

## Verification Plan

### Manual Verification
- Verify scrolling performance with many glass note rows.
- Check search field interaction while floating.
- Ensure the "pinned" state is visually distinct on the glass surface.
