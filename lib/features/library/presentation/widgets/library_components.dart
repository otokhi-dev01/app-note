import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../library_helpers.dart';

class LibraryScaffold extends StatelessWidget {
  const LibraryScaffold({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: Get.back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: Icon(
            CupertinoIcons.chevron_left,
            color: colors.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -.2,
          ),
        ),
        actions: action == null
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: action,
                ),
              ],
      ),
      body: child,
    );
  }
}

class LibrarySurface extends StatelessWidget {
  const LibrarySurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final decoration = libraryCardDecoration(context);
    return Container(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: child,
      ),
    );
  }
}

class LibraryFeatureIntro extends StatelessWidget {
  const LibraryFeatureIntro({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: colors.onSurface,
                    fontSize: 32,
                    height: 1.08,
                    letterSpacing: -1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          LibraryFeatureIcon(icon, size: 50, iconSize: 24),
        ],
      ),
    );
  }
}

class LibraryFeatureIcon extends StatelessWidget {
  const LibraryFeatureIcon(
    this.icon, {
    super.key,
    this.size = 44,
    this.iconSize = 21,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(icon, color: colors.primary, size: iconSize),
    );
  }
}

class LibraryFeatureEmpty extends StatelessWidget {
  const LibraryFeatureEmpty({
    super.key,
    required this.message,
    this.icon = CupertinoIcons.doc_text_search,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 310),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: colors.onSurfaceVariant, size: 31),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LibraryWeekLabel extends StatelessWidget {
  const LibraryWeekLabel(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LibraryStorageRow extends StatelessWidget {
  const LibraryStorageRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          minTileHeight: 70,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: LibraryFeatureIcon(icon, size: 42, iconSize: 20),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            value,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          trailing: Icon(
            CupertinoIcons.chevron_right,
            color: colors.onSurfaceVariant.withValues(alpha: .72),
            size: 14,
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 74,
            color: colors.outlineVariant.withValues(alpha: .55),
          ),
      ],
    );
  }
}

class LibrarySectionHeader extends StatelessWidget {
  const LibrarySectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: libraryFeatureEyebrow(context),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class LibraryCountBadge extends StatelessWidget {
  const LibraryCountBadge(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class LibraryCategoryDefinition {
  const LibraryCategoryDefinition(this.title, this.icon, this.patterns);

  final String title;
  final IconData icon;
  final List<String> patterns;
}
