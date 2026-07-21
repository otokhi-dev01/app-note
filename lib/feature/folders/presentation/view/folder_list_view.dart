import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:note_app/feature/main/presentation/widgets/app_liquid_background_widget.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../main/presentation/controller/main_navigation_controller.dart';
import '../../../main/presentation/widgets/main_tab_header_widget.dart';
import '../../../notes/presentation/controllers/home_controller.dart';
import '../../domain/entities/folder_entity.dart';

class FolderListView extends GetView<HomeController> {
  const FolderListView({super.key});

  @override
  Widget build(BuildContext context) {
    return _FolderListContent(controller: controller);
  }
}

class _FolderListContent extends StatefulWidget {
  final HomeController controller;

  const _FolderListContent({required this.controller});

  @override
  State<_FolderListContent> createState() {
    return _FolderListContentState();
  }
}

class _FolderListContentState extends State<_FolderListContent>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  late final Ticker _scrollTicker;
  double _lastTickElapsedSeconds = 0.0;
  double _scrollVelocityScale =
      0.0; // -1.0 (scrolling up) to 1.0 (scrolling down)

  bool _isAtTop = true;
  bool _isAtBottom = false;
  bool _canScroll = false;
  bool _scrollStateUpdateScheduled = false;

  HomeController get controller {
    return widget.controller;
  }

  @override
  void initState() {
    super.initState();

    _scrollTicker = createTicker(_onScrollTick);

    _scrollController.addListener(_updateScrollState);

    _scheduleScrollStateUpdate();
  }

  @override
  void dispose() {
    _stopContinuousScroll();
    _scrollTicker.dispose();

    _scrollController
      ..removeListener(_updateScrollState)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(child: AppLiquidBackgroundWidget()),

        SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              // Sticky header: outside the scroll view.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Obx(() {
                  final int folderCount = controller.folders.length;

                  final int noteCount = controller.folders.fold<int>(
                    0,
                    (int total, FolderEntity folder) {
                      return total + folder.noteCount;
                    },
                  );

                  final int deletedCount = controller.deletedFolders.length;

                  return MainTabHeader(
                    title: 'Folders',
                    subtitle:
                        '$folderCount active '
                        '${folderCount == 1 ? 'folder' : 'folders'}'
                        ' • $noteCount '
                        '${noteCount == 1 ? 'note' : 'notes'}',
                    trailing: MainTabHeaderAction(
                      tooltip: 'Recently Deleted',
                      icon: deletedCount > 0
                          ? CupertinoIcons.delete_solid
                          : CupertinoIcons.delete,
                      onPressed: _openRecentlyDeleted,
                    ),
                    onRefresh: controller.loadFolders,
                    onAdd: _openCreateFolder,
                    addIcon: CupertinoIcons.folder_badge_plus,
                  );
                }),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: Obx(() {
                  return _buildContent(context);
                }),
              ),
            ],
          ),
        ),

        Positioned(
          right: 14,
          bottom: 108,
          child: SafeArea(
            top: false,
            child: _ScrollEdgeControls(
              visible: _canScroll,
              isAtTop: _isAtTop,
              isAtBottom: _isAtBottom,
              onVelocityChanged: (double scale) {
                if (scale == 0.0) {
                  _stopContinuousScroll();
                } else {
                  _startContinuousScroll(velocityScale: scale);
                }
              },
              onTopTap: () {
                _scrollToEdge(goToBottom: false);
              },
              onBottomTap: () {
                _scrollToEdge(goToBottom: true);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final List<FolderEntity> folderSnapshot = List<FolderEntity>.unmodifiable(
      controller.folders.toList(),
    );

    final bool isLoading = controller.isFoldersLoading.value;

    final String errorMessage = controller.folderErrorMessage.value.trim();

    final int? selectedFolderId = controller.selectedFolderId.value;

    _scheduleScrollStateUpdate();

    if (isLoading && folderSnapshot.isEmpty) {
      return const _FolderLoadingState();
    }

    if (controller.hasFolderError && folderSnapshot.isEmpty) {
      return _FolderErrorState(
        message: errorMessage,
        onRetry: controller.loadFolders,
      );
    }

    final int totalNotes = controller.activeNotes.isNotEmpty
        ? controller.activeNotes.length
        : folderSnapshot.fold<int>(0, (int total, FolderEntity folder) {
            return total + folder.noteCount;
          });

    final ThemeData theme = Theme.of(context);

    final Color primaryColor = theme.colorScheme.primary;

    return RefreshIndicator.adaptive(
      onRefresh: controller.loadFolders,
      displacement: 24,
      child: CustomScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          const SliverToBoxAdapter(child: SizedBox(height: 4)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _AllNotesCard(
                noteCount: totalNotes,
                selected: selectedFolderId == null,
                color: primaryColor,
                onTap: () {
                  HapticFeedback.selectionClick();

                  controller.selectAllNotes();

                  _openNoteTab();
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          if (folderSnapshot.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyFolderState(
                onCreate: _openCreateFolder,
                onOpenDeleted: _openRecentlyDeleted,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList.builder(
                itemCount: folderSnapshot.length,
                itemBuilder: (BuildContext context, int index) {
                  if (index < 0 || index >= folderSnapshot.length) {
                    return const SizedBox.shrink();
                  }

                  final FolderEntity folder = folderSnapshot[index];

                  final Color folderColor = _parseFolderColor(
                    folder.colorValue,
                    primaryColor,
                  );

                  final bool selected = selectedFolderId == folder.id;

                  return Padding(
                    key: ValueKey<int>(folder.id),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FolderCard(
                      title: folder.name.trim().isEmpty
                          ? 'Unnamed Folder'
                          : folder.name.trim(),
                      subtitle: _folderSubtitle(
                        context,
                        folder,
                      ),
                      noteCount: folder.noteCount,
                      color: folderColor,
                      icon: _folderIcon(folder.iconName),
                      selected: selected,
                      onTap: () {
                        HapticFeedback.selectionClick();

                        controller.selectFolder(folder.id);

                        _openNoteTab();
                      },
                      onMore: () {
                        _showFolderActions(context, folder);
                      },
                    ),
                  );
                },
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }

  void _scheduleScrollStateUpdate() {
    if (_scrollStateUpdateScheduled) {
      return;
    }

    _scrollStateUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollStateUpdateScheduled = false;

      if (!mounted) {
        return;
      }

      _updateScrollState();
    });
  }

  void _updateScrollState() {
    if (!_scrollController.hasClients) {
      if (_canScroll || !_isAtTop || _isAtBottom) {
        setState(() {
          _canScroll = false;
          _isAtTop = true;
          _isAtBottom = false;
        });
      }

      return;
    }

    final ScrollPosition position = _scrollController.position;

    final bool canScroll =
        position.maxScrollExtent > position.minScrollExtent + 1;

    final bool atTop = position.pixels <= position.minScrollExtent + 3;

    final bool atBottom = position.pixels >= position.maxScrollExtent - 3;

    if (_canScroll == canScroll &&
        _isAtTop == atTop &&
        _isAtBottom == atBottom) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _canScroll = canScroll;
      _isAtTop = atTop;
      _isAtBottom = atBottom;
    });
  }

  Future<void> _scrollToEdge({required bool goToBottom}) async {
    _stopContinuousScroll();

    if (!_scrollController.hasClients) {
      return;
    }

    final ScrollPosition position = _scrollController.position;

    final double target = goToBottom
        ? position.maxScrollExtent
        : position.minScrollExtent;

    final double distance = (target - _scrollController.offset).abs();

    if (distance < 2) {
      return;
    }

    HapticFeedback.selectionClick();

    final int durationMilliseconds = (320 + (distance * 0.35))
        .clamp(320, 850)
        .round();

    await _scrollController.animateTo(
      target,
      duration: Duration(milliseconds: durationMilliseconds),
      curve: Curves.easeOutCubic,
    );
  }

  void _onScrollTick(Duration elapsed) {
    if (!_scrollController.hasClients || _scrollVelocityScale == 0.0) {
      _stopContinuousScroll();
      return;
    }

    final double elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
    if (_lastTickElapsedSeconds == 0.0) {
      _lastTickElapsedSeconds = elapsedSeconds;
      return;
    }

    final double dt = elapsedSeconds - _lastTickElapsedSeconds;
    _lastTickElapsedSeconds = elapsedSeconds;

    if (dt <= 0) return;

    final ScrollPosition position = _scrollController.position;

    // Fluid sliding velocity up to 2200 pixels/sec depending on joystick sliding depth
    final double maxVelocity = 2200.0;
    final double targetVelocity = _scrollVelocityScale * maxVelocity;

    final double nextOffset = (_scrollController.offset + (targetVelocity * dt))
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    _scrollController.jumpTo(nextOffset);

    final bool reachedEdge = _scrollVelocityScale > 0.0
        ? nextOffset >= position.maxScrollExtent
        : nextOffset <= position.minScrollExtent;

    if (reachedEdge) {
      // Do not kill the ticker immediately while dragging, allowing instant reversal
      _lastTickElapsedSeconds = elapsedSeconds;
    }
  }

  void _startContinuousScroll({required double velocityScale}) {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollVelocityScale = velocityScale;
    _lastTickElapsedSeconds = 0.0;

    if (!_scrollTicker.isActive) {
      _scrollTicker.start();
    }
  }

  void _stopContinuousScroll() {
    if (_scrollTicker.isActive) {
      _scrollTicker.stop();
    }
    _scrollVelocityScale = 0.0;
    _lastTickElapsedSeconds = 0.0;
  }

  Future<void> _openRecentlyDeleted() async {
    _stopContinuousScroll();

    await Get.toNamed(AppRoutes.recentlyDeletedFolders);

    await controller.loadFolders();

    _scheduleScrollStateUpdate();
  }

  Future<void> _openCreateFolder() async {
    _stopContinuousScroll();

    final dynamic result = await Get.toNamed(AppRoutes.createFolder);

    if (result == true) {
      await controller.loadFolders();

      _scheduleScrollStateUpdate();
    }
  }

  void _openNoteTab() {
    if (!Get.isRegistered<MainNavigationController>()) {
      return;
    }

    Get.find<MainNavigationController>().changeTab(1);
  }

  Future<void> _showFolderActions(
    BuildContext context,
    FolderEntity folder,
  ) async {
    HapticFeedback.mediumImpact();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        final String folderName = folder.name.trim().isEmpty
            ? 'Unnamed Folder'
            : folder.name.trim();

        return CupertinoActionSheet(
          title: Text(folderName),
          message: const Text('Choose an action for this folder.'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _showRenameDialog(context, folder);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(CupertinoIcons.pencil, size: 20),
                  SizedBox(width: 9),
                  Text('Rename Folder'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _confirmDelete(context, folder);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(CupertinoIcons.delete, size: 20),
                  SizedBox(width: 9),
                  Text('Move to Recently Deleted'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    FolderEntity folder,
  ) async {
    final TextEditingController textController = TextEditingController(
      text: folder.name,
    );

    final String? newName = await showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Rename Folder'),
          content: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: CupertinoTextField(
              controller: textController,
              autofocus: true,
              clearButtonMode: OverlayVisibilityMode.editing,
              placeholder: 'Folder name',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (String value) {
                final String name = value.trim();

                if (name.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(name);
              },
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final String name = textController.text.trim();

                if (name.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(name);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (newName == null || newName.trim().isEmpty) {
      return;
    }

    await controller.updateFolder(folder: folder, name: newName.trim());

    _scheduleScrollStateUpdate();
  }

  Future<void> _confirmDelete(BuildContext context, FolderEntity folder) async {
    final String folderName = folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : folder.name.trim();

    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Delete Folder?'),
          content: Text(
            '"$folderName" will be moved to '
            'Recently Deleted. You can restore '
            'it later.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.deleteOrRestoreFolder(folderId: folder.id, isDelete: true);

    _scheduleScrollStateUpdate();
  }
}

// =============================================================================
// REUSABLE LIQUID GLASS CONTAINER
// =============================================================================

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _GlassContainer({
    required this.child,
    required this.accentColor,
    required this.selected,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color baseBgColor = isDark
        ? const Color(0xFF15181E).withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.70);

    final Color activeBgColor = selected
        ? accentColor.withValues(alpha: isDark ? 0.12 : 0.08)
        : baseBgColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: selected
                ? accentColor.withValues(alpha: isDark ? 0.22 : 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: selected ? 28 : 20,
            spreadRadius: selected ? -4 : -8,
            offset: const Offset(0, 10),
          ),
          if (selected)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: -2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(26),
              splashColor: accentColor.withValues(alpha: 0.08),
              highlightColor: accentColor.withValues(alpha: 0.04),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: activeBgColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: selected
                        ? accentColor.withValues(alpha: 0.55)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.09)
                              : Colors.black.withValues(alpha: 0.07)),
                    width: selected ? 1.4 : 1.0,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ALL NOTES CARD
// =============================================================================

class _AllNotesCard extends StatelessWidget {
  final int noteCount;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _AllNotesCard({
    required this.noteCount,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colorScheme = theme.colorScheme;

    return _GlassContainer(
      accentColor: color,
      selected: selected,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          _FolderIconSurface(
            color: color,
            icon: CupertinoIcons.doc_text_fill,
            selected: selected,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'All Notes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$noteCount '
                  '${noteCount == 1 ? 'note' : 'notes'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          _CountBadge(count: noteCount, color: color),

          const SizedBox(width: 8),

          Icon(
            CupertinoIcons.chevron_forward,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FOLDER CARD
// =============================================================================

class _FolderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int noteCount;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _FolderCard({
    required this.title,
    required this.subtitle,
    required this.noteCount,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $subtitle',
      hint: 'Tap to open. Hold for folder actions.',
      child: _GlassContainer(
        accentColor: color,
        selected: selected,
        onTap: onTap,
        onLongPress: onMore,
        child: Row(
          children: <Widget>[
            _FolderIconSurface(color: color, icon: icon, selected: selected),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            _CountBadge(count: noteCount, color: color),

            const SizedBox(width: 2),

            CupertinoButton(
              padding: EdgeInsets.zero,
              pressedOpacity: 0.55,
              onPressed: onMore, minimumSize: Size(42, 42),
              child: Icon(
                CupertinoIcons.ellipsis,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderIconSurface extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool selected;

  const _FolderIconSurface({
    required this.color,
    required this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: selected ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: selected ? 0.30 : 0.14),
        ),
      ),
      child: Icon(icon, color: color, size: selected ? 29 : 27),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final String value = count > 999 ? '999+' : count.toString();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.13)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 34, minHeight: 28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Center(
            child: Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HOLD-TO-SCROLL CONTROLS (SMOOTH LIQUID JOYSTICK STRIP)
// =============================================================================

class _ScrollEdgeControls extends StatefulWidget {
  final bool visible;
  final bool isAtTop;
  final bool isAtBottom;
  final ValueChanged<double> onVelocityChanged;
  final VoidCallback onTopTap;
  final VoidCallback onBottomTap;

  const _ScrollEdgeControls({
    required this.visible,
    required this.isAtTop,
    required this.isAtBottom,
    required this.onVelocityChanged,
    required this.onTopTap,
    required this.onBottomTap,
  });

  @override
  State<_ScrollEdgeControls> createState() => _ScrollEdgeControlsState();
}

class _ScrollEdgeControlsState extends State<_ScrollEdgeControls> {
  double _bubbleAlignY = 0.0; // Alignment -1.0 (Top) to 1.0 (Bottom)
  bool _isDragging = false;

  final double _barHeight = 170.0;
  final double _barWidth = 52.0;

  void _handleDragUpdate(Offset localPosition) {
    final double centerY = _barHeight / 2;
    // Limit inner slider boundary so it doesn't leave the borders
    final double maxActiveTravel = (_barHeight / 2) - 30.0;

    final double relativeY = (localPosition.dy - centerY).clamp(
      -maxActiveTravel,
      maxActiveTravel,
    );
    final double velocityScale = relativeY / maxActiveTravel;

    setState(() {
      _bubbleAlignY = velocityScale;
      _isDragging = true;
    });

    widget.onVelocityChanged(velocityScale);
  }

  void _handleDragEnd() {
    setState(() {
      _bubbleAlignY = 0.0;
      _isDragging = false;
    });
    widget.onVelocityChanged(0.0);
  }

  void _handleTapUp(Offset localPosition) {
    // Top third of the bar acts as a fast-jump to top
    if (localPosition.dy < _barHeight * 0.33) {
      HapticFeedback.selectionClick();
      widget.onTopTap();
    }
    // Bottom third acts as a fast-jump to bottom
    else if (localPosition.dy > _barHeight * 0.66) {
      HapticFeedback.selectionClick();
      widget.onBottomTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = theme.colorScheme.primary;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: widget.visible ? Offset.zero : const Offset(1.4, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: widget.visible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !widget.visible,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: GestureDetector(
                onVerticalDragStart: (DragStartDetails details) {
                  _handleDragUpdate(details.localPosition);
                },
                onVerticalDragUpdate: (DragUpdateDetails details) {
                  _handleDragUpdate(details.localPosition);
                },
                onVerticalDragEnd: (DragEndDetails details) {
                  _handleDragEnd();
                },
                onVerticalDragCancel: () {
                  _handleDragEnd();
                },
                onTapUp: (TapUpDetails details) {
                  _handleTapUp(details.localPosition);
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1B1D22).withValues(alpha: 0.82)
                        : Colors.white.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.22 : 0.06,
                        ),
                        blurRadius: 20,
                        spreadRadius: -6,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: _barWidth,
                    height: _barHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        // The Liquid Floating Indicator
                        AnimatedAlign(
                          alignment: Alignment(0.0, _bubbleAlignY),
                          duration: Duration(
                            milliseconds: _isDragging ? 60 : 250,
                          ),
                          curve: _isDragging
                              ? Curves.linear
                              : Curves.elasticOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: _isDragging ? 42.0 : 38.0,
                            // Dynamic stretch depending on speed / drag state
                            height: _isDragging ? 54.0 : 38.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(19),
                              color: primaryColor.withValues(alpha: 0.16),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.40),
                                width: 1.2,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Arrows for visual guides
                        Positioned(
                          top: 14,
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 140),
                              opacity: widget.isAtTop ? 0.25 : 1.0,
                              child: Icon(
                                CupertinoIcons.chevron_up,
                                size: 18,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.black.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 14,
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 140),
                              opacity: widget.isAtBottom ? 0.25 : 1.0,
                              child: Icon(
                                CupertinoIcons.chevron_down,
                                size: 18,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.black.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// STATES
// =============================================================================

class _EmptyFolderState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onOpenDeleted;

  const _EmptyFolderState({
    required this.onCreate,
    required this.onOpenDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 40, 30, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.10),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                ),
              ),
              child: SizedBox(
                width: 92,
                height: 92,
                child: Icon(
                  CupertinoIcons.folder_badge_plus,
                  size: 42,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Folders Yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create folders to keep your '
              'notes organized.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(CupertinoIcons.add),
              label: const Text('Create Folder'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onOpenDeleted,
              icon: const Icon(CupertinoIcons.delete),
              label: const Text('Recently Deleted'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderLoadingState extends StatelessWidget {
  const _FolderLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CupertinoActivityIndicator(radius: 15));
  }
}

class _FolderErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _FolderErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colorScheme = theme.colorScheme;

    return RefreshIndicator.adaptive(
      onRefresh: onRetry,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Icon(
                    //   CupertinoIcons
                    //       .exclamation_icloud,
                    //   size: 56,
                    //   color:
                    //       colorScheme.error,
                    // ),
                    const SizedBox(height: 17),
                    Text(
                      'Folders Are Unavailable',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      message.isEmpty
                          ? 'Unable to load your folders.'
                          : message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        onRetry();
                      },
                      icon: const Icon(CupertinoIcons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HELPERS
// =============================================================================

IconData _folderIcon(String value) {
  switch (value.trim().toLowerCase()) {
    case 'work':
    case 'briefcase':
    case 'business':
      return Icons.work_rounded;

    case 'school':
    case 'education':
      return Icons.school_rounded;

    case 'personal':
    case 'person':
      return Icons.person_rounded;

    case 'favorite':
    case 'heart':
      return Icons.favorite_rounded;

    case 'travel':
    case 'flight':
      return Icons.flight_takeoff_rounded;

    case 'home':
      return Icons.home_rounded;

    case 'code':
      return Icons.code_rounded;

    case 'shopping':
      return Icons.shopping_bag_rounded;

    case 'photo':
    case 'photos':
      return Icons.photo_rounded;

    case 'music':
      return Icons.music_note_rounded;

    case 'idea':
      return Icons.lightbulb_rounded;

    default:
      return Icons.folder_rounded;
  }
}

String _folderSubtitle(
  BuildContext context,
  FolderEntity folder,
) {
  final int noteCount = folder.noteCount;
  final String notes =
      '$noteCount ${noteCount == 1 ? 'note' : 'notes'}';

  final DateTime? activityDate = folder.updatedAt ?? folder.createdAt;

  if (activityDate == null) {
    return notes;
  }

  final String formattedDate = MaterialLocalizations.of(
    context,
  ).formatShortDate(activityDate.toLocal());

  return '$notes • Updated $formattedDate';
}

Color _parseFolderColor(String rawValue, Color fallback) {
  final String value = rawValue.trim();

  if (value.isEmpty || value.toLowerCase() == 'string') {
    return fallback;
  }

  try {
    String hex = value
        .replaceAll('#', '')
        .replaceAll('0x', '')
        .replaceAll('0X', '');

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length != 8) {
      return fallback;
    }

    return Color(int.parse(hex, radix: 16));
  } catch (_) {
    return fallback;
  }
}
