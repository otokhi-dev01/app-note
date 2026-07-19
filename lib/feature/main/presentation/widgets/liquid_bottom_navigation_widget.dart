import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiquidBottomNavigation
    extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onCreateNote;

  const LiquidBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color backgroundColor = isDark
        ? const Color(0xFF1B1D22)
        .withValues(alpha: 0.90)
        : Colors.white.withValues(
      alpha: 0.88,
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        14,
        0,
        14,
        10,
      ),
      child: SizedBox(
        height: 86,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius:
                BorderRadius.circular(29),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 26,
                    sigmaY: 26,
                  ),
                  child: Container(
                    height: 70,
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius:
                      BorderRadius.circular(29),
                      border: Border.all(
                        color: colorScheme
                            .outlineVariant
                            .withValues(
                          alpha: isDark
                              ? 0.23
                              : 0.40,
                        ),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black
                              .withValues(
                            alpha: isDark
                                ? 0.30
                                : 0.10,
                          ),
                          blurRadius: 30,
                          offset:
                          const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _NavigationItem(
                            index: 0,
                            selectedIndex:
                            selectedIndex,
                            label: 'folders'.tr,
                            icon:
                            CupertinoIcons.folder,
                            selectedIcon:
                            CupertinoIcons
                                .folder_fill,
                            onChanged: onChanged,
                          ),
                        ),
                        Expanded(
                          child: _NavigationItem(
                            index: 1,
                            selectedIndex:
                            selectedIndex,
                            label: 'notes'.tr,
                            icon: CupertinoIcons
                                .doc_text,
                            selectedIcon:
                            CupertinoIcons
                                .doc_text_fill,
                            onChanged: onChanged,
                          ),
                        ),
                        const SizedBox(width: 74),
                        Expanded(
                          child: _NavigationItem(
                            index: 2,
                            selectedIndex:
                            selectedIndex,
                            label: 'settings'.tr,
                            icon:
                            CupertinoIcons.gear,
                            selectedIcon:
                            CupertinoIcons
                                .gear_solid,
                            onChanged: onChanged,
                          ),
                        ),
                        Expanded(
                          child: _NavigationItem(
                            index: 3,
                            selectedIndex:
                            selectedIndex,
                            label: 'profile'.tr,
                            icon:
                            CupertinoIcons.person,
                            selectedIcon:
                            CupertinoIcons
                                .person_fill,
                            onChanged: onChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: _CenterCreateButton(
                onPressed: onCreateNote,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterCreateButton
    extends StatelessWidget {
  final VoidCallback onPressed;

  const _CenterCreateButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primary,
          border: Border.all(
            color:
            theme.scaffoldBackgroundColor,
            width: 6,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.primary
                  .withValues(alpha: 0.38),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.13,
              ),
              blurRadius: 15,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(
          CupertinoIcons.add,
          size: 31,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final ValueChanged<int> onChanged;

  const _NavigationItem({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool selected =
        index == selectedIndex;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        onChanged(index);
      },
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 210),
        curve: Curves.easeOutCubic,
        height: 57,
        margin: const EdgeInsets.symmetric(
          horizontal: 1,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              .withValues(alpha: 0.13)
              : Colors.transparent,
          borderRadius:
          BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              selected
                  ? selectedIcon
                  : icon,
              size: selected ? 22 : 21,
              color: selected
                  ? colorScheme.primary
                  : colorScheme
                  .onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: theme
                  .textTheme.labelSmall
                  ?.copyWith(
                fontSize: 10,
                color: selected
                    ? colorScheme.primary
                    : colorScheme
                    .onSurfaceVariant,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}