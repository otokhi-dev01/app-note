import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/glass_widgets.dart';
import 'package:Note/app/modules/note/controllers/note_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NoteContextMenu extends StatelessWidget {
  final NoteController controller;

  const NoteContextMenu({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Get.back(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            40,
            60,
            20,
            0,
          ), // Anchored to top-right
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {}, // Prevent taps on the menu itself from closing it
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child:
                    LiquidGlassContainer(
                          borderRadius: 16,
                          opacity: 0.98,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Obx(
                            () => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMenuItem(
                                  context,
                                  controller.viewMode.value == "list"
                                      ? "View as Gallery"
                                      : "View as List",
                                  controller.viewMode.value == "list"
                                      ? Icons.grid_view_rounded
                                      : Icons.list_rounded,
                                  onTap: () {
                                    Get.back();
                                    controller.toggleViewMode();
                                  },
                                ),
                                _buildDivider(context),
                                _buildMenuItem(
                                  context,
                                  "Select Notes",
                                  Icons.check_circle_outline,
                                  onTap: () {
                                    Get.back();
                                    controller.toggleEditing();
                                  },
                                ),
                                _buildDivider(context),
                                _buildMenuItem(
                                  context,
                                  "Sort By",
                                  Icons.swap_vert_rounded,
                                  subtitle: "Default (Date Edited)",
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  onTap: () {
                                    Get.back();
                                    controller.updateSorting("Date Edited");
                                  },
                                ),
                                _buildDivider(context),
                                _buildMenuItem(
                                  context,
                                  "Group By Date",
                                  Icons.calendar_view_day_rounded,
                                  subtitle: "Default (On)",
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  onTap: () {
                                    Get.back();
                                    controller.toggleDateGrouping();
                                  },
                                ),
                                _buildDivider(context),
                                _buildMenuItem(
                                  context,
                                  "View Attachments",
                                  Icons.attach_file_rounded,
                                  onTap: () {
                                    Get.back();
                                    controller.viewAllAttachments();
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .scale(
                          duration: 200.ms,
                          curve: Curves.easeOutBack,
                          alignment: Alignment.topRight,
                        )
                        .fadeIn(duration: 150.ms),
              ),
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
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: theme.colorScheme.onSurface, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            )
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
