part of '../editor_view.dart';

class _FloatingKeyboardAccessoryBar extends StatelessWidget {
  final VoidCallback onAddPhoto;
  final VoidCallback onDraw;
  final VoidCallback onChecklist;
  final VoidCallback onFormat;
  final VoidCallback onDone;

  const _FloatingKeyboardAccessoryBar({
    required this.onAddPhoto,
    required this.onDraw,
    required this.onChecklist,
    required this.onFormat,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: Colors.transparent,
      child: Center(
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: style.surface,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: style.border.withValues(alpha: .7)),
            boxShadow: [
              BoxShadow(
                color: style.shadow,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onFormat,
                child: Text(
                  'Aa',
                  style: TextStyle(
                    color: style.theme.colorScheme.primary,
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              _AccessoryIcon(
                CupertinoIcons.list_bullet_indent,
                onTap: onChecklist,
              ),
              _AccessoryIcon(
                CupertinoIcons.table,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.snackbar(
                    "Table",
                    "Tables are not available in this version.",
                  );
                },
              ),
              _AccessoryIcon(CupertinoIcons.paperclip, onTap: onAddPhoto),
              _AccessoryIcon(CupertinoIcons.pencil_circle, onTap: onDraw),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onDone,
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: style.theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessoryIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _AccessoryIcon(this.icon, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap ?? () => HapticFeedback.lightImpact(),
      child: Icon(icon, color: style.theme.colorScheme.primary, size: 22),
    );
  }
}
