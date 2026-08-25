import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/features/settings/presentation/controllers/account_controller.dart';

/// The Account screen's "Delete Account" row, iOS-26 style: tapping it morphs
/// into a glass pull-down anchored where it was — the same glass-menu
/// language as [NoteContextMenu] (the note list's "more" button) and
/// [NoteItemContextMenu] — rather than jumping straight into a plain,
/// centered confirmation dialog.
///
/// The pull-down is only the entry point; picking its one destructive item
/// still runs [AccountController.startDeleteAccount]'s own warning dialog and
/// password reauthentication before anything is actually deleted, the same
/// way [NoteItemContextMenu]'s "Delete" item opens a menu first and only
/// confirms the actual delete afterward.
class AccountDeleteMenu extends StatelessWidget {
  final AccountController controller;

  /// Builds the row the menu grows out of, given the callback that opens it.
  final Widget Function(BuildContext context, VoidCallback openMenu)
  triggerBuilder;
  final bool morphFromZero;

  const AccountDeleteMenu({
    super.key,
    required this.controller,
    required this.triggerBuilder,
    this.morphFromZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return lg.GlassMenu(
      triggerBuilder: triggerBuilder,
      menuWidth: 250,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      morphFromZero: morphFromZero,
      items: [
        lg.GlassMenuItem(
          title: 'delete_account_title'.tr,
          icon: const Icon(CupertinoIcons.delete_solid),
          isDestructive: true,
          onTap: controller.startDeleteAccount,
        ),
      ],
    );
  }
}
