import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

class CustomGlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TapRegionCallback? onTapOutside;
  final TextStyle? textStyle;
  final TextStyle? placeholderStyle;
  final EdgeInsetsGeometry padding;
  final double iconSpacing;
  final CrossAxisAlignment iconAlignment;
  final double borderRadius;
  final double? height;
  final double? minHeight;
  final double? maxHeight;
  final Widget? bottom;
  final bool useOwnLayer;
  final lg.GlassQuality quality;

  const CustomGlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.onTapOutside,
    this.textStyle,
    this.placeholderStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.iconSpacing = 12,
    this.iconAlignment = CrossAxisAlignment.center,
    this.borderRadius = 18,
    this.height,
    this.minHeight,
    this.maxHeight,
    this.bottom,
    this.useOwnLayer = true,
    this.quality = lg.GlassQuality.standard,
  }) : assert(borderRadius >= 0),
       assert(height == null || (minHeight == null && maxHeight == null));

  @override
  Widget build(BuildContext context) {
    return lg.GlassTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      onSuffixTap: onSuffixTap,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      onTapOutside: onTapOutside,
      textStyle: textStyle,
      placeholderStyle: placeholderStyle,
      padding: padding,
      iconSpacing: iconSpacing,
      iconAlignment: iconAlignment,
      height: height,
      minHeight: minHeight,
      maxHeight: maxHeight,
      bottom: bottom,
      shape: lg.LiquidRoundedSuperellipse(borderRadius: borderRadius),
      useOwnLayer: useOwnLayer,
      quality: quality,
    );
  }
}

class CustomGlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCancel;
  final bool showsCancelButton;
  final bool autofocus;
  final bool enabled;
  final Color? searchIconColor;
  final Color? clearIconColor;
  final Color? cancelButtonColor;
  final Widget? cancelIcon;
  final double cancelIconSize;
  final TextStyle? textStyle;
  final TextStyle? placeholderStyle;
  final double height;
  final bool useOwnLayer;
  final lg.GlassQuality quality;

  const CustomGlassSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
    this.showsCancelButton = false,
    this.autofocus = false,
    this.enabled = true,
    this.searchIconColor,
    this.clearIconColor,
    this.cancelButtonColor,
    this.cancelIcon,
    this.cancelIconSize = 24,
    this.textStyle,
    this.placeholderStyle,
    this.height = 44,
    this.useOwnLayer = true,
    this.quality = lg.GlassQuality.standard,
  });

  @override
  Widget build(BuildContext context) {
    return lg.GlassSearchBar(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onCancel: onCancel,
      showsCancelButton: showsCancelButton,
      autofocus: autofocus,
      enabled: enabled,
      searchIconColor: searchIconColor,
      clearIconColor: clearIconColor,
      cancelButtonColor: cancelButtonColor,
      cancelIcon: cancelIcon,
      cancelIconSize: cancelIconSize,
      textStyle: textStyle,
      placeholderStyle: placeholderStyle,
      height: height,
      useOwnLayer: useOwnLayer,
      quality: quality,
    );
  }
}

class CustomGlassListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry contentPadding;
  final Color? leadingIconColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final bool standalone;
  final double borderRadius;
  final lg.GlassQuality quality;

  const CustomGlassListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.leadingIconColor,
    this.titleStyle,
    this.subtitleStyle,
    this.standalone = false,
    this.borderRadius = 18,
    this.quality = lg.GlassQuality.standard,
  }) : assert(borderRadius >= 0);

  static Widget get chevron => const Icon(
    CupertinoIcons.chevron_forward,
    color: CupertinoColors.systemGrey,
    size: 20,
  );

  @override
  Widget build(BuildContext context) {
    final tile = lg.GlassListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: contentPadding,
      leadingIconColor: leadingIconColor,
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
    );

    if (!standalone) return tile;

    return lg.GlassContainer(
      useOwnLayer: true,
      quality: quality,
      shape: lg.LiquidRoundedSuperellipse(borderRadius: borderRadius),
      child: tile,
    );
  }
}
