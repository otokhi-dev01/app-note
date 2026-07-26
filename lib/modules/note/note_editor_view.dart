import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'note_controller.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/content_block_model.dart';
import '../folder/folder_controller.dart';
import 'attachment_list_view.dart';
import 'dart:io';

class NoteEditorView extends GetView<NoteController> {
  const NoteEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final int? noteId = Get.arguments as int?;
    controller.initNote(noteId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => IconButton(
            icon: Icon(controller.note.value?.isPinned ?? false ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: controller.togglePin,
          )),
          IconButton(
            onPressed: () => _showMoreActions(context), 
            icon: const Icon(Icons.more_horiz),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: SizedBox(
              width: 80,
              child: Obx(() => AppButton(
                onPressed: controller.saveNote,
                text: 'Save',
                isLoading: controller.isLoading.value,
              )),
            ),
          ),
        ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.blocks.length,
                      itemBuilder: (context, index) {
                        return _buildBlock(index, controller.blocks[index]);
                      },
                    ),
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
        GestureDetector(
          onTap: () => _showFolderPicker(context, folderController),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined, size: 14),
                const SizedBox(width: 4),
                Obx(() {
                  final folderId = controller.selectedFolderId.value;
                  final folder = folderController.folders.firstWhereOrNull((f) => f.id == folderId);
                  return Text(
                    folder?.name ?? 'Select Folder', 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
                  );
                }),
              ],
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
      return TextField(
        onChanged: (val) => controller.updateTextBlock(index, val),
        maxLines: null,
        controller: TextEditingController(text: block.text)..selection = TextSelection.collapsed(offset: block.text?.length ?? 0),
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                  controller: TextEditingController(text: item.text)..selection = TextSelection.collapsed(offset: item.text.length),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (block.text != null && (block.text!.endsWith('.jpg') || block.text!.endsWith('.png')))
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(block.text!), width: 40, height: 40, fit: BoxFit.cover),
                )
              else
                const Icon(Icons.insert_drive_file_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text(block.displayName ?? 'Attachment')),
              const Icon(Icons.close, size: 16),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(onPressed: controller.addImageBlock, icon: const Icon(Icons.image_outlined)),
            IconButton(onPressed: controller.addChecklistBlock, icon: const Icon(Icons.check_box_outlined)),
            IconButton(
              onPressed: () => Get.to(() => const AttachmentListView()), 
              icon: const Icon(Icons.attach_file),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.format_bold)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.format_italic)),
            IconButton(onPressed: controller.addTextBlock, icon: const Icon(Icons.format_list_bulleted)),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_vert, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderPicker(BuildContext context, FolderController folderController) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Move to Folder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

  void _showMoreActions(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
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
              leading: const Icon(Icons.lock_outline),
              title: const Text('Lock Note'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}
