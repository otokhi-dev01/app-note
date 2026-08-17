import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class IOSMenuAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? subtitle;
  final bool isDestructive;

  IOSMenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.subtitle,
    this.isDestructive = false,
  });
}

enum IOSMenuType { popup, bottomSheet }

class IOSActionMenu extends StatelessWidget {
  final List<IOSMenuAction> actions;
  final IOSMenuType type;
  final String? title;
  final bool showCancel;
  final Alignment? alignment;

  const IOSActionMenu({
    super.key,
    required this.actions,
    this.type = IOSMenuType.popup,
    this.title,
    this.showCancel = true,
    this.alignment,
  });

  static Future<void> show({
    required BuildContext context,
    required List<IOSMenuAction> actions,
    IOSMenuType type = IOSMenuType.popup,
    String? title,
    String? message,
  }) {
    if (type == IOSMenuType.bottomSheet) {
      return Get.bottomSheet(
        IOSActionMenu(actions: actions, type: type, title: title),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }

    return Get.dialog(
      IOSActionMenu(actions: actions, type: type, title: title),
      barrierColor: Colors.black.withValues(alpha: 0.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (type == IOSMenuType.bottomSheet) {
      return _buildBottomSheet(context);
    }
    return _buildPopup(context);
  }

  Widget _buildPopup(BuildContext context) {
    final _ = Theme.of(context);
    final effectiveAlignment = alignment ?? Alignment.topRight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Get.back(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 60, 20, 0),
          child: Align(
            alignment: effectiveAlignment,
            child: GestureDetector(
              onTap: () {}, // Prevent taps on the menu itself from closing it
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: _MenuContainer(
                  children: [
                    if (title != null) ...[
                      _buildHeader(context, title!),
                      _buildDivider(context),
                    ],
                    for (int i = 0; i < actions.length; i++) ...[
                      _buildMenuItem(context, actions[i]),
                      if (i < actions.length - 1) _buildDivider(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomGlassContainer(
                borderRadius: 24,
                opacity: 0.15,
                blur: 35,
                thickness: 8,
                showGlow: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) ...[
                      _buildHeader(context, title!),
                      _buildDivider(context),
                    ],
                    for (int i = 0; i < actions.length; i++) ...[
                      _buildMenuItem(context, actions[i]),
                      if (i < actions.length - 1) _buildDivider(context),
                    ],
                  ],
                ),
              ),
              if (showCancel) ...[
                const SizedBox(height: 12),
                CustomGlassButton(
                  onPressed: () => Get.back(),
                  width: double.infinity,
                  height: 56,
                  borderRadius: 24,
                  opacity: 0.15,
                  blur: 35,
                  thickness: 8,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IOSMenuAction action) {
    final theme = Theme.of(context);
    final color = action.isDestructive
        ? CupertinoColors.destructiveRed
        : (action.color ?? theme.colorScheme.onSurface);

    return InkWell(
      onTap: () {
        Get.back();
        action.onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: color, size: 22),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                action.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      indent: 56,
      height: 1,
      thickness: 0.5,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
    );
  }
}

class _MenuContainer extends StatelessWidget {
  final List<Widget> children;
  const _MenuContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return CustomGlassContainer(
      borderRadius: 30,
      opacity: 0.1,
      blur: 35,
      thickness: 8,
      showGlow: true,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
