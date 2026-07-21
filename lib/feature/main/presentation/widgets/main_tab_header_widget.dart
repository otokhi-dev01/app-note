import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'main_tab_header_action.dart';
part 'main_tab_header_badge.dart';
part 'main_tab_header_button.dart';
part 'main_tab_header_liquid_glass.dart';
part 'main_tab_header_logo.dart';
part 'main_tab_header_page_icon.dart';
part 'main_tab_header_title.dart';

class MainTabHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final VoidCallback? onRefresh;
  final VoidCallback? onAdd;
  final IconData addIcon;
  final Widget? trailing;
  final bool showLogo;
  final String logoAsset;
  final bool showLeading;
  final bool useSafeArea;

  const MainTabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingIcon,
    this.onLeadingPressed,
    this.onRefresh,
    this.onAdd,
    this.addIcon = CupertinoIcons.add,
    this.trailing,
    this.showLogo = false,
    this.logoAsset = 'assets/icons/app_icon.png',
    this.showLeading = true,
    this.useSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget header = Padding(
      padding: useSafeArea
          ? const EdgeInsets.fromLTRB(14, 8, 14, 4)
          : EdgeInsets.zero,
      child: _LiquidGlassHeader(
        title: title,
        subtitle: subtitle,
        leadingIcon: leadingIcon,
        onLeadingPressed: onLeadingPressed,
        onRefresh: onRefresh,
        onAdd: onAdd,
        addIcon: addIcon,
        trailing: trailing,
        showLogo: showLogo,
        logoAsset: logoAsset,
        showLeading: showLeading,
      ),
    );

    return useSafeArea ? SafeArea(bottom: false, child: header) : header;
  }
}
