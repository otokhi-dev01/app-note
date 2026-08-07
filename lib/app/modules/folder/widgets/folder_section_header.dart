import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';

class FolderSectionHeader extends StatelessWidget {
  final String title;
  final RxBool isExpanded;
  final VoidCallback onTap;

  const FolderSectionHeader({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            Obx(() => Icon(
                  isExpanded.value ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: AppTheme.folderYellow,
                  size: 28,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }
}
