import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/note_editor_controller.dart';

class NoteEditorView extends GetView<NoteEditorController> {
  const NoteEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: Get.back,
          child: Icon(CupertinoIcons.back, color: theme.colorScheme.onSurface),
        ),
        title: const Text('Edit Note'),
        actions: <Widget>[
          Obx(
            () => IconButton(
              tooltip: 'Note options',
              onPressed:
                  controller.isSaving.value ||
                      controller.isLoading.value ||
                      !controller.hasLoadedNote
                  ? null
                  : () => _showStateOptions(context),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ),
          Obx(
            () => CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: !controller.canEdit || controller.isLoading.value
                  ? null
                  : controller.saveChanges,
              child: controller.isSaving.value
                  ? const CupertinoActivityIndicator()
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Obx(() => _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    final String error = controller.errorMessage.value.trim();

    if (error.isNotEmpty && controller.note.value == null) {
      return _NoteEditorErrorState(
        message: error,
        onRetry: controller.reloadNote,
      );
    }

    return _NoteEditorContent(
      controller: controller,
      onAddAttachment: () {
        _showAttachmentOptions(context);
      },
    );
  }

  Future<void> _showAttachmentOptions(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Add Attachment'),
          message: const Text(
            'Take a photo, choose an image, or select a document.',
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _pickAndUploadImage(source: ImageSource.camera);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(CupertinoIcons.camera, size: 21),
                  SizedBox(width: 9),
                  Text('Take Photo'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _pickAndUploadDocument();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(CupertinoIcons.doc, size: 21),
                  SizedBox(width: 9),
                  Text('Choose Document'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _pickAndUploadImage(source: ImageSource.gallery);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(CupertinoIcons.photo, size: 21),
                  SizedBox(width: 9),
                  Text('Choose Photo'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage({required ImageSource source}) async {
    if (!controller.canEdit) {
      return;
    }

    try {
      final ImagePicker imagePicker = ImagePicker();

      final XFile? selectedImage = await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (selectedImage == null) {
        return;
      }

      await controller.uploadAttachment(filePath: selectedImage.path);
    } catch (error) {
      controller.errorMessage.value = _cleanError(error);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    if (!controller.canEdit) {
      return;
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      final String? path = result?.files.single.path;

      if (path == null || path.trim().isEmpty) {
        return;
      }

      await controller.uploadAttachment(filePath: path);
    } catch (error) {
      controller.errorMessage.value = _cleanError(error);
    }
  }

  Future<void> _showStateOptions(BuildContext context) async {
    final currentNote = controller.note.value;

    if (currentNote == null) {
      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Note Options'),
          message: const Text(
            'Pin important notes, move them to Archive, or lock editing.',
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                controller.togglePin();
              },
              child: Text(currentNote.isPinned ? 'Unpin Note' : 'Pin Note'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                controller.toggleArchive();
              },
              child: Text(
                currentNote.isArchived ? 'Move to Notes' : 'Move to Archive',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                controller.toggleLock();
              },
              child: Text(currentNote.isLocked ? 'Unlock Note' : 'Lock Note'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('ApiException: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }
}

class _NoteEditorContent extends StatelessWidget {
  final NoteEditorController controller;
  final VoidCallback onAddAttachment;

  const _NoteEditorContent({
    required this.controller,
    required this.onAddAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colorScheme = theme.colorScheme;

    final bool isDark = theme.brightness == Brightness.dark;

    final currentNote = controller.note.value;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: <Widget>[
              if (currentNote != null) ...<Widget>[
                _NoteMetadataCard(controller: controller),
                const SizedBox(height: 14),
              ],
              if (controller.isLocked) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        CupertinoIcons.lock_fill,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This note is locked. Unlock it from Note Options to edit.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1D22) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(
                      alpha: isDark ? 0.18 : 0.35,
                    ),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.15 : 0.05,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Title',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.titleController,
                      readOnly: controller.isLocked,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: 250,
                      decoration: const InputDecoration(
                        hintText: 'Enter note title',
                        counterText: '',
                        prefixIcon: Icon(CupertinoIcons.textformat),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Statement',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.statementController,
                      readOnly: controller.isLocked,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 10,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Write your note...',
                        alignLabelWithHint: true,
                        contentPadding: EdgeInsets.all(17),
                      ),
                    ),
                    Obx(() {
                      final String error = controller.errorMessage.value.trim();

                      if (error.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(
                              alpha: 0.70,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                CupertinoIcons.exclamationmark_circle,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  error,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ChecklistCard(controller: controller),
              const SizedBox(height: 14),
              _AttachmentsCard(
                controller: controller,
                onAddAttachment: onAddAttachment,
              ),
              const SizedBox(height: 22),
              Obx(
                () => FilledButton.icon(
                  onPressed: !controller.canEdit
                      ? null
                      : controller.saveChanges,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                  ),
                  icon: controller.isSaving.value
                      ? SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(CupertinoIcons.checkmark_alt),
                  label: Text(
                    controller.isSaving.value ? 'Saving...' : 'Save Changes',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteMetadataCard extends StatelessWidget {
  final NoteEditorController controller;

  const _NoteMetadataCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final note = controller.note.value;

    if (note == null) {
      return const SizedBox.shrink();
    }

    final DateTime? timestamp = note.updatedAt ?? note.createdAt;
    final String folder = note.folderName.trim().isNotEmpty
        ? note.folderName.trim()
        : 'Folder #${note.folderId}';
    final int attachmentCount = note.attachmentCount > 0
        ? note.attachmentCount
        : controller.attachmentBlocks.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Icon(CupertinoIcons.folder, size: 19, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              folder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (attachmentCount > 0) ...<Widget>[
            const Icon(Icons.attach_file_rounded, size: 17),
            const SizedBox(width: 2),
            Text('$attachmentCount'),
            const SizedBox(width: 12),
          ],
          if (timestamp != null)
            Text(
              MaterialLocalizations.of(context).formatShortDate(timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final NoteEditorController controller;

  const _ChecklistCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final List<NoteChecklistBlockDraft> blocks = controller.checklistBlocks;
    final List<({NoteChecklistBlockDraft block, NoteChecklistItemDraft item})>
    rows = <({NoteChecklistBlockDraft block, NoteChecklistItemDraft item})>[
      for (final NoteChecklistBlockDraft block in blocks)
        for (final NoteChecklistItemDraft item in block.items)
          (block: block, item: item),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.18 : 0.35),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.checklist_rounded, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Checklist',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      rows.isEmpty
                          ? 'Add tasks to this note'
                          : '${rows.where((row) => row.item.checked).length} of ${rows.length} completed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Add task',
                onPressed: controller.canEdit
                    ? controller.addChecklistItem
                    : null,
                icon: const Icon(Icons.add_task_rounded),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: <Widget>[
                    Checkbox.adaptive(
                      value: row.item.checked,
                      onChanged: controller.canEdit
                          ? (bool? value) => controller.toggleChecklistItem(
                              row.block.id,
                              row.item.id,
                              value ?? false,
                            )
                          : null,
                    ),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey<String>(row.item.id),
                        initialValue: row.item.text,
                        readOnly: !controller.canEdit,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Task',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: row.item.checked
                              ? TextDecoration.lineThrough
                              : null,
                          color: row.item.checked
                              ? colors.onSurfaceVariant
                              : null,
                        ),
                        onChanged: (String value) =>
                            controller.updateChecklistItem(
                              row.block.id,
                              row.item.id,
                              value,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove task',
                      visualDensity: VisualDensity.compact,
                      onPressed: controller.canEdit
                          ? () => controller.removeChecklistItem(
                              row.block.id,
                              row.item.id,
                            )
                          : null,
                      icon: const Icon(CupertinoIcons.xmark, size: 17),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentsCard extends StatelessWidget {
  final NoteEditorController controller;
  final VoidCallback onAddAttachment;

  const _AttachmentsCard({
    required this.controller,
    required this.onAddAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final List<Map<String, dynamic>> attachments = controller.attachmentBlocks;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.18 : 0.35),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(CupertinoIcons.paperclip, color: colors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Attachments',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      attachments.isEmpty
                          ? 'Add a photo or document'
                          : '${attachments.length} file${attachments.length == 1 ? '' : 's'} attached',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Add attachment',
                onPressed: controller.canEdit ? onAddAttachment : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            const Divider(height: 1),
            for (final Map<String, dynamic> block in attachments)
              _AttachmentTile(block: block),
          ],
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final Map<String, dynamic> block;

  const _AttachmentTile({required this.block});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String attachmentId =
        (block['attachmentId'] ?? block['AttachmentId'] ?? '').toString();
    final String name = _displayName(attachmentId);
    final String extension = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
    final IconData icon =
        <String>{'png', 'jpg', 'jpeg', 'gif', 'webp'}.contains(extension)
        ? CupertinoIcons.photo
        : extension == 'pdf'
        ? CupertinoIcons.doc_text
        : CupertinoIcons.doc;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colors.secondaryContainer,
        foregroundColor: colors.onSecondaryContainer,
        child: Icon(icon, size: 20),
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: attachmentId.trim().isEmpty
          ? null
          : Text('Attachment #$attachmentId'),
    );
  }

  String _displayName(String attachmentId) {
    for (final String key in <String>[
      'displayName',
      'DisplayName',
      'fileName',
      'FileName',
      'name',
      'Name',
    ]) {
      final String value = block[key]?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return attachmentId.trim().isEmpty
        ? 'Attached file'
        : 'Attachment $attachmentId';
  }
}

class _NoteEditorErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _NoteEditorErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.error.withValues(alpha: 0.10),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 39,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to load note',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
