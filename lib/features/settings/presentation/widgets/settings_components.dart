import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notes/features/settings/presentation/widgets/settings_palette.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.style,
    required this.title,
    required this.children,
  });

  final SettingsPalette style;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: style.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(10) : Radius.zero,
          bottom: isLast ? const Radius.circular(10) : Radius.zero,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            color: titleColor ?? style.primaryText,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 13,
                              color: style.secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!hideChevron)
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: Colors.grey,
                    ),
                ],
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: Divider(
                  height: 0.5,
                  color: style.border.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
