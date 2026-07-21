part of '../../view/create_note_view.dart';

class _SelectedDocumentsSection extends GetView<CreateNoteController> {
  const _SelectedDocumentsSection();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Obx(() {
      final List<NoteDraftDocument> documents =
          List<NoteDraftDocument>.unmodifiable(
            controller.selectedDocuments.toList(),
          );

      if (documents.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              _SectionHeader(
                icon: CupertinoIcons.doc_fill,
                title: 'Documents',
                subtitle:
                    '${documents.length} ${documents.length == 1 ? 'document' : 'documents'} selected',
              ),

              const SizedBox(height: 12),

              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.18 : 0.35,
                ),
              ),

              const SizedBox(height: 4),

              for (
                int index = 0;
                index < documents.length;
                index++
              ) ...<Widget>[
                _DocumentRow(
                  document: documents[index],
                  enabled: !controller.isSaving.value,
                  onRemove: () {
                    controller.removeDocument(documents[index]);
                  },
                ),
                if (index < documents.length - 1)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: colors.outlineVariant.withValues(alpha: 0.28),
                  ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
