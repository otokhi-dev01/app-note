import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes/app/theme/colors.dart';
import 'package:notes/core/utils/image_helper.dart';
import '../../../../data/models/note_model.dart';
import '../../../../domain/entities/folder.dart';
import '../../../../domain/entities/note.dart';
import '../../../../shared/components/note_card.dart';
import '../home_controller.dart';
import '../home_style.dart';

// --- Action Menus ---

void showFolderOptionsMenu(
  BuildContext context,
  Folder? f,
  HomeController controller,
) {
  HapticFeedback.mediumImpact();
  showCupertinoModalPopup(
    context: context,
    builder: (context) => CupertinoActionSheet(
      actions: [
        buildActionItem(
          controller.isGalleryView.value
              ? CupertinoIcons.list_bullet
              : CupertinoIcons.square_grid_2x2,
          controller.isGalleryView.value ? 'View as List' : 'View as Gallery',
          () {
            Get.back();
            controller.toggleViewMode();
          },
        ),
        const Divider(height: 0.5),
        buildActionItem(
          CupertinoIcons.person_badge_plus,
          'Share Folder',
          () => Get.back(),
        ),
        buildActionItem(CupertinoIcons.folder_badge_plus, 'Add Folder', () {
          Get.back();
          controller.openCreateFolder();
        }),
        buildActionItem(
          CupertinoIcons.folder,
          'Move This Folder',
          () => Get.back(),
        ),
        buildActionItem(CupertinoIcons.pencil, 'Rename', () {
          Get.back();
          if (f != null) controller.renameFolder(f);
        }),
        buildActionItem(
          CupertinoIcons.check_mark_circled,
          'Select Notes',
          () => Get.back(),
        ),

        buildActionItem(
          CupertinoIcons.arrow_up_arrow_down,
          'Sort By',
          () => Get.back(),
          subtitle: 'Default (Date Edited)',
        ),
        buildActionItem(
          CupertinoIcons.calendar,
          'Group By Date',
          () => Get.back(),
          subtitle: 'Default (On)',
        ),
        buildActionItem(CupertinoIcons.paperclip, 'View Attachments', () {
          Get.back();
          controller.searchByFilter('attachments');
        }),

        const Divider(height: 0.5),
        buildActionItem(
          CupertinoIcons.settings,
          'Convert to Smart Folder',
          () => Get.back(),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    ),
  );
}

void showFolderEditMenu(
  BuildContext context,
  Folder f,
  HomeController controller,
) {
  HapticFeedback.mediumImpact();
  showCupertinoModalPopup(
    context: context,
    builder: (context) => CupertinoActionSheet(
      actions: [
        buildActionItem(
          CupertinoIcons.person_badge_plus,
          'Share Folder',
          () => Get.back(),
        ),
        buildActionItem(CupertinoIcons.folder_badge_plus, 'Add Folder', () {
          Get.back();
          controller.openCreateFolder();
        }),
        buildActionItem(
          CupertinoIcons.folder,
          'Move This Folder',
          () => Get.back(),
        ),
        buildActionItem(CupertinoIcons.pencil, 'Rename', () {
          Get.back();
          controller.renameFolder(f);
        }),
        buildActionItem(CupertinoIcons.calendar, 'Group By Date', () {
          Get.back();
          Get.snackbar(
            "Sort Options",
            "Grouping options are not available yet.",
          );
        }, subtitle: 'Default (On)'),
        buildActionItem(CupertinoIcons.trash, 'Delete', () {
          Get.back();
          controller.deleteFolder(f);
        }, isDestructive: true),
        buildActionItem(CupertinoIcons.settings, 'Convert to Smart Folder', () {
          Get.back();
          Get.snackbar(
            "Smart Folders",
            "Smart folder conversion is coming soon!",
          );
        }),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    ),
  );
}

void showTrashNoteOptions(
  BuildContext context,
  Note note,
  HomeController controller,
) {
  HapticFeedback.mediumImpact();
  showCupertinoModalPopup(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(
        'Note from ${DateFormat('MMM dd, yyyy').format(note.updatedAt)}',
      ),
      message: const Text('This note is in the Recently Deleted folder.'),
      actions: [
        buildActionItem(CupertinoIcons.arrow_up_left, 'Restore', () {
          Get.back();
          controller.restoreNote(note);
        }),
        buildActionItem(CupertinoIcons.trash, 'Delete Permanently', () {
          Get.back();
          controller.permanentlyDeleteNote(note);
        }, isDestructive: true),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    ),
  );
}

Widget buildActionItem(
  IconData icon,
  String title,
  VoidCallback onTap, {
  String? subtitle,
  bool isDestructive = false,
}) {
  final colors = Theme.of(Get.context!).colorScheme;
  final Color color = isDestructive ? colors.error : colors.onSurface;
  return CupertinoActionSheetAction(
    onPressed: onTap,
    child: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
        if (title == 'Group By Date' || title == 'Sort By')
          Icon(
            CupertinoIcons.chevron_right,
            color: colors.onSurfaceVariant,
            size: 14,
          ),
      ],
    ),
  );
}

// --- Header ---

class HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final HomeStyle style;
  final HomeController controller;
  final double topPadding;

  HomeHeaderDelegate({
    required this.style,
    required this.controller,
    required this.topPadding,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Obx(() {
      final isFolder = controller.isFolderView.value;
      final isTrash = controller.isTrashView.value;
      final isEmpty =
          controller.filteredNotes.isEmpty && controller.pinnedNotes.isEmpty;
      final trashCount = controller.trashNotes.length;
      final title = isTrash
          ? 'Recently Deleted'
          : (isFolder
                ? 'Folders'
                : (controller.selectedFolder.value?.name ?? 'Notes'));

      final double progress = shrinkOffset / (maxExtent - minExtent);
      final double opacity = progress.clamp(0.0, 1.0);
      final double largeTitleOpacity = (1.0 - progress * 2.5).clamp(0.0, 1.0);

      return Container(
        color: style.background.withValues(alpha: opacity > 0.5 ? 0.95 : 1.0),
        child: Stack(
          children: [
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (!isFolder || isTrash)
                      HeaderCircleButton(
                        onTap: controller.showFolders,
                        child: Icon(
                          CupertinoIcons.left_chevron,
                          color: style.primaryText,
                          size: 20,
                        ),
                      ),
                    const Spacer(),
                    if (isFolder || isTrash) ...[
                      if (isFolder)
                        HeaderCircleButton(
                          onTap: controller.openCreateFolder,
                          child: Icon(
                            CupertinoIcons.folder_badge_plus,
                            color: style.primaryText,
                            size: 22,
                          ),
                        ),
                      const SizedBox(width: 12),
                      HeaderCircleButton(
                        onTap: controller.goToSettings,
                        child: Icon(
                          CupertinoIcons.settings,
                          color: style.primaryText,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      HeaderCircleButton(
                        onTap: isTrash
                            ? controller.clearTrash
                            : controller.toggleEdit,
                        child: isTrash
                            ? Text(
                                'Empty',
                                style: TextStyle(
                                  color: controller.trashNotes.isEmpty
                                      ? style.secondaryText
                                      : HomeStyle.red,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : controller.isEditing.value
                            ? Icon(
                                CupertinoIcons.check_mark,
                                color: style.primaryText,
                                size: 20,
                              )
                            : Text(
                                'Edit',
                                style: TextStyle(
                                  color: style.primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ] else ...[
                      HeaderPillButton(
                        children: [
                          ActionIconButton(
                            icon: CupertinoIcons.share,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Get.snackbar(
                                "Share Folder",
                                "Sharing features are coming soon!",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: style.surface,
                                colorText: style.primaryText,
                                margin: const EdgeInsets.all(16),
                                borderRadius: 16,
                              );
                            },
                          ),
                          ActionIconButton(
                            icon: CupertinoIcons.ellipsis,
                            onTap: () => showFolderOptionsMenu(
                              context,
                              controller.selectedFolder.value,
                              controller,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: 60,
              child: Center(
                child: Opacity(
                  opacity: opacity > 0.7 ? (opacity - 0.7) * 3.33 : 0,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: style.primaryText,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 20,
              right: 20,
              child: Opacity(
                opacity: largeTitleOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: style.primaryText,
                      ),
                    ),
                    if (isTrash)
                      Text(
                        '$trashCount ${trashCount == 1 ? 'Note' : 'Notes'}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    else if (!isFolder && isEmpty)
                      const Text(
                        'No Notes',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  double get maxExtent => 140 + topPadding;
  @override
  double get minExtent => 60 + topPadding;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

// --- List Widgets ---

class FoldersList extends StatelessWidget {
  final HomeStyle style;
  final HomeController controller;
  const FoldersList({super.key, required this.style, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.isEditing.value;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          SectionHeader(
            title: 'My Notes',
            onToggle: controller.toggleNotesSection,
            isExpanded: controller.isNotesSectionExpanded.value,
          ),
          if (controller.isNotesSectionExpanded.value)
            FolderSection(
              style: style,
              children: [
                FolderRow(
                  style: style,
                  title: 'All Notes',
                  icon: CupertinoIcons.folder,
                  iconColor: isEditing ? AppColors.outline : AppColors.yellow,
                  count: controller.notes.length,
                  onTap: () => controller.selectFolder(null),
                  isLast: controller.folders.isEmpty,
                  isEditing: isEditing,
                  isSystem: true,
                ),
                ...controller.folders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final f = entry.value;
                  final isLast = index == controller.folders.length - 1;
                  return FolderRow(
                    style: style,
                    title: f.name,
                    icon: CupertinoIcons.folder,
                    iconColor: AppColors.yellow,
                    count: controller.notes
                        .where((n) => n.folderId == f.id)
                        .length,
                    onTap: () => isEditing
                        ? showFolderEditMenu(context, f, controller)
                        : controller.selectFolder(f),
                    isLast: isLast,
                    isEditing: isEditing,
                  );
                }),
                FolderRow(
                  style: style,
                  title: 'Recently Deleted',
                  icon: CupertinoIcons.trash,
                  iconColor: isEditing ? AppColors.outline : AppColors.primary,
                  count: controller.trashNotes.length,
                  onTap: controller.openRecentlyDeleted,
                  isLast: true,
                  isEditing: isEditing,
                  isSystem: true,
                ),
              ],
            ),
        ]),
      ),
    );
  }
}

class TrashList extends StatelessWidget {
  final HomeStyle style;
  final HomeController controller;
  const TrashList({super.key, required this.style, required this.controller});

  @override
  Widget build(BuildContext context) {
    final trash = controller.trashNotes;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text(
              'Deleted notes stay here until you restore or permanently remove them.',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
          ),
          if (trash.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(
                child: Text(
                  'No Notes',
                  style: TextStyle(color: Colors.grey, fontSize: 17),
                ),
              ),
            )
          else
            FolderSection(
              style: style,
              children: trash.asMap().entries.map((entry) {
                final index = entry.key;
                final note = entry.value;
                final folder = controller.folders.firstWhereOrNull(
                  (f) => f.id == note.folderId,
                );

                return NoteCard(
                  key: ValueKey('trash-note-${note.id}'),
                  note: NoteModel.fromEntity(note),
                  onTap: () => showTrashNoteOptions(context, note, controller),
                  onDelete: () => controller.permanentlyDeleteNote(note),
                  onMove: () => controller.restoreNote(note),
                  onPin: null,
                  onShare: null,
                  isLast: index == trash.length - 1,
                  subtitle: Row(
                    children: [
                      Text(
                        DateFormat('h:mm').format(note.updatedAt) +
                            (note.updatedAt.hour >= 12
                                ? ' in the afternoon'
                                : ' in the morning'),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          folder?.name ?? 'Notes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ]),
      ),
    );
  }
}

class SearchOverlay extends StatelessWidget {
  final HomeStyle style;
  final HomeController controller;
  const SearchOverlay({
    super.key,
    required this.style,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: style.background,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              children: [
                Text(
                  'Suggested',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: style.primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                FolderSection(
                  style: style,
                  children: [
                    FolderRow(
                      style: style,
                      title: 'Shared Notes',
                      icon: CupertinoIcons.person_crop_circle,
                      iconColor: AppColors.yellow,
                      count: 0,
                      onTap: () => controller.searchByFilter('shared'),
                      hideCount: true,
                    ),
                    FolderRow(
                      style: style,
                      title: 'Locked Notes',
                      icon: CupertinoIcons.lock_fill,
                      iconColor: AppColors.yellow,
                      count: 0,
                      onTap: () => controller.searchByFilter('locked'),
                      hideCount: true,
                    ),
                    FolderRow(
                      style: style,
                      title: 'Notes with Checklists',
                      icon: CupertinoIcons.list_bullet_indent,
                      iconColor: AppColors.yellow,
                      count: 0,
                      onTap: () => controller.searchByFilter('checklists'),
                      hideCount: true,
                    ),
                    FolderRow(
                      style: style,
                      title: 'Notes with Tags',
                      icon: CupertinoIcons.number,
                      iconColor: AppColors.yellow,
                      count: 0,
                      onTap: () => controller.searchByFilter('tags'),
                      hideCount: true,
                    ),
                    FolderRow(
                      style: style,
                      title: 'Notes with Drawings',
                      icon: CupertinoIcons.pencil_circle,
                      iconColor: AppColors.yellow,
                      count: 0,
                      onTap: () => controller.searchByFilter('drawings'),
                      hideCount: true,
                    ),
                    FolderRow(
                      style: style,
                      title: 'Notes with Scanned Documents',
                      icon: CupertinoIcons.doc_text_viewfinder,
                      iconColor: AppColors.yellow,
                      count: 0,
                      onTap: () => controller.searchByFilter('scanned'),
                      hideCount: true,
                    ),
                    FolderRow(
                      style: style,
                      title: 'Notes with Attachments',
                      icon: CupertinoIcons.paperclip,
                      iconColor: AppColors.yellow,
                      count: 0,
                      onTap: () => controller.searchByFilter('attachments'),
                      hideCount: true,
                      isLast: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class SearchBottomBar extends StatefulWidget {
  final HomeStyle style;
  final HomeController controller;
  const SearchBottomBar({
    super.key,
    required this.style,
    required this.controller,
  });

  @override
  State<SearchBottomBar> createState() => _SearchBottomBarState();
}

class _SearchBottomBarState extends State<SearchBottomBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.searchQuery.value,
    );
  }

  @override
  void didUpdateWidget(covariant SearchBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.controller.searchQuery.value;
    if (query != _textController.text) {
      _textController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final controller = widget.controller;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: style.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppColors.magenta.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: style.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    color: style.secondaryText,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onChanged: controller.search,
                      autofocus: true,
                      cursorColor: AppColors.magenta,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(
                          color: AppColors.subtitle,
                          fontSize: 17,
                        ),
                      ),
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  Obx(
                    () => controller.searchQuery.value.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _textController.clear();
                              controller.search('');
                            },
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              color: AppColors.outline,
                              size: 18,
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Get.snackbar(
                                "Voice Search",
                                "Voice search is not available in this version.",
                              );
                            },
                            child: Icon(
                              CupertinoIcons.mic,
                              color: style.primaryText,
                              size: 20,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              _textController.clear();
              controller.cancelSearch();
            },
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: style.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: style.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.xmark,
                color: style.primaryText,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Reusable Components ---

class HeaderCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const HeaderCircleButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        constraints: const BoxConstraints(minWidth: 40),
        decoration: BoxDecoration(
          color: style.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: style.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class HeaderPillButton extends StatelessWidget {
  final List<Widget> children;
  const HeaderPillButton({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: style.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const ActionIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onPressed: onTap,
      minimumSize: Size.zero,
      child: Icon(icon, color: style.secondaryText, size: 22),
    );
  }
}

class FolderSection extends StatelessWidget {
  final HomeStyle style;
  final List<Widget> children;
  final EdgeInsets? padding;

  const FolderSection({
    super.key,
    required this.style,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: style.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding,
      child: Column(children: children),
    );
  }
}

class FolderRow extends StatelessWidget {
  final HomeStyle style;
  final String title;
  final IconData icon;
  final Color iconColor;
  final int count;
  final VoidCallback onTap;
  final bool isLast;
  final bool isEditing;
  final bool isSystem;
  final bool hideCount;

  const FolderRow({
    super.key,
    required this.style,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.onTap,
    this.isLast = false,
    this.isEditing = false,
    this.isSystem = false,
    this.hideCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool showActions = isEditing && !isSystem;
    final Color textColor = (isEditing && isSystem)
        ? style.secondaryText.withValues(alpha: 0.45)
        : style.primaryText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isEditing && isSystem) ? null : onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (!isEditing) ...[
                    if (!hideCount)
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 17,
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (!hideCount)
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                  ] else if (showActions) ...[
                    FolderActionIcon(
                      icon: CupertinoIcons.ellipsis_circle,
                      onTap: onTap,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 24,
                      color: style.border.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      CupertinoIcons.bars,
                      color: style.secondaryText,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: Divider(
                  height: 0.5,
                  color: style.border.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FolderActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const FolderActionIcon({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: AppColors.yellow, size: 22),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onToggle;
  final bool isExpanded;
  const SectionHeader({
    super.key,
    required this.title,
    required this.onToggle,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: style.primaryText,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: AppColors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class NotesGrid extends StatelessWidget {
  final List<Note> notes;
  final HomeStyle style;
  final HomeController controller;
  const NotesGrid({
    super.key,
    required this.notes,
    required this.style,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: controller.isGalleryView.value
          ? SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (c, i) => GalleryItem(
                  note: notes[i],
                  style: style,
                  onTap: () => controller.openNote(notes[i]),
                ),
                childCount: notes.length,
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (c, i) => NoteCard(
                  key: ValueKey('note-${notes[i].id}'),
                  note: NoteModel.fromEntity(notes[i]),
                  onTap: () => controller.openNote(notes[i]),
                  onDelete: () => controller.deleteNote(notes[i]),
                  onPin: () => controller.togglePin(notes[i]),
                  onShare: () => controller.shareNote(notes[i]),
                  onMove: () => controller.moveNote(notes[i]),
                  isLast: i == notes.length - 1,
                ),
                childCount: notes.length,
              ),
            ),
    );
  }
}

class GalleryItem extends StatelessWidget {
  final Note note;
  final HomeStyle style;
  final VoidCallback onTap;
  const GalleryItem({
    super.key,
    required this.note,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: style.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: style.border.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.imagePaths.isNotEmpty)
              Expanded(
                child: ImageHelper.buildSafeImage(
                  note.imagePaths.first,
                  width: double.infinity,
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Icon(
                    CupertinoIcons.doc_text,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              note.content,
              maxLines: 2,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeBottomBar extends StatelessWidget {
  final HomeStyle style;
  final int noteCount;
  final bool isFolderView;
  final VoidCallback onSearch;
  final VoidCallback onCreateNote;
  final VoidCallback onCreateFolder;
  final VoidCallback onOpenGoals;
  final VoidCallback onShowNotes;
  final VoidCallback onShowFolders;

  const HomeBottomBar({
    super.key,
    required this.style,
    required this.noteCount,
    required this.isFolderView,
    required this.onSearch,
    required this.onCreateNote,
    required this.onCreateFolder,
    required this.onOpenGoals,
    required this.onShowNotes,
    required this.onShowFolders,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: style.surface,
        border: Border(
          top: BorderSide(color: style.border.withValues(alpha: .55)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(10, 8, 10, bottomPadding + 8),
      child: Row(
        children: [
          _HomeNavItem(
            icon: CupertinoIcons.doc_text,
            label: 'Notes',
            selected: !isFolderView,
            onTap: onShowNotes,
          ),
          _HomeNavItem(
            icon: CupertinoIcons.folder,
            label: 'Folders',
            selected: isFolderView,
            onTap: onShowFolders,
          ),
          _HomeNavItem(
            icon: CupertinoIcons.search,
            label: 'Search',
            selected: false,
            onTap: onSearch,
          ),
          _HomeNavItem(
            icon: CupertinoIcons.scope,
            label: 'Goals',
            selected: false,
            onTap: onOpenGoals,
          ),
        ],
      ),
    );
  }
}

class _HomeNavItem extends StatelessWidget {
  const _HomeNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.subtitle;
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 30,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomSearchAnchor extends StatelessWidget {
  final VoidCallback onTap;
  final HomeStyle style;
  const BottomSearchAnchor({
    super.key,
    required this.onTap,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: style.surface,
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: style.shadow,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.search, color: style.secondaryText, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search',
                style: TextStyle(color: style.secondaryText, fontSize: 17),
              ),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Get.snackbar(
                  "Voice Note",
                  "Voice recording is not available in this version.",
                );
              },
              icon: Icon(
                CupertinoIcons.mic_fill,
                color: style.secondaryText,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomActionCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final HomeStyle style;
  const BottomActionCircle({
    super.key,
    required this.icon,
    required this.onTap,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          color: style.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: style.shadow,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: style.primaryText, size: 24),
      ),
    );
  }
}

class SearchNoteCard extends StatelessWidget {
  final Note note;
  final HomeController controller;
  final bool isLast;

  const SearchNoteCard({
    super.key,
    required this.note,
    required this.controller,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final folder = controller.folders.firstWhereOrNull(
      (f) => f.id == note.folderId,
    );

    return NoteCard(
      key: ValueKey('search-note-${note.id}'),
      note: NoteModel.fromEntity(note),
      onTap: () => controller.openNote(note),
      onDelete: () => controller.deleteNote(note),
      onPin: () => controller.togglePin(note),
      onShare: () => controller.shareNote(note),
      onMove: () => controller.moveNote(note),
      isLast: isLast,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('h:mm').format(note.updatedAt) +
                    (note.updatedAt.hour >= 12
                        ? ' in the afternoon'
                        : ' in the morning'),
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Text(
                folder?.name ?? 'Notes',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
          if (note.isDeleted)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.trash,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Recently Deleted',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
