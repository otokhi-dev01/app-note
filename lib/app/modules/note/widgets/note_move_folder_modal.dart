import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';

class NoteMoveFolderModal extends StatelessWidget {
  final List<FolderModel> folders;
  final int currentFolderId;
  final Function(FolderModel) onFolderSelected;

  const NoteMoveFolderModal({
    super.key,
    required this.folders,
    required this.currentFolderId,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final currentFolder = folders.firstWhereOrNull((f) => f.id == currentFolderId);
    
    return Material(
      color: AppTheme.bodyColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: Get.height * 0.9,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.black, size: 20),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Select a Folder",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32), // Spacer to balance header
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Folder Summary
                    if (currentFolder != null) ...[
                      Row(
                        children: [
                          LiquidGlassContainer(
                            width: 60,
                            height: 60,
                            borderRadius: 12,
                            child: Icon(currentFolder.icon, color: currentFolder.color, size: 36),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currentFolder.name, 
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              Text("${currentFolder.noteCount} Notes", 
                                style: const TextStyle(color: AppTheme.textGrey, fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    // On My iPhone Section
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8),
                      child: Text("On My iPhone", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),

                    GlassCard(
            borderRadius: 30,
            children: [
                        // New Folder Action
                        ListTile(
                          onTap: () {},
                          leading: const Icon(Icons.create_new_folder_outlined, color: AppTheme.folderPink),
                          title: const Text("New Folder", 
                            style: TextStyle(color: AppTheme.folderPink, fontWeight: FontWeight.w500)),
                        ),
                        const Divider(indent: 56, height: 1),
                        
                        // Folder List
                        for (int i = 0; i < folders.length; i++) ...[
                          _buildFolderTile(folders[i]),
                          if (i < folders.length - 1)
                            const Divider(indent: 56, height: 1),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderTile(FolderModel folder) {
    final isCurrent = folder.id == currentFolderId;
    final isSystem = ["Notes", "All on My iPhone"].contains(folder.name);

    return Opacity(
      opacity: (isCurrent || isSystem) ? 0.3 : 1.0,
      child: ListTile(
        onTap: (isCurrent || isSystem) ? null : () => onFolderSelected(folder),
        leading: Icon(folder.icon, color: folder.color, size: 24),
        title: Text(folder.name, style: const TextStyle(fontSize: 17)),
        trailing: isCurrent 
            ? Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.folderPink,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            : const Icon(Icons.chevron_right, color: AppTheme.textGrey, size: 20),
      ),
    );
  }
}
