import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notes/features/settings/presentation/widgets/settings_palette.dart';

const _settingsRadius = 20.0;

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.style,
    required this.title,
    required this.children,
    this.footer,
  });

  final SettingsPalette style;
  final String title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 7,
                end: 7,
                bottom: 9,
              ),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: style.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .65,
                  height: 1.2,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: style.surface,
              borderRadius: BorderRadius.circular(_settingsRadius),
              border: Border.all(color: style.cardBorder, width: .5),
              boxShadow: style.cardShadows,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_settingsRadius),
              child: Material(
                color: Colors.transparent,
                child: Column(children: children),
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 7,
                top: 9,
                end: 7,
              ),
              child: Text(
                footer!,
                style: TextStyle(
                  color: style.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsAccountCard extends StatelessWidget {
  const SettingsAccountCard({
    super.key,
    required this.style,
    required this.identifier,
    required this.onTap,
  });

  final SettingsPalette style;
  final String identifier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notes account',
      value: identifier,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_settingsRadius),
        overlayColor: WidgetStatePropertyAll(style.pressedOverlay),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(17, 16, 15, 16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: style.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: style.accent.withValues(alpha: .22),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.person_crop_circle_fill,
                  color: style.onAccent,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes Account',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: style.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      identifier,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: style.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SettingsChevron(style: style),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.style,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onTap,
    this.isLast = false,
    this.hideChevron = false,
    this.isFirst = false,
  });

  final SettingsPalette style;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;
  final bool isLast;
  final bool hideChevron;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final corners = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(_settingsRadius) : Radius.zero,
      bottom: isLast ? const Radius.circular(_settingsRadius) : Radius.zero,
    );

    return Semantics(
      button: onTap != null,
      label: title,
      value: subtitle,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: corners,
        overlayColor: WidgetStatePropertyAll(style.pressedOverlay),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 62),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 11, 14, 11),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: style.tinted(iconColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 19),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor ?? style.primaryText,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -.15,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: style.secondaryText,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                    if (!hideChevron) ...[
                      const SizedBox(width: 9),
                      _SettingsChevron(style: style),
                    ],
                  ],
                ),
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 63),
                child: SizedBox(
                  height: .5,
                  child: ColoredBox(color: style.separator),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsChevron extends StatelessWidget {
  const _SettingsChevron({required this.style});

  final SettingsPalette style;

  @override
  Widget build(BuildContext context) {
    return Icon(
      CupertinoIcons.chevron_forward,
      size: 14,
      color: style.secondaryText.withValues(alpha: .66),
    );
  }
}
