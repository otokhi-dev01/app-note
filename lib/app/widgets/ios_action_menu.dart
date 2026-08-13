import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glass_widgets.dart';

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
            child:
                GestureDetector(
                      onTap:
                          () {}, // Prevent taps on the menu itself from closing it
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: _MenuContainer(
                          children: [
                            if (title != null) ...[
                              _buildHeader(context, title!),
                              _buildDivider(context),
                            ],
                            for (int i = 0; i < actions.length; i++) ...[
                              _buildMenuItem(context, actions[i]),
                              if (i < actions.length - 1)
                                _buildDivider(context),
                            ],
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .scale(
                      duration: 200.ms,
                      curve: Curves.easeOutBack,
                      alignment: effectiveAlignment,
                    )
                    .fadeIn(duration: 150.ms),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onTap: () => Get.back(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _MenuContainer(
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
                  if (showCancel) ...[
                    const SizedBox(height: 8),
                    _MenuContainer(
                      children: [
                        ListTile(
                          onTap: () => Get.back(),
                          title: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
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

    return ListTile(
      onTap: () {
        Get.back();
        action.onTap();
      },
      dense: type == IOSMenuType.popup,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(action.icon, color: color, size: 24),
      title: Text(
        action.label,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
      ),
      subtitle: action.subtitle != null
          ? Text(
              action.subtitle!,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            )
          : null,
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
    return LiquidGlassContainer(
      borderRadius: 14,
      opacity: 0.1,
      blur: 35,
      thickness: 8,
      showGlow: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
