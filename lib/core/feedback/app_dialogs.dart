import 'package:get/get.dart';

import 'package:Note/shared/widgets/ios_confirmation_dialog.dart';

/// Confirmations, in one place.
///
/// Thin wrapper over [IOSConfirmationDialog] so callers state intent
/// ("confirm deleting N notes") rather than assembling labels each time.
class AppDialogs {
  AppDialogs._();

  /// Returns `true` only if the user confirmed.
  static Future<bool> confirm({
    required String title,
    required String confirmLabel,
    bool isDestructive = true,
  }) async {
    var confirmed = false;
    await IOSConfirmationDialog.show(
      title: title,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
      onConfirm: () {
        confirmed = true;
        if (Get.isDialogOpen ?? false) Get.back();
      },
    );
    return confirmed;
  }

  /// "Move 3 notes to Recently Deleted?" — pluralized for you.
  static Future<bool> confirmDeleteNotes(int count) => confirm(
    title: count == 1
        ? 'Are you sure you want to move this note to Recently Deleted?'
        : 'Are you sure you want to move these $count notes to Recently Deleted?',
    confirmLabel: count == 1 ? 'Delete Note' : 'Delete $count Notes',
  );

  static Future<bool> confirmDeleteFolder(String folderName) => confirm(
    title: 'Delete "$folderName"? Its notes will move to Recently Deleted.',
    confirmLabel: 'Delete Folder',
  );
}
