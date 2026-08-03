import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';

class IOSConfirmationDialog extends StatelessWidget {
  final String title;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const IOSConfirmationDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    this.isDestructive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: isDark 
                  ? const Color(0xFF252525).withValues(alpha: 0.85) 
                  : Colors.white.withValues(alpha: 0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.3,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  Divider(
                    height: 1, 
                    thickness: 0.5, 
                    color: isDark ? const Color(0xFF38383A) : AppTheme.dividerColor,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 0.5, 
                        height: 50, 
                        color: isDark ? const Color(0xFF38383A) : AppTheme.dividerColor,
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            onConfirm();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(
                            confirmLabel,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: isDestructive ? Colors.redAccent : AppTheme.folderYellow,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
