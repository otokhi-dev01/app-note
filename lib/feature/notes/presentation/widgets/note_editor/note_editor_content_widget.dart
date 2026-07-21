part of '../../view/note_editor_view.dart';

class _NoteEditorContent extends StatelessWidget {
  final NoteEditorController controller;
  final VoidCallback onAddAttachment;

  const _NoteEditorContent({
    required this.controller,
    required this.onAddAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final currentNote = controller.note.value;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (currentNote != null) ...<Widget>[
                  _NoteMetadataCard(controller: controller),
                  const SizedBox(height: 12),
                ],

                if (controller.isLocked) ...<Widget>[
                  const _LockedNoteBanner(),
                  const SizedBox(height: 12),
                ],

                _NoteTextSection(controller: controller),

                Obx(() {
                  final String error = controller.errorMessage.value.trim();

                  if (error.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InlineErrorBanner(message: error),
                  );
                }),

                const SizedBox(height: 12),

                _ChecklistCard(controller: controller),

                const SizedBox(height: 12),

                _AttachmentsCard(
                  controller: controller,
                  onAddAttachment: onAddAttachment,
                ),

                const SizedBox(height: 20),

                Obx(
                  () => _BottomSaveButton(
                    saving: controller.isSaving.value,
                    enabled: controller.canEdit && !controller.isSaving.value,
                    onPressed: controller.saveChanges,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
