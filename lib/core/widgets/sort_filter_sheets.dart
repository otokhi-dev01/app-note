import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/colors.dart';
import 'package:otokhi_note/modules/note/note_list_controller.dart';
import 'liquid_glass_container.dart';

class SortSheet extends StatelessWidget {
  const SortSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NoteListController>();

    return LiquidGlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sort By', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Obx(() => Column(
            children: [
              _buildOption(controller, 'Date Created (Newest)'),
              _buildOption(controller, 'Date Created (Oldest)'),
              _buildOption(controller, 'Title (A-Z)'),
              _buildOption(controller, 'Title (Z-A)'),
              _buildOption(controller, 'Recently Modified'),
            ],
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOption(NoteListController controller, String title) {
    final isSelected = controller.currentSort.value == title;
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.accent) : null,
      onTap: () {
        controller.updateSort(title);
        Get.back();
      },
    );
  }
}

class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NoteListController>();

    return LiquidGlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('STATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Obx(() => Wrap(
            spacing: 12,
            children: [
              _buildChip(controller, 'All', isState: true),
              _buildChip(controller, 'Pinned', isState: true),
              _buildChip(controller, 'Locked', isState: true),
              _buildChip(controller, 'Archived', isState: true),
            ],
          )),
          const SizedBox(height: 24),
          const Text('TYPE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Obx(() => Wrap(
            spacing: 12,
            children: [
              _buildChip(controller, 'Notes', isState: false),
              _buildChip(controller, 'Checklists', isState: false),
              _buildChip(controller, 'Attachments', isState: false),
            ],
          )),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Get.back(),
            child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChip(NoteListController controller, String label, {required bool isState}) {
    final isSelected = isState 
        ? controller.currentStateFilter.value == label 
        : controller.currentTypeFilter.value == label;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        if (isState) {
          controller.updateFilters(state: label);
        } else {
          controller.updateFilters(type: label);
        }
      },
    );
  }
}
