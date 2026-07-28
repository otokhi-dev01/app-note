import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otokhi_note/modules/note/note_list_controller.dart';
import 'package:otokhi_note/modules/folder/folder_controller.dart';
import 'package:otokhi_note/app/theme/colors.dart';
import 'package:otokhi_note/data/models/note_model.dart';
import 'package:otokhi_note/data/models/folder_model.dart';
import 'package:otokhi_note/core/utils/ui_helpers.dart';
import 'package:otokhi_note/core/widgets/liquid_glass_container.dart';
import 'package:otokhi_note/core/widgets/folder_card.dart';
import 'package:otokhi_note/core/widgets/custom_app_bar.dart';

class TrashView extends StatelessWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NoteListController>() 
      ? Get.find<NoteListController>() 
      : Get.put(NoteListController());
    controller.fetchTrashNotes();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: CustomGlassAppBar(
        titleText: 'Trash',
        actions: [
          TextButton.icon(
            onPressed: () => _confirmClearTrash(controller),
            icon: const Icon(Icons.disabled_by_default_rounded, size: 20, color: AppColors.error, weight: 800),
            label: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Text(
              'Items in trash will be permanently deleted after 30 days.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.5),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.notes.isEmpty && controller.trashFolders.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.notes.isEmpty && controller.trashFolders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 80, color: AppColors.textPlaceholder.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('Trash is empty', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  if (controller.trashFolders.isNotEmpty) ...[
                    const Text('FOLDERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    ...controller.trashFolders.map((FolderModel f) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FolderCard(
                        folder: f, 
                        isGrid: false, 
                        onTap: () => _showFolderTrashOptions(f),
                      ),
                    )),
                    const SizedBox(height: 24),
                  ],
                  if (controller.notes.isNotEmpty) ...[
                    const Text('NOTES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    ...controller.notes.map((n) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildTrashCard(controller, n),
                    )),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearTrash(NoteListController controller) async {
    final confirm = await UIHelpers.showConfirmDialog(
      title: 'Clear Trash',
      message: 'Are you sure you want to permanently delete all items in trash?',
      confirmText: 'Clear All',
    );
    if (confirm == true) {
      controller.clearAllTrash();
    }
  }

  Widget _buildTrashCard(NoteListController controller, NoteModel note) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showRestoreDeleteOptions(controller, note),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled Note' : note.title, 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2), 
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        controller.getDaysRemaining(note.deletedAt),
                        style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note.content?.firstWhereOrNull((b) => b.type == 'text')?.text ?? 'No description available',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                Text(
                  'Deleted: ${note.deletedAt != null ? DateFormat('MMM dd').format(note.deletedAt!) : 'Recently'}', 
                  style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRestoreDeleteOptions(NoteListController controller, NoteModel note) {
    Get.bottomSheet(
      LiquidGlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore_rounded, color: AppColors.primary),
              title: const Text('Restore Note', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Get.back();
                controller.restoreNote(note.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
              title: const Text('Delete Permanently', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onTap: () async {
                Get.back();
                final confirm = await UIHelpers.showConfirmDialog(
                  title: 'Delete Forever',
                  message: 'This action cannot be undone.',
                  confirmText: 'Delete',
                );
                if (confirm == true) {
                  controller.deleteNoteForever(note.id!);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFolderTrashOptions(FolderModel folder) {
    final folderController = Get.find<FolderController>();
    Get.bottomSheet(
      LiquidGlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore_rounded, color: AppColors.primary),
              title: const Text('Restore Folder', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                Get.back();
                await folderController.restoreFolder(folder.id!);
                Get.find<NoteListController>().fetchTrashNotes();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
              title: const Text('Delete Permanently', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onTap: () async {
                Get.back();
                final confirm = await UIHelpers.showConfirmDialog(
                  title: 'Delete Folder Forever',
                  message: 'All notes in this folder will also be deleted permanently.',
                  confirmText: 'Delete',
                );
                if (confirm == true) {
                  await folderController.deleteFolder(folder.id!);
                  Get.find<NoteListController>().fetchTrashNotes();
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
