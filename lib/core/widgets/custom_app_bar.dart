import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'liquid_glass_container.dart';
import '../../app/theme/colors.dart';

class CustomGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final double height;
  final bool showBackButton;

  const CustomGlassAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.height = kToolbarHeight + 10,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      toolbarHeight: height,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: leading ?? (showBackButton ? IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded, 
          color: isDark ? Colors.white : AppColors.primary,
          size: 20,
        ),
        onPressed: () => Get.back(),
      ) : null),
      title: title ?? (titleText != null ? Text(
        titleText!,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ) : null),
      actions: actions,
      flexibleSpace: LiquidGlassContainer(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        opacity: isDark ? 0.3 : 0.6,
        blur: 20,
        child: Container(color: Colors.transparent),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class CustomGlassSliverAppBar extends StatelessWidget {
  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final bool pinned;
  final bool stretch;
  final BorderRadius? borderRadius;
  final bool centerTitle;

  const CustomGlassSliverAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.expandedHeight = 140.0,
    this.flexibleSpace,
    this.pinned = true,
    this.stretch = true,
    this.borderRadius,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: pinned,
      stretch: stretch,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: leading ?? (showBackButton ? IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded, 
          color: isDark ? Colors.white : AppColors.primary,
          size: 20,
        ),
        onPressed: () => Get.back(),
      ) : null),
      // The main title shown when the AppBar is collapsed
      title: title ?? (titleText != null ? Text(
        titleText!,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ) : null),
      centerTitle: centerTitle,
      flexibleSpace: LiquidGlassContainer(
        borderRadius: borderRadius ?? const BorderRadius.vertical(bottom: Radius.circular(30)),
        opacity: isDark ? 0.3 : 0.6,
        blur: 20,
        child: flexibleSpace ?? (titleText != null ? FlexibleSpaceBar(
          stretchModes: const [StretchMode.blurBackground, StretchMode.zoomBackground],
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
          title: Text(
            titleText!,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ) : const SizedBox.expand()),
      ),
      actions: actions,
    );
  }
}
