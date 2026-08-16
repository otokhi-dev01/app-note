import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../routes/note_navigation.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../widgets/ios_confirmation_dialog.dart';
import '../controllers/note_controller.dart';

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
    return SafeArea(
      top: false,
      child: CustomGlassTabBar.bottom(
        tabs: const [
          CustomGlassTab(
            icon: Icon(CupertinoIcons.folder),
            activeIcon: Icon(CupertinoIcons.folder_fill),
            label: 'Folders',
            semanticLabel: 'Folders',
          ),
          CustomGlassTab(
            icon: Icon(CupertinoIcons.profile_circled),
            activeIcon: Icon(CupertinoIcons.profile_circled),
            label: 'Profile',
            semanticLabel: 'Profile',
          ),
          CustomGlassTab(
            icon: Icon(CupertinoIcons.search),
            label: 'Search',
            semanticLabel: 'Search notes and folders',
          ),
        ],
        selectedIndex: 0,
        onTabSelected: (index) {
          if (index == 0) {
            Get.back();
          } else if (index == 1) {
            Get.toNamed(Routes.PROFILE);
          } else if (index == 2) {
            Get.toNamed(Routes.SEARCH);
          }
        },
        extraButton: CustomGlassTabBarExtraButton(
          icon: const Icon(CupertinoIcons.square_pencil),
          onTap: () => NoteNavigation.toNewNote(folderId)
              ?.then((value) => controller.fetchNotes(folderId: folderId)),
          label: 'Create note',
          iconColor: theme.primaryColor,
          size: 56,
        ),
        horizontalPadding: 12,
        verticalPadding: 8,
        barHeight: 64,
        selectedIconColor: theme.primaryColor,
        unselectedIconColor: theme.colorScheme.onSurfaceVariant,
        adaptiveBrightness: true,
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
                    final noteCount = selectedCount == 0 ? controller.notes.length : selectedCount;
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
