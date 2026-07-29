import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'note_controller.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/content_block_model.dart';
import '../folder/folder_controller.dart';
import '../../core/widgets/liquid_glass_container.dart';
import '../../core/widgets/custom_app_bar.dart';
import 'attachment_list_view.dart';
import 'dart:io';

class NoteEditorView extends GetView<NoteController> {
  const NoteEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamic args = Get.arguments;
    controller.initNote(args);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomGlassAppBar(
        centerTitle: false,
        actions: [
          Obx(() => IconButton(
            icon: Icon(controller.note.value?.isPinned ?? false ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: controller.togglePin,
          )),
          IconButton(
            onPressed: () => _showMoreActions(context), 
            icon: const Icon(Icons.more_horiz_rounded, weight: 800),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: SizedBox(
              width: 80,
              child: Obx(() => AppButton(
                onPressed: controller.saveNote,
                text: 'Done',
                isLoading: controller.isLoading.value,
              )),
            ),
          ),
        ],  bottom: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox(),)
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.note.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTagsHeader(context),
                    const SizedBox(height: 24),
                    TextField(
                      controller: controller.titleController,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'Note Title',
                        hintStyle: TextStyle(color: AppColors.textPlaceholder),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...controller.blocks.asMap().entries.map((entry) {
                      return _buildBlock(entry.key, entry.value);
                    }),
                  ],
                ),
              ),
            ),
            _buildToolbar(),
          ],
        );
      }),
    );
  }

  Widget _buildTagsHeader(BuildContext context) {
    final folderController = Get.find<FolderController>();
    return Row(
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () => _showFolderPicker(context, folderController),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_outlined, size: 14),
                  const SizedBox(width: 4),
                  Obx(() {
                    final folderId = controller.selectedFolderId.value;
                    final folder = folderController.folders.firstWhereOrNull((f) => f.id == folderId);
                    return Text(
                      folder?.name ?? 'Select Folder', 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('+ Add Tag', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildBlock(int index, ContentBlockModel block) {
    if (block.type == 'text') {
      final textController = controller.getBlockController(block.id, block.text);
      return TextField(
        onChanged: (val) => controller.updateTextBlock(index, val),
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        controller: textController,
        style: const TextStyle(fontSize: 18, height: 1.6),
        decoration: const InputDecoration(
          hintText: 'Start typing...',
          hintStyle: TextStyle(color: AppColors.textPlaceholder),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
        ),
      );
    } else if (block.type == 'checklist') {
      return Column(
        children: (block.items ?? []).asMap().entries.map((entry) {
          int itemIndex = entry.key;
          ChecklistItemModel item = entry.value;
          final itemController = controller.getBlockController(item.id, item.text);
          return Row(
            children: [
              Checkbox(
                value: item.checked,
                onChanged: (_) => controller.toggleChecklistItem(index, itemIndex),
                activeColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              Expanded(
                child: TextField(
                  onChanged: (val) => controller.updateChecklistItemText(index, itemIndex, val),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                  controller: itemController,
                  style: TextStyle(
                    decoration: item.checked ? TextDecoration.lineThrough : null,
                    color: item.checked ? AppColors.textPlaceholder : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      );
    } else if (block.type == 'attachment') {
      final isImage = block.text != null && (block.text!.endsWith('.jpg') || block.text!.endsWith('.png'));
      final isVideo = block.text != null && (block.text!.endsWith('.mp4') || block.text!.endsWith('.mov') || block.text!.endsWith('.avi'));

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: LiquidGlassContainer(
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              if (isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(block.text!), width: 40, height: 40, fit: BoxFit.cover),
                )
              else if (isVideo)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.videocam_rounded, color: AppColors.accent),
                )
              else
                const Icon(Icons.insert_drive_file_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.displayName ?? (isVideo ? 'Video Attachment' : 'Attachment'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (isVideo)
                      const Text('Video', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (block.attachmentId != null) {
                    controller.deleteAttachment(block.attachmentId!);
                  } else {
                    // Logic for local block removal if not synced yet
                  }
                },
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: controller.addImageBlock, icon: const Icon(Icons.image_outlined)),
              IconButton(onPressed: controller.addVideoBlock, icon: const Icon(Icons.videocam_outlined)),
              IconButton(onPressed: controller.addChecklistBlock, icon: const Icon(Icons.check_box_outlined)),
              IconButton(
                onPressed: () => Get.to(() => const AttachmentListView()), 
                icon: const Icon(Icons.attach_file),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.format_bold)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.format_italic)),
              IconButton(onPressed: controller.addTextBlock, icon: const Icon(Icons.format_list_bulleted)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.more_vert, color: AppColors.accent),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showFolderPicker(BuildContext context, FolderController folderController) {
    Get.bottomSheet(
      LiquidGlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Move to Folder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    Get.back();
                    _showNewFolderDialog(context, folderController);
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('New Folder', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: folderController.folders.length,
                itemBuilder: (context, index) {
                  final folder = folderController.folders[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(folder.name),
                    trailing: Obx(() => controller.selectedFolderId.value == folder.id 
                      ? const Icon(Icons.check_circle, color: AppColors.accent) 
                      : const SizedBox()),
                    onTap: () {
                      controller.changeFolder(folder.id!);
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewFolderDialog(BuildContext context, FolderController folderController) {
    folderController.selectedFolder.value = null;
    folderController.nameController.clear();
    folderController.selectedColorIndex.value = 0;
    folderController.selectedIconIndex.value = 0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: LiquidGlassContainer(
          borderRadius: BorderRadius.circular(30),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Folder', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: folderController.nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Travel Plans',
                    prefixIcon: const Icon(Icons.folder_open_outlined),
                    filled: true,
                    fillColor: AppColors.background.withValues(alpha: 0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('COLOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppColors.folderColors.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => Obx(() => GestureDetector(
                      onTap: () => folderController.selectedColorIndex.value = index,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.folderColors[index],
                          shape: BoxShape.circle,
                          border: folderController.selectedColorIndex.value == index 
                            ? Border.all(color: AppColors.accent, width: 2) 
                            : null,
                        ),
                        child: folderController.selectedColorIndex.value == index 
                          ? const Icon(Icons.check, color: Colors.white, size: 20) 
                          : null,
                      ),
                    )),
                  ),
                ),
                const SizedBox(height: 40),
                AppButton(
                  onPressed: () async {
                    await folderController.createFolder();
                    // Auto-select the newly created folder for the current note
                    if (folderController.folders.isNotEmpty) {
                      controller.changeFolder(folderController.folders.last.id!);
                    }
                  },
                  text: 'Create & Use',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreActions(BuildContext context) {
    Get.bottomSheet(
      LiquidGlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive Note'),
              onTap: () {
                Get.back();
                controller.archiveNote();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Note', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Get.back();
                controller.deleteNote();
              },
            ),
            ListTile(
              leading: Obx(() => Icon(
                controller.note.value?.isLocked ?? false ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                color: AppColors.primary,
              )),
              title: Obx(() => Text(
                controller.note.value?.isLocked ?? false ? 'Unlock Note' : 'Lock Note',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
              onTap: () {
                Get.back();
                controller.toggleLock();
              },
            ),
          ],
        ),
      ),
    );
  }
}
