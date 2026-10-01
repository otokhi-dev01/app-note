import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/features/profile/presentation/widgets/profile_text_editor.dart';
import 'package:Note/features/profile/presentation/views/profile_edit_screen.dart';

/// A focused, compact profile-name editor.
class EditNameSheet extends StatelessWidget {
  final String initialName;
  final Future<bool> Function(String name) onSave;

  const EditNameSheet({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialName,
    required Future<bool> Function(String name) onSave,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(
          title: 'edit_name_title'.tr,
          child: EditNameSheet(initialName: initialName, onSave: onSave),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileTextEditor(
      title: 'edit_name_title'.tr,
      subtitle: 'edit_name_subtitle'.tr,
      label: 'full_name_label'.tr,
      hint: 'edit_name_hint'.tr,
      initialValue: initialName,
      onSave: onSave,
      maxLength: 60,
      requiredMessage: 'name_required_message'.tr,
      textCapitalization: TextCapitalization.words,
    );
  }
}
