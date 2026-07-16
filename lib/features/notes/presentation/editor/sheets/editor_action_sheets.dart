part of '../editor_view.dart';

extension _EditorActionSheets on EditorView {
  void _showFormattingMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Text Formatting'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.applyInlineFormat('**', '**');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.bold),
                SizedBox(width: 12),
                Text('Bold'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.applyInlineFormat('_', '_');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.italic),
                SizedBox(width: 12),
                Text('Italic'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.applyLineFormat('> ');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.text_quote),
                SizedBox(width: 12),
                Text('Quote'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.applyLineFormat('## ');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.textformat_size),
                SizedBox(width: 12),
                Text('Heading'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.insertTable();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.table),
                SizedBox(width: 12),
                Text('Insert Table'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              Get.snackbar(
                "Note Options",
                "Pinning notes is not available in editor.",
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.pin),
                SizedBox(width: 8),
                Text('Pin Note'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              Get.snackbar(
                "Note Options",
                "Locking notes is not available yet.",
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.lock),
                SizedBox(width: 8),
                Text('Lock Note'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              Get.snackbar("Note Options", "Duplication is not available yet.");
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_on_doc),
                SizedBox(width: 8),
                Text('Duplicate'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Get.back();
              controller.delete();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.trash),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showImageOptions(BuildContext context, int index) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Edit / Markup'),
            onPressed: () {
              Get.back();
              controller.editImage(index);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Replace from Gallery'),
            onPressed: () {
              Get.back();
              controller.replaceImage(index, ImageSource.gallery);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Replace from Camera'),
            onPressed: () {
              Get.back();
              controller.replaceImage(index, ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('Remove Image'),
            onPressed: () {
              Get.back();
              controller.removeImage(index);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Get.back(),
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Attachment'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Take Photo or Video'),
            onPressed: () {
              Get.back();
              controller.addImage(ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Choose Photo or Video'),
            onPressed: () {
              Get.back();
              controller.addImage(ImageSource.gallery);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Scan Documents'),
            onPressed: () {
              Get.back();
              Get.snackbar(
                "Scan Documents",
                "Document scanning is not available.",
              );
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Get.back(),
        ),
      ),
    );
  }
}
