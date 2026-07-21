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
      borderRadius: 20,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: <Widget>[
          ClipOval(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.11),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.18),
                ),
              ),
              alignment: Alignment.center,
              child: _avatar(colors),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            displayName.trim().isEmpty ? 'Piisiit Note User' : displayName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusText.trim().isEmpty ? 'Signed in' : statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
      return Icon(CupertinoIcons.person_fill, size: 37, color: colors.primary);
    }

    return Image.network(
      url,
      width: 82,
      height: 82,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return Icon(
          CupertinoIcons.person_fill,
          size: 37,
          color: colors.primary,
        );
      },
    );
  }
}
