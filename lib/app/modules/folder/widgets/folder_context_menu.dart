import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/folder_controller.dart';
import 'folder_create_modal.dart';

import 'package:flutter_animate/flutter_animate.dart';

class FolderContextMenu extends StatelessWidget {
  final FolderModel folder;
  final FolderController controller;

  const FolderContextMenu({super.key, required this.folder, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Get.back(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 60, 20, 0), // Anchored to top-right
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {}, // Prevent taps on the menu itself from closing it
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: LiquidGlassContainer(
                  borderRadius: 14,
                  opacity: 0.98,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(
                        context,
                        "Add Folder",
                        Icons.create_new_folder_outlined,
                        onTap: () {
                          Get.back();
                          Get.bottomSheet(
                            FolderCreateModal(controller: controller),
                            isScrollControlled: true,
                          );
                        },
                      ),
                      _buildDivider(context),
                      _buildMenuItem(
                        context,
                        "Move This Folder",
                        Icons.folder_open_outlined,
                        onTap: () {
                          Get.back();
                          controller.onMoveFolder(folder);
                        },
                      ),
                      _buildDivider(context),
                      _buildMenuItem(
                        context,
                        "Rename",
                        Icons.edit_outlined,
                        onTap: () {
                          Get.back();
                          controller.onRenameFolder(folder);
                        },
                      ),
                      _buildDivider(context),
                      _buildMenuItem(
                        context,
                        "Group By Date",
                        Icons.calendar_view_day_outlined,
                        subtitle: "Default (On)",
                        trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textGrey),
                        onTap: () {
                          Get.back();
                          controller.onToggleGroupByDate(folder);
                        },
                      ),
                      _buildDivider(context),
                      _buildMenuItem(
                        context,
                        "Delete",
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        onTap: () {
                          Get.back();
                          controller.onDeleteFolder(folder);
                        },
                      ),
                      _buildDivider(context),
                      _buildMenuItem(
                        context,
                        "Convert to Smart Folder",
                        Icons.settings_outlined,
                        onTap: () {
                          Get.back();
                          controller.onConvertToSmartFolder(folder);
                        },
                      ),
                    ],
                  ),
                ),
              ).animate().scale(
                duration: 200.ms,
                curve: Curves.easeOutBack,
                alignment: Alignment.topRight,
              ).fadeIn(duration: 150.ms),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon, {
    String? subtitle,
    Widget? trailing,
    Color? color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.colorScheme.onSurface;
    
    return ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: primaryColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: primaryColor,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13))
          : null,
      trailing: trailing,
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      indent: 56, 
      height: 1, 
      thickness: 0.5, 
      color: Theme.of(context).dividerColor,
    );
  }
}
