import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            stretch: true,
            border: null,
            backgroundColor: Colors.transparent,
            largeTitle: Text(
              'Search',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SearchField(),
          ),
          SliverToBoxAdapter(
            child: _RecentSearches(),
          ),
          const SliverToBoxAdapter(
            child: _SectionHeader(title: 'Suggestions'),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _SuggestionItem(
                icon: CupertinoIcons.doc_text,
                iconColor: Colors.orange,
                title: 'Design System',
                time: '10:30 AM',
              ),
              _SuggestionItem(
                icon: CupertinoIcons.doc_text,
                iconColor: Colors.purple,
                title: 'Project Ideas',
                time: 'Yesterday',
              ),
              _SuggestionItem(
                icon: CupertinoIcons.doc_text,
                iconColor: Colors.green,
                title: 'Daily Journal',
                time: '9:20 AM',
              ),
              _SuggestionItem(
                icon: CupertinoIcons.doc_text,
                iconColor: Colors.red,
                title: 'Travel Plan',
                time: '2 days ago',
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              placeholder: 'Search notes...',
              borderRadius: BorderRadius.circular(14),
              backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.all(10),
              onPressed: () {},
              child: Icon(
                CupertinoIcons.mic_fill,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {},
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SearchChip(label: 'design system'),
              _SearchChip(label: 'project'),
              _SearchChip(label: 'meeting'),
              _SearchChip(label: 'ideas'),
              _SearchChip(label: 'journal'),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SearchChip extends StatelessWidget {
  final String label;
  const _SearchChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;

  const _SuggestionItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        time,
        style: TextStyle(
          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      onTap: () {},
    );
  }
}
