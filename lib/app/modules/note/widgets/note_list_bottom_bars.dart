import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../routes/note_navigation.dart';
import '../../../widgets/glass_widgets.dart';
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.SEARCH),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: theme.brightness == Brightness.dark ? null : [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.search, size: 22),
                      SizedBox(width: 8),
                      Expanded(child: Text("Search", style: TextStyle(fontSize: 17))),
                      Icon(Icons.mic, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            LiquidGlassContainer(
              width: 50,
              height: 50,
              borderRadius: 25,
              child: IconButton(
                onPressed: () => NoteNavigation.toNewNote(folderId)
                    ?.then((value) => controller.fetchNotes(folderId: folderId)),
                icon: Icon(Icons.open_in_new, color: theme.colorScheme.onSurface, size: 28),
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Obx(() {
          final selectedCount = controller.selectedNoteIds.length;
          final moveText = selectedCount == 0 ? "Move All" : selectedCount == 1 ? "Move" : "Move ($selectedCount)";
          final deleteText = selectedCount == 0 ? "Delete All" : selectedCount == 1 ? "Delete" : "Delete ($selectedCount)";

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(label: moveText, onTap: () => controller.moveSelectedNotes(context, folderId)),
              _ActionButton(label: deleteText, onTap: () => controller.deleteSelectedNotes(folderId)),
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

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlassContainer(
        borderRadius: 25,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
