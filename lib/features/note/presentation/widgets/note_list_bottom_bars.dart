import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/routes/note_navigation.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/ios_confirmation_dialog.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';

class NoteListBottomBar extends StatelessWidget {
  final int folderId;
  final NoteController controller;

  const NoteListBottomBar({
    super.key,
    required this.folderId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? 10 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: CustomGlassContainer(
                height: 50,
                borderRadius: 30,
                blur: 10,
                opacity: 0.15,
                thickness: 8,
                padding: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'note_list_search_semantic'.tr,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Get.toNamed(Routes.SEARCH),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.search,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'note_list_search'.tr,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 17,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'note_editor_record_audio'.tr,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 50),
                        onPressed: () =>
                            NoteNavigation.toNewAudioNote(folderId)?.then(
                              (_) => controller.fetchNotes(folderId: folderId),
                            ),
                        child: Icon(
                          CupertinoIcons.mic_fill,
                          color: CupertinoColors.systemRed.resolveFrom(context),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            CustomGlassButton(
              onPressed: () => NoteNavigation.toNewNote(
                folderId,
              )?.then((value) => controller.fetchNotes(folderId: folderId)),
              semanticLabel: 'note_list_create_note'.tr,
              width: 50,
              height: 50,
              shape: GlassShape.circle,
              blur: 10,
              opacity: 0.15,
              thickness: 8,
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.square_pencil,
                color: theme.primaryColor,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteListEditBar extends StatelessWidget {
  final int folderId;
  final NoteController controller;

  const NoteListEditBar({
    super.key,
    required this.folderId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Obx(() {
          final selectedCount = controller.selectedNoteIds.length;
          final moveText = selectedCount == 0
              ? "note_list_move_all".tr
              : selectedCount == 1
              ? "note_list_move".tr
              : "note_list_move_count".trParams({'count': '$selectedCount'});
          final deleteText = selectedCount == 0
              ? "note_list_delete_all".tr
              : selectedCount == 1
              ? "note_list_delete".tr
              : "note_list_delete_count".trParams({'count': '$selectedCount'});

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _ActionButton(
                  label: moveText,
                  onTap: () => controller.moveSelectedNotes(context, folderId),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionButton(
                  label: deleteText,
                  color: Colors.redAccent,
                  onTap: () {
                    final noteCount = selectedCount == 0
                        ? controller.notes.length
                        : selectedCount;
                    if (noteCount == 0) return;
                    IOSConfirmationDialog.show(
                      title: "note_list_delete_confirm_title".trParams({
                        'count': '$noteCount',
                      }),
                      message: "note_list_delete_confirm_message".tr,
                      confirmLabel: "note_list_delete".tr,
                      onConfirm: () {
                        Get.back();
                        controller.deleteSelectedNotes(folderId);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomGlassButton(
      onPressed: onTap,
      height: 48,
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      blur: 10,
      opacity: 0.15,
      thickness: 8,
      child: Text(
        label,
        style: TextStyle(
          color: color ?? theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
