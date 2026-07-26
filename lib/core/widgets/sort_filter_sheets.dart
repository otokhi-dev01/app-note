import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/colors.dart';
import 'liquid_glass_container.dart';

class SortSheet extends StatelessWidget {
  const SortSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sort By', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildOption('Date Created (Newest)', true),
          _buildOption('Date Created (Oldest)', false),
          _buildOption('Title (A-Z)', false),
          _buildOption('Title (Z-A)', false),
          _buildOption('Recently Modified', false),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOption(String title, bool isSelected) {
    return ListTile(
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.accent) : null,
      onTap: () => Get.back(result: title),
    );
  }
}

class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
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
          Wrap(
            spacing: 12,
            children: [
              _buildChip('All', true),
              _buildChip('Pinned', false),
              _buildChip('Locked', false),
              _buildChip('Archived', false),
            ],
          ),
          const SizedBox(height: 24),
          const Text('TYPE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _buildChip('Notes', true),
              _buildChip('Checklists', false),
              _buildChip('Attachments', false),
            ],
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => Get.back(),
            child: const Text('Apply Filters'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
      onSelected: (_) {},
    );
  }
}
