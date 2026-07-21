part of 'main_tab_header_widget.dart';

class _HeaderBadge extends StatelessWidget {
  final int count;

  const _HeaderBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String text = count > 99 ? '99+' : count.toString();
    final bool circular = count < 10;

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: EdgeInsets.symmetric(horizontal: circular ? 0 : 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.error,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(10),
        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.error.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onError,
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
