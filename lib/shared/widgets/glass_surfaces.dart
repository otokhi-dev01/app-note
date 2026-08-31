import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// The app-bar surface used by Create Note and, by default, every screen-level
/// app bar in the app.
const kCreateNoteAppBarShadow = <BoxShadow>[
  BoxShadow(color: Color(0x09000000), blurRadius: 18, offset: Offset(0, 6)),
];

class CustomGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color backgroundColor;
  final double toolbarHeight;
  final EdgeInsetsGeometry padding;
  final PreferredSizeWidget? bottom;
  final lg.GlassLargeTitleController? largeTitleController;

  const CustomGlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor = Colors.transparent,
    this.toolbarHeight = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.bottom,
    this.largeTitleController,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return lg.GlassAppBar(
      title: title,
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      toolbarHeight: toolbarHeight,
      padding: padding,
      bottom: bottom,
      largeTitleController: largeTitleController,
    );
  }
}

class CustomGlassSliverAppBar extends StatelessWidget {
  final Widget? title;
  final Widget? largeTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color backgroundColor;
  final List<BoxShadow>? shadow;
  final double toolbarHeight;
  final double expandedHeight;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry largeTitlePadding;
  final AlignmentGeometry largeTitleAlignment;

  const CustomGlassSliverAppBar({
    super.key,
    this.title,
    this.largeTitle,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor = Colors.transparent,
    this.shadow,
    this.toolbarHeight = 44,
    this.expandedHeight = 140,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.largeTitlePadding = const EdgeInsets.fromLTRB(20, 0, 20, 12),
    this.largeTitleAlignment = Alignment.bottomLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CustomGlassSliverAppBarDelegate(
        topPadding: MediaQuery.paddingOf(context).top,
        title: title,
        largeTitle: largeTitle,
        leading: leading,
        actions: actions,
        centerTitle: centerTitle,
        backgroundColor: backgroundColor,
        shadow: shadow,
        toolbarHeight: toolbarHeight,
        expandedHeight: expandedHeight,
        padding: padding,
        largeTitlePadding: largeTitlePadding,
        largeTitleAlignment: largeTitleAlignment,
      ),
    );
  }
}

/// A compact screen app bar matching the Create Note editor exactly.
///
/// Route-specific controls stay injectable, while height, spacing, title
/// typography, surface color, and shadow remain consistent across the app.
class AppScreenSliverAppBar extends StatelessWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final List<BoxShadow>? shadow;

  const AppScreenSliverAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomGlassSliverAppBar(
      toolbarHeight: 52,
      expandedHeight: 52,
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      shadow: shadow ?? kCreateNoteAppBarShadow,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      centerTitle: centerTitle,
      title: title == null
          ? null
          : Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
      leading: leading,
      actions: actions,
    );
  }
}

class _CustomGlassSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final Widget? title;
  final Widget? largeTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color backgroundColor;
  final List<BoxShadow>? shadow;
  final double toolbarHeight;
  final double expandedHeight;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry largeTitlePadding;
  final AlignmentGeometry largeTitleAlignment;

  const _CustomGlassSliverAppBarDelegate({
    required this.topPadding,
    required this.title,
    required this.largeTitle,
    required this.leading,
    required this.actions,
    required this.centerTitle,
    required this.backgroundColor,
    required this.shadow,
    required this.toolbarHeight,
    required this.expandedHeight,
    required this.padding,
    required this.largeTitlePadding,
    required this.largeTitleAlignment,
  });

  @override
  double get minExtent => topPadding + toolbarHeight;

  @override
  double get maxExtent => math.max(topPadding + expandedHeight, minExtent);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapseRange = maxExtent - minExtent;
    final expandedAmount = collapseRange == 0
        ? 0.0
        : (1 - shrinkOffset / collapseRange).clamp(0.0, 1.0);
    final compactOpacity = Curves.easeOut.transform(1 - expandedAmount);

    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: shadow ?? const []),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: CustomGlassAppBar(
                title: title == null
                    ? null
                    : Opacity(opacity: compactOpacity, child: title),
                leading: leading,
                actions: actions,
                centerTitle: centerTitle,
                backgroundColor: backgroundColor,
                toolbarHeight: toolbarHeight,
                padding: padding,
              ),
            ),
            if (largeTitle != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: largeTitlePadding,
                    child: Align(
                      alignment: largeTitleAlignment,
                      child: Opacity(
                        opacity: Curves.easeIn.transform(expandedAmount),
                        child: largeTitle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CustomGlassSliverAppBarDelegate oldDelegate) {
    return topPadding != oldDelegate.topPadding ||
        title != oldDelegate.title ||
        largeTitle != oldDelegate.largeTitle ||
        leading != oldDelegate.leading ||
        actions != oldDelegate.actions ||
        centerTitle != oldDelegate.centerTitle ||
        backgroundColor != oldDelegate.backgroundColor ||
        shadow != oldDelegate.shadow ||
        toolbarHeight != oldDelegate.toolbarHeight ||
        expandedHeight != oldDelegate.expandedHeight ||
        padding != oldDelegate.padding ||
        largeTitlePadding != oldDelegate.largeTitlePadding ||
        largeTitleAlignment != oldDelegate.largeTitleAlignment;
  }
}

class CustomGlassTab {
  final Widget? icon;
  final Widget? activeIcon;
  final String? label;
  final String? semanticLabel;

  const CustomGlassTab({
    this.icon,
    this.activeIcon,
    this.label,
    this.semanticLabel,
  });

  lg.GlassTab toPackage() => lg.GlassTab(
    icon: icon,
    activeIcon: activeIcon,
    label: label,
    semanticLabel: semanticLabel,
  );
}

class CustomGlassTabBarExtraButton {
  final Widget icon;
  final VoidCallback onTap;
  final String label;
  final Color? iconColor;
  final double size;

  const CustomGlassTabBarExtraButton({
    required this.icon,
    required this.onTap,
    required this.label,
    this.iconColor,
    this.size = 64,
  });

  lg.GlassTabBarExtraButton toPackage() => lg.GlassTabBarExtraButton(
    icon: icon,
    onTap: onTap,
    label: label,
    iconColor: iconColor,
    size: size,
  );
}

class CustomGlassSearchConfig {
  final ValueChanged<bool> onSearchToggle;
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onMicTap;
  final VoidCallback? onCancelTap;
  final bool autoFocusOnExpand;
  final bool showsCancelButton;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final Color? searchIconColor;
  final Color? textColor;
  final Color? cursorColor;

  const CustomGlassSearchConfig({
    required this.onSearchToggle,
    this.hintText = 'Search',
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onMicTap,
    this.onCancelTap,
    this.autoFocusOnExpand = false,
    this.showsCancelButton = true,
    this.textInputAction,
    this.keyboardType,
    this.searchIconColor,
    this.textColor,
    this.cursorColor,
  });

  lg.GlassSearchBarConfig toPackage() => lg.GlassSearchBarConfig(
    onSearchToggle: onSearchToggle,
    hintText: hintText,
    controller: controller,
    focusNode: focusNode,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    onMicTap: onMicTap,
    onCancelTap: onCancelTap,
    autoFocusOnExpand: autoFocusOnExpand,
    showsCancelButton: showsCancelButton,
    textInputAction: textInputAction,
    keyboardType: keyboardType,
    searchIconColor: searchIconColor,
    textColor: textColor,
    cursorColor: cursorColor,
  );
}

class CustomGlassTabBar extends StatelessWidget implements PreferredSizeWidget {
  final lg.GlassTabBar _tabBar;

  CustomGlassTabBar.bottom({
    super.key,
    required List<CustomGlassTab> tabs,
    required int selectedIndex,
    required ValueChanged<int> onTabSelected,
    CustomGlassTabBarExtraButton? extraButton,
    double horizontalPadding = 20,
    double verticalPadding = 20,
    double barHeight = 64,
    Color? selectedIconColor,
    Color? unselectedIconColor,
    bool adaptiveBrightness = false,
  }) : _tabBar = lg.GlassTabBar.bottom(
         tabs: tabs.map((tab) => tab.toPackage()).toList(growable: false),
         selectedIndex: selectedIndex,
         onTabSelected: onTabSelected,
         extraButton: extraButton?.toPackage(),
         horizontalPadding: horizontalPadding,
         verticalPadding: verticalPadding,
         barHeight: barHeight,
         selectedIconColor: selectedIconColor,
         unselectedIconColor: unselectedIconColor,
         adaptiveBrightness: adaptiveBrightness,
       );

  CustomGlassTabBar.inline({
    super.key,
    required List<CustomGlassTab> tabs,
    required int selectedIndex,
    required ValueChanged<int> onTabSelected,
    double barHeight = 40,
    double borderRadius = 100,
    Color? selectedIconColor,
    Color? unselectedIconColor,
    bool adaptiveBrightness = false,
  }) : _tabBar = lg.GlassTabBar.inline(
         tabs: tabs.map((tab) => tab.toPackage()).toList(growable: false),
         selectedIndex: selectedIndex,
         onTabSelected: onTabSelected,
         barHeight: barHeight,
         barBorderRadius: borderRadius,
         selectedIconColor: selectedIconColor,
         unselectedIconColor: unselectedIconColor,
         adaptiveBrightness: adaptiveBrightness,
       );

  CustomGlassTabBar.searchable({
    super.key,
    required List<CustomGlassTab> tabs,
    required int selectedIndex,
    required ValueChanged<int> onTabSelected,
    required CustomGlassSearchConfig searchConfig,
    required bool isSearchActive,
    CustomGlassTabBarExtraButton? extraButton,
    double horizontalPadding = 20,
    double verticalPadding = 20,
    double barHeight = 64,
    double searchBarHeight = 50,
    bool adaptiveBrightness = false,
  }) : _tabBar = lg.GlassTabBar.searchable(
         tabs: tabs.map((tab) => tab.toPackage()).toList(growable: false),
         selectedIndex: selectedIndex,
         onTabSelected: onTabSelected,
         searchConfig: searchConfig.toPackage(),
         isSearchActive: isSearchActive,
         extraButton: extraButton?.toPackage(),
         horizontalPadding: horizontalPadding,
         verticalPadding: verticalPadding,
         barHeight: barHeight,
         searchBarHeight: searchBarHeight,
         adaptiveBrightness: adaptiveBrightness,
       );

  @override
  Size get preferredSize => _tabBar.preferredSize;

  @override
  Widget build(BuildContext context) => _tabBar;
}

class CustomGlassDialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool closeOnPressed;

  const CustomGlassDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.closeOnPressed = true,
  });
}

class CustomGlassDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? content;
  final List<CustomGlassDialogAction> actions;
  final double maxWidth;
  final lg.GlassQuality quality;

  const CustomGlassDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    required this.actions,
    this.maxWidth = 280,
    this.quality = lg.GlassQuality.standard,
  }) : assert(actions.length > 0 && actions.length <= 3);

  static Future<T?> show<T>({
    required BuildContext context,
    required List<CustomGlassDialogAction> actions,
    String? title,
    String? message,
    Widget? content,
    bool barrierDismissible = false,
    Color barrierColor = const Color(0x8A000000),
    double maxWidth = 280,
    bool useRootNavigator = true,
  }) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useRootNavigator: useRootNavigator,
      builder: (_) => CustomGlassDialog(
        title: title,
        message: message,
        content: content,
        actions: actions,
        maxWidth: maxWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: lg.GlassDialog(
        title: title,
        message: message,
        content: content,
        maxWidth: maxWidth,
        quality: quality,
        actions: actions
            .map(
              (action) => lg.GlassDialogAction(
                label: action.label,
                isPrimary: action.isPrimary,
                isDestructive: action.isDestructive,
                onPressed: () {
                  if (action.closeOnPressed) Navigator.of(context).pop();
                  action.onPressed();
                },
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class CustomGlassSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showDragIndicator;
  final Color? dragIndicatorColor;
  final double topBorderRadius;
  final double? bottomBorderRadius;
  final EdgeInsetsGeometry margin;
  final bool isScrollable;
  final lg.GlassQuality quality;

  const CustomGlassSheet({
    super.key,
    required this.child,
    this.padding,
    this.showDragIndicator = true,
    this.dragIndicatorColor,
    this.topBorderRadius = 32,
    this.bottomBorderRadius,
    this.margin = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    this.isScrollable = true,
    this.quality = lg.GlassQuality.standard,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool showDragIndicator = true,
    Color? dragIndicatorColor,
    EdgeInsetsGeometry? padding,
    double topBorderRadius = 32,
    double? bottomBorderRadius,
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    bool isScrollable = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? barrierColor,
    bool useRootNavigator = false,
    bool useSafeArea = true,
  }) {
    return lg.GlassSheet.show<T>(
      context: context,
      builder: (context) =>
          Material(color: Colors.transparent, child: builder(context)),
      quality: lg.GlassQuality.standard,
      showDragIndicator: showDragIndicator,
      dragIndicatorColor: dragIndicatorColor,
      padding: padding,
      topBorderRadius: topBorderRadius,
      bottomBorderRadius: bottomBorderRadius,
      margin: margin,
      isScrollable: isScrollable,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      barrierColor: barrierColor,
      useRootNavigator: useRootNavigator,
      useSafeArea: useSafeArea,
    );
  }

  @override
  Widget build(BuildContext context) {
    return lg.GlassSheet(
      padding: padding,
      showDragIndicator: showDragIndicator,
      dragIndicatorColor: dragIndicatorColor,
      topBorderRadius: topBorderRadius,
      bottomBorderRadius: bottomBorderRadius,
      margin: margin,
      isScrollable: isScrollable,
      quality: quality,
      child: child,
    );
  }
}

class CustomGlassActionSheetAction {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isDestructive;
  final bool isCancel;

  const CustomGlassActionSheetAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
    this.isCancel = false,
  });

  lg.GlassActionSheetAction toPackage() => lg.GlassActionSheetAction(
    label: label,
    onPressed: onPressed,
    icon: icon != null
        ? Material(color: Colors.transparent, child: Icon(icon))
        : null,
    style: isDestructive
        ? lg.GlassActionSheetStyle.destructive
        : (isCancel
              ? lg.GlassActionSheetStyle.cancel
              : lg.GlassActionSheetStyle.defaultStyle),
  );
}

class CustomGlassActionSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? message,
    required List<CustomGlassActionSheetAction> actions,
    String cancelLabel = 'Cancel',
    bool showCancelButton = true,
    lg.GlassQuality quality = lg.GlassQuality.standard,
  }) {
    return lg.showGlassActionSheet<T>(
      context: context,
      title: title,
      message: message,
      actions: actions.map((a) => a.toPackage()).toList(),
      cancelLabel: cancelLabel,
      showCancelButton: showCancelButton,
      quality: quality,
    );
  }
}
