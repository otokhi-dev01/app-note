import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/note_detail_controller.dart';

class NoteDetailMorePopup extends StatelessWidget {
  final NoteDetailController controller;

  const NoteDetailMorePopup({super.key, required this.controller});

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
                  borderRadius: 20,
                  opacity: 0.98,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Obx(() => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(
                        context,
                        controller.isPinned.value ? "Unpin" : "Pin",
                        controller.isPinned.value ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
                        onTap: () {
                          Get.back();
                          controller.togglePin();
                        },
                      ),
                      _buildDivider(context),
                      _buildMenuItem(
                        context,
                        controller.isArchived.value ? "Unarchive" : "Archive",
                        controller.isArchived.value ? CupertinoIcons.archivebox_fill : CupertinoIcons.archivebox,
                        onTap: () {
                          Get.back();
                          controller.toggleArchive();
                        },
                      ),
                      _buildDivider(context),
                      _buildMenuItem(
                        context,
                        controller.isLocked.value ? "Unlock" : "Lock",
                        controller.isLocked.value ? CupertinoIcons.lock_fill : CupertinoIcons.lock,
                        onTap: () {
                          Get.back();
                          controller.toggleLock();
                        },
                      ),
                      _buildDivider(context),
                      _buildMenuItem(
                        context,
                        "Move",
                        CupertinoIcons.folder_badge_plus,
                        onTap: () {
                          Get.back();
                          controller.moveNote();
                        },
                      ),
                      _buildDivider(context),
                      _buildMenuItem(
                        context,
                        "Find in Note",
                        CupertinoIcons.doc_text_search,
                        onTap: () {
                          Get.back();
                          controller.toggleSearch();
                        },
                      ),
                      _buildDivider(context),
                      _buildMenuItem(
                        context,
                        "Delete",
                        CupertinoIcons.trash,
                        isDestructive: true,
                        onTap: () {
                          Get.back();
                          controller.deleteNote();
                        },
                      ),
                    ],
                  )),
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
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? CupertinoColors.destructiveRed : theme.colorScheme.onSurface;
    
    return ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
      ),
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
