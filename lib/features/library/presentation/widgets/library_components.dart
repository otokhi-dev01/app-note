import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/app/theme/app_colors.dart';

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            CupertinoIcons.chevron_left,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [?action],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
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
    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          LibraryFeatureIcon(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.subtitle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryFeatureIcon extends StatelessWidget {
  const LibraryFeatureIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFF3EACB),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: 23),
    );
  }
}

class LibraryFeatureEmpty extends StatelessWidget {
  const LibraryFeatureEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.subtitle,
            fontSize: 16,
            height: 1.4,
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
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.subtitle),
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
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: LibraryFeatureIcon(icon),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(value),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 15),
        ),
        if (!isLast) const Divider(height: 1, indent: 72),
      ],
    );
  }
}

class LibraryCategoryDefinition {
  const LibraryCategoryDefinition(this.title, this.icon, this.patterns);

  final String title;
  final IconData icon;
  final List<String> patterns;
}
