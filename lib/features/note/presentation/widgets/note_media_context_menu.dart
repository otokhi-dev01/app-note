import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoteMediaMenuAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? trailing;
  final bool isDestructive;
  final bool enabled;

  const NoteMediaMenuAction({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.isDestructive = false,
    this.enabled = true,
  });
}

class NoteMediaContextMenu {
  NoteMediaContextMenu._();

  static Future<void> show({
    required BuildContext context,
    required Widget preview,
    required List<NoteMediaMenuAction> actions,
    double previewHeight = 320,
  }) {
    Feedback.forLongPress(context);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) => _MediaContextMenuOverlay(
        preview: preview,
        actions: actions,
        previewHeight: previewHeight,
      ),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _MediaContextMenuOverlay extends StatelessWidget {
  final Widget preview;
  final List<NoteMediaMenuAction> actions;
  final double previewHeight;

  const _MediaContextMenuOverlay({
    required this.preview,
    required this.actions,
    required this.previewHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableHeight = MediaQuery.sizeOf(context).height;
    final resolvedPreviewHeight = previewHeight.clamp(
      140.0,
      (availableHeight * 0.52).clamp(180.0, 520.0),
    );

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.72),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: double.infinity,
                          height: resolvedPreviewHeight,
                          constraints: const BoxConstraints(maxWidth: 560),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: preview,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {},
                        child: _MediaActionCard(actions: actions),
                      ),
                    ],
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

class _MediaActionCard extends StatelessWidget {
  final List<NoteMediaMenuAction> actions;

  const _MediaActionCard({required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    for (var index = 0; index < actions.length; index++) {
      if (index > 0) {
        children.add(
          Divider(
            height: 1,
            indent: 54,
            color: theme.dividerColor.withValues(alpha: 0.32),
          ),
        );
      }
      children.add(_MediaActionRow(action: actions[index]));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          key: const ValueKey('note-media-context-menu'),
          width: 344,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _MediaActionRow extends StatelessWidget {
  final NoteMediaMenuAction action;

  const _MediaActionRow({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledColor = action.isDestructive
        ? CupertinoColors.destructiveRed
        : theme.colorScheme.onSurface;
    final color = action.enabled
        ? enabledColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.32);

    return Semantics(
      button: true,
      enabled: action.enabled,
      child: InkWell(
        onTap: action.enabled
            ? () {
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => action.onTap(),
                );
              }
            : null,
        child: SizedBox(
          height: action.subtitle == null ? 56 : 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Icon(action.icon, size: 23, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (action.subtitle != null)
                        Text(
                          action.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (action.trailing != null)
                  IconTheme(
                    data: IconThemeData(color: color),
                    child: action.trailing!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
