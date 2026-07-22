part of '../../view/create_note_view.dart';

class _MainEditorCard extends StatelessWidget {
  const _MainEditorCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return AppGlassSurface(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _TitleField(),

          const SizedBox(height: 13),

          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.25 : 0.40,
            ),
          ),

          const SizedBox(height: 15),

          const _BodyField(),
        ],
      ),
    );
  }
}
