import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/routes/app_pages.dart';

/// The profile screen's "more" menu, iOS-26 style: a glossy pull-down for
/// secondary actions like renaming or managing the account, matching the 
/// pattern of [NoteDetailMorePopup] and [NoteContextMenu].
class ProfileMorePopup extends StatelessWidget {
  final ProfileController controller;

  /// Builds the trigger (the "…" button or the rename affordance) that the 
  /// menu grows out of.
  final Widget Function(BuildContext context, VoidCallback toggleMenu)
      triggerBuilder;

  const ProfileMorePopup({
    super.key,
    required this.controller,
    required this.triggerBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => lg.GlassMenu(
        triggerBuilder: triggerBuilder,
        menuWidth: 250,
        menuAlignment: lg.GlassMenuAlignment.topRight,
        autoAdjustToScreen: true,
        menuPadding: const EdgeInsets.all(12),
        items: [
          if (!controller.isGuestMode.value) ...[
            _item(
              title: 'edit_name_title'.tr,
              icon: CupertinoIcons.pencil,
              onTap: controller.updateUserName,
            ),
            _item(
              title: 'Change Photo',
              icon: CupertinoIcons.camera,
              onTap: controller.updateProfileImage,
            ),
            const lg.GlassMenuDivider(),
          ],
          _item(
            title: 'Account Settings',
            icon: CupertinoIcons.person_crop_circle_fill,
            onTap: () => Get.toNamed(Routes.ACCOUNT),
          ),
          const lg.GlassMenuDivider(),
          _item(
            title: controller.isGuestMode.value ? 'Log In' : 'Log Out',
            icon: controller.isGuestMode.value
                ? CupertinoIcons.arrow_right_circle
                : CupertinoIcons.square_arrow_right,
            onTap: () {
              if (controller.isGuestMode.value) {
                Get.offAllNamed(Routes.LOGIN);
              } else {
                controller.logout();
              }
            },
            isDestructive: !controller.isGuestMode.value,
          ),
        ],
      ),
    );
  }

  lg.GlassMenuItem _item({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return lg.GlassMenuItem(
      title: title,
      icon: Icon(icon),
      isDestructive: isDestructive,
      onTap: onTap,
    );
  }
}
