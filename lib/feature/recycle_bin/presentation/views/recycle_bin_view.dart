import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/widgets/app_refresh_button.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../../notes/domain/entities/note_entity.dart';
import '../controllers/recycle_bin_controller.dart';
import '../widgets/archived_note_row_widget.dart';
import '../widgets/deleted_folder_row_widget.dart';
import '../widgets/empty_recycle_bin_state_widget.dart';
import '../widgets/recycle_bin_error_state_widget.dart';
import '../widgets/recycle_bin_footer_widget.dart';
import '../widgets/recycle_bin_grouped_divider_widget.dart';
import '../widgets/recycle_bin_grouped_section_widget.dart';
import '../widgets/recycle_bin_loading_state_widget.dart';
import '../widgets/recycle_bin_section_header_widget.dart';
import '../widgets/recycle_bin_summary_widget.dart';

class RecycleBinView extends GetView<RecycleBinController> {
  const RecycleBinView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color pageColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: pageColor,
      body: Obx(() {
        final List<FolderEntity> deletedFolders =
            List<FolderEntity>.unmodifiable(controller.deletedFolders);
        final List<NoteEntity> archivedNotes = List<NoteEntity>.unmodifiable(
          controller.archivedNotes,
        );
        final bool isEmpty = deletedFolders.isEmpty && archivedNotes.isEmpty;
        final bool isInitialLoading = controller.isRefreshing.value && isEmpty;
        final String errorMessage = controller.errorMessage.value.trim();

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: <Widget>[
            CupertinoSliverNavigationBar(
              stretch: true,
              previousPageTitle: 'Back',
              backgroundColor: pageColor.withValues(alpha: 0.96),
              border: Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.35),
                  width: 0.5,
                ),
              ),
              largeTitle: Text(
                'Recycle Bin',
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              trailing: AppRefreshButton(
                semanticsLabel: 'Refresh recycle bin',
                isLoading: controller.isRefreshing.value,
                enableHaptics: true,
                onPressed: controller.refreshData,
              ),
            ),
            CupertinoSliverRefreshControl(onRefresh: controller.refreshData),
            if (isInitialLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: RecycleBinLoadingStateWidget(),
              )
            else if (errorMessage.isNotEmpty && isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: RecycleBinErrorStateWidget(
                  message: errorMessage,
                  onRetry: controller.refreshData,
                ),
              )
            else if (isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyRecycleBinStateWidget(
                  onRefresh: controller.refreshData,
                ),
              )
            else ...<Widget>[
              SliverToBoxAdapter(
                child: RecycleBinSummaryWidget(
                  folderCount: deletedFolders.length,
                  noteCount: archivedNotes.length,
                ),
              ),
              if (deletedFolders.isNotEmpty) ...<Widget>[
                SliverToBoxAdapter(
                  child: RecycleBinSectionHeaderWidget(
                    title: 'Deleted Folders',
                    count: deletedFolders.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RecycleBinGroupedSectionWidget(
                      children: <Widget>[
                        for (
                          int index = 0;
                          index < deletedFolders.length;
                          index++
                        ) ...<Widget>[
                          DeletedFolderRowWidget(
                            folder: deletedFolders[index],
                            onRestore: () {
                              _confirmRestoreFolder(
                                context,
                                deletedFolders[index],
                              );
                            },
                          ),
                          if (index < deletedFolders.length - 1)
                            const RecycleBinGroupedDividerWidget(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (archivedNotes.isNotEmpty) ...<Widget>[
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: RecycleBinSectionHeaderWidget(
                    title: 'Archived Notes',
                    count: archivedNotes.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RecycleBinGroupedSectionWidget(
                      children: <Widget>[
                        for (
                          int index = 0;
                          index < archivedNotes.length;
                          index++
                        ) ...<Widget>[
                          ArchivedNoteRowWidget(
                            note: archivedNotes[index],
                            onRestore: () {
                              HapticFeedback.selectionClick();
                              controller.restoreNote(archivedNotes[index]);
                            },
                          ),
                          if (index < archivedNotes.length - 1)
                            const RecycleBinGroupedDividerWidget(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: RecycleBinFooterWidget(
                  folderCount: deletedFolders.length,
                  noteCount: archivedNotes.length,
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      }),
    );
  }

  Future<void> _confirmRestoreFolder(
    BuildContext context,
    FolderEntity folder,
  ) async {
    HapticFeedback.mediumImpact();

    final String folderName = folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : folder.name.trim();
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Restore Folder?'),
          content: Text('Restore “$folderName” and make it available again?'),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.restoreFolder(folder);
  }
}
