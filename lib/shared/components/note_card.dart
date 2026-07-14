import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/core/utils/image_helper.dart';
import 'package:notes/core/utils/date_formatter.dart';
import 'package:notes/data/models/note_model.dart';

class NoteCardController extends GetxController with GetSingleTickerProviderStateMixin {
  static const double actionWidth = 72;
  
  late final AnimationController animationController;
  final bool hasShare;
  final bool hasMove;
  final bool hasPin;

  NoteCardController({required this.hasShare, required this.hasMove, required this.hasPin});

  int get actionCount {
    int count = 1; // Delete
    if (hasShare) count++;
    if (hasMove) count++;
    if (hasPin) count++;
    return count;
  }

  double get revealWidth => actionCount * actionWidth;
  bool get isOpened => animationController.value > 0.1;

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 240),
    );
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }

  void handleDragUpdate(DragUpdateDetails details) {
    final double horizontalDelta = details.primaryDelta ?? 0;
    final double newValue = animationController.value - (horizontalDelta / revealWidth);
    animationController.value = newValue.clamp(0.0, 1.0);
  }

  void handleDragEnd(DragEndDetails details) {
    final double velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity < -450) { openActions(); return; }
    if (velocity > 450) { closeActions(); return; }
    if (animationController.value >= 0.42) { openActions(); } else { closeActions(); }
  }

  void openActions() {
    HapticFeedback.selectionClick();
    animationController.animateTo(1, curve: Curves.easeOutCubic);
  }

  void closeActions() { animationController.animateBack(0, curve: Curves.easeOutCubic); }

  void executeAction(VoidCallback callback) {
    HapticFeedback.lightImpact();
    closeActions();
    callback();
  }
}

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    this.onShare,
    this.onMove,
    this.onPin,
    this.isLast = false,
    this.subtitle,
  });

  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onMove;
  final VoidCallback? onPin;
  final bool isLast;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final tag = 'note-card-${note.id}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GetBuilder<NoteCardController>(
      init: NoteCardController(hasShare: onShare != null, hasMove: onMove != null, hasPin: onPin != null),
      tag: tag,
      dispose: (state) => Get.delete<NoteCardController>(tag: tag),
      builder: (controller) {
        final actions = [
          if (onPin != null) 
            _SwipeAction(
              width: 72, 
              icon: note.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin, 
              label: 'Pin', 
              color: const Color(0xFFFF9F0A), 
              onPressed: () => controller.executeAction(onPin!)
            ),
          if (onShare != null) 
            _SwipeAction(
              width: 72, 
              icon: CupertinoIcons.share, 
              label: 'Share', 
              color: const Color(0xFF007AFF), 
              onPressed: () => controller.executeAction(onShare!)
            ),
          if (onMove != null) 
            _SwipeAction(
              width: 72, 
              icon: CupertinoIcons.folder, 
              label: 'Move', 
              color: const Color(0xFF5856D6), 
              onPressed: () => controller.executeAction(onMove!)
            ),
          _SwipeAction(
            width: 72, 
            icon: CupertinoIcons.trash, 
            label: 'Delete', 
            color: const Color(0xFFFF3B30), 
            onPressed: () => controller.executeAction(onDelete)
          ),
        ];

        return Container(
          margin: const EdgeInsets.only(bottom: 0.5),
          child: ClipRRect(
            child: GestureDetector(
              onHorizontalDragUpdate: controller.handleDragUpdate,
              onHorizontalDragEnd: controller.handleDragEnd,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                      alignment: Alignment.centerRight,
                      child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: controller.animationController,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(-controller.animationController.value * controller.revealWidth, 0),
                      child: child,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      ),
                      child: InkWell(
                        onTap: () => controller.isOpened ? controller.closeActions() : onTap(),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          note.title.isEmpty ? 'Untitled' : note.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        subtitle ?? Row(
                                          children: [
                                            Text(
                                              DateFormatter.format(note.updatedAt),
                                              style: const TextStyle(fontSize: 15, color: Colors.grey),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                note.content.isEmpty ? 'No additional text' : note.content,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 15, color: Colors.grey),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (note.imagePaths.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    ImageHelper.buildSafeImage(note.imagePaths.first, width: 44, height: 44, radius: 6),
                                  ],
                                  const SizedBox(width: 4),
                                  const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Divider(height: 0.5, color: Colors.black.withValues(alpha: 0.05)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.width,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final double width;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      color: color,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
