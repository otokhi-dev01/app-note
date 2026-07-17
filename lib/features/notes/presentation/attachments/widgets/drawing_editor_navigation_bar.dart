import 'package:flutter/material.dart';

class DrawingEditorNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DrawingEditorNavigationBar({
    super.key,
    required this.title,
    required this.onCancel,
    required this.onDone,
  });

  final String title;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      toolbarHeight: preferredSize.height,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 94,
      leading: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: -.25,
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: scheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -.35,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: TextButton(
            onPressed: onDone,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              minimumSize: const Size(62, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              tapTargetSize: MaterialTapTargetSize.padded,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -.1,
              ),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
