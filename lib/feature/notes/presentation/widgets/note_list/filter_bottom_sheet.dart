import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Tags',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TagTile(label: 'Work', count: 32, color: Colors.orange),
              _TagTile(label: 'Personal', count: 24, color: Colors.indigo),
              _TagTile(label: 'Ideas', count: 18, color: Colors.green),
              _TagTile(label: 'Important', count: 12, color: Colors.red),
              _TagTile(label: 'Inspiration', count: 8, color: Colors.pink),
              _AddTagTile(),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Filters',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _FilterItem(title: 'All Notes', isSelected: true),
          _FilterItem(title: 'Pinned'),
          _FilterItem(title: 'Reminders'),
          _FilterItem(title: 'Locked'),
          const SizedBox(height: 32),
          Text(
            'Sort By',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _SortDropdown(),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TagTile({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTagTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add Tag',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.add,
            size: 16,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  final String title;
  final bool isSelected;

  const _FilterItem({required this.title, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (isSelected)
            Icon(
              CupertinoIcons.checkmark_alt_circle_fill,
              color: colors.primary,
              size: 24,
            )
          else
            Icon(
              CupertinoIcons.chevron_forward,
              color: colors.onSurface.withValues(alpha: 0.2),
              size: 18,
            ),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            'Date Modified',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color: colors.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
