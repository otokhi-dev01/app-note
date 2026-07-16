part of '../home_view.dart';

class _LinenHeader extends StatelessWidget {
  const _LinenHeader({
    required this.title,
    required this.onMenu,
    this.eyebrow,
    this.actions = const [],
  });

  final String title;
  final String? eyebrow;
  final VoidCallback onMenu;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onMenu,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(CupertinoIcons.line_horizontal_3),
              ),
              const Spacer(),
              ...actions,
            ],
          ),
          const SizedBox(height: 12),
          if (eyebrow != null) ...[
            Text(eyebrow!, style: _eyebrowStyle),
            const SizedBox(height: 5),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 38,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactBar extends StatelessWidget {
  const _CompactBar({
    required this.title,
    required this.onBack,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final VoidCallback onBack;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(CupertinoIcons.chevron_left, size: 18),
            label: const Text('Folders'),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            width: 86,
            child: actionLabel == null
                ? null
                : TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
        ],
      ),
    );
  }
}

class _LinenNavigationBar extends StatelessWidget {
  const _LinenNavigationBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = [
      (CupertinoIcons.doc_text, 'Notes'),
      (CupertinoIcons.folder, 'Folders'),
      (CupertinoIcons.search, 'Search'),
      (CupertinoIcons.scope, 'Goals'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        MediaQuery.paddingOf(context).bottom + 7,
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final selected = selectedIndex == entry.key;
          final color = selected ? AppColors.primary : AppColors.subtitle;
          return Expanded(
            child: Semantics(
              selected: selected,
              button: true,
              label: entry.value.$2,
              child: InkResponse(
                onTap: () => onSelect(entry.key),
                radius: 30,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(entry.value.$1, color: color, size: 24),
                      const SizedBox(height: 3),
                      Text(
                        entry.value.$2,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, this.readOnly = false, this.onTap});

  final String hint;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(CupertinoIcons.search),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

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
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}
