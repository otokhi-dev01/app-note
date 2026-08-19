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

    // Same floating-pill footprint as the Folder screen's bottom bar: a
    // wide "Search" pill plus a circular accent button. "Folders" is dropped
    // since the app bar already has a back button, and "Profile" now lives
    // under Settings rather than a bottom-bar tab.
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? 10 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: CustomGlassButton(
                onPressed: () => Get.toNamed(Routes.SEARCH),
                semanticLabel: 'Search notes and folders',
                height: 50,
                borderRadius: 30,
                blur: 10,
                opacity: 0.15,
                thickness: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 17,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      CupertinoIcons.mic_fill,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
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
              semanticLabel: 'Create note',
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
              ? "Move All"
              : selectedCount == 1
              ? "Move"
              : "Move ($selectedCount)";
          final deleteText = selectedCount == 0
              ? "Delete All"
              : selectedCount == 1
              ? "Delete"
              : "Delete ($selectedCount)";

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
                      title: "Delete $noteCount Notes?",
                      message: "These notes will be moved to Recently Deleted.",
                      confirmLabel: "Delete",
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
