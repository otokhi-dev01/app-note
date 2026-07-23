import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_surface_card.dart';

class ProfileHeaderCardWidget extends StatelessWidget {
  const ProfileHeaderCardWidget({
    this.displayName = 'Piisiit Note User',
    this.statusText = 'Signed in',
    this.avatarUrl,
    super.key,
  });

  final String displayName;
  final String statusText;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return AppSurfaceCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.05),
              ),
              alignment: Alignment.center,
              child: _avatar(colors),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  displayName.trim().isEmpty ? 'User Name' : displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText.trim().isEmpty ? 'user@email.com' : statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 18,
            color: colors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _avatar(ColorScheme colors) {
    final String url = avatarUrl?.trim() ?? '';
    final Uri? uri = Uri.tryParse(url);
    final bool canLoad =
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http');

    if (!canLoad) {
      return Icon(CupertinoIcons.person_solid, size: 30, color: colors.onSurface.withValues(alpha: 0.4));
    }

    return Image.network(
      url,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return Icon(
          CupertinoIcons.person_solid,
          size: 30,
          color: colors.onSurface.withValues(alpha: 0.4),
        );
      },
    );
  }
}
