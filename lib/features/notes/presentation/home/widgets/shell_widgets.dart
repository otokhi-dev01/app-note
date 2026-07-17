part of '../home_view.dart';

class _LinenHeader extends StatelessWidget {
  const _LinenHeader({
    required this.title,
    required this.onMenu,
    this.actions = const [],
  });

  final String title;
  final VoidCallback onMenu;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SizedBox(
        height: 52,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showBrandMark = constraints.maxWidth >= 360;
            return Row(
              children: [
                IconButton(
                  onPressed: onMenu,
                  tooltip: 'Menu',
                  icon: const Icon(CupertinoIcons.line_horizontal_3),
                ),
                if (showBrandMark) ...[
                  const SizedBox(width: 8),
                  const AppBrandMark(size: 34, borderRadius: 11),
                ],
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                    ),
                  ),
                ),
                ...actions,
              ],
            );
          },
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SizedBox(
        height: 52,
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
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
    final scheme = Theme.of(context).colorScheme;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: AppGlassSurface(
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: items.asMap().entries.map((entry) {
            final selected = selectedIndex == entry.key;
            final color = selected ? scheme.primary : scheme.onSurfaceVariant;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: entry.value.$2,
                child: InkWell(
                  onTap: () => onSelect(entry.key),
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedContainer(
                    duration: reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary.withValues(alpha: .18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(entry.value.$1, color: color, size: 22),
                        const SizedBox(height: 2),
                        Text(
                          entry.value.$2,
                          style: TextStyle(
                            color: color,
                            fontSize: 10.5,
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
    return SizedBox(
      height: 44,
      child: TextField(
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(CupertinoIcons.search, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}
