# Immersive Full-Screen Image Preview & Dynamic Statement Redesign

I will update the "Create Note" screen to allow adding multiple text "statements" (blocks) and upgrade the image preview to a truly immersive full-screen experience.

## User Review Required

> [!IMPORTANT]
> - **Full-Screen Image Preview**: The image will now fill the entire screen (`BoxFit.cover` by default with zoom capability) and the UI controls will float elegantly on top without a solid background.
> - **Dynamic Statements**: I will update the `CreateNoteController` to support a more flexible content structure if the user wants to add multiple text sections, or I will focus on making the current "Start writing..." area feel like a premium dynamic statement block.
> - **Rich Text Formatting**: Since we are using standard text fields, I will implement basic "Append" functionality for the toolbar icons (e.g., adding Markdown-like symbols) or ensure the focus remains on a premium, single-statement experience as per the design.

## Proposed Changes

### Create Note Feature

#### [MODIFY] [image_preview_page_widget.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/notes/presentation/widgets/create_note/image_preview_page_widget.dart)
- Change `BoxFit.contain` to a more immersive fit logic.
- Remove `boundaryMargin` from `InteractiveViewer` for a cleaner "full screen" feel.
- Make the top bar (close button) fully translucent.

#### [MODIFY] [body_field_widget.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/notes/presentation/widgets/create_note/body_field_widget.dart)
- Update the styling to feel more like a "Statement" block.
- Add support for inserting text templates or formatting placeholders from the toolbar.

#### [MODIFY] [create_note_controller.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/notes/presentation/controllers/create_note_controller.dart)
- Add a helper method `insertToStatement(String text)` to allow the toolbar to interact with the body text.

## Verification Plan

### Manual Verification
- **Full Screen**: Open an image preview and verify it uses the entire screen area.
- **Statement**: Verify that typing in the body area remains fluid and the toolbar icons can interact with it (if formatting is implemented).
- **Transitions**: Ensure the liquid background remains visible and smooth.
