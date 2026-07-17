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

  void _showAttachmentOptions(BuildContext context, {int? afterStatement}) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Attachment'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Take Photo or Video'),
            onPressed: () {
              Get.back();
              controller.addImage(
                ImageSource.camera,
                afterStatement: afterStatement,
              );
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Choose Photo or Video'),
            onPressed: () {
              Get.back();
              controller.addImage(
                ImageSource.gallery,
                afterStatement: afterStatement,
              );
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
