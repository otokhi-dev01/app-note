import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/recycle_bin_date_formatter.dart';

class TrashNoteCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final VoidCallback onTap;
  final bool isArchive;

  const TrashNoteCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.timestamp,
    required this.onTap,
    this.isArchive = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isArchive) ...[
                      Icon(
                        CupertinoIcons.trash,
                        size: 18,
                        color: colors.error.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isArchive)
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: 16,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (timestamp != null)
                  Text(
                    formatRecycleBinDate(timestamp!.toLocal()),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
