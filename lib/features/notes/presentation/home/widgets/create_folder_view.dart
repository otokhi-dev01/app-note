import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../home_style.dart';

class CreateFolderController extends GetxController {
  CreateFolderController() {
    nameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: nameController.text.length,
    );
    nameController.addListener(_handleNameChanged);
  }

  final nameController = TextEditingController(text: 'New Folder');
  final isSmartFolder = false.obs;
  final canDone = true.obs;
  final folderName = 'New Folder'.obs;

  void _handleNameChanged() {
    folderName.value = nameController.text;
    canDone.value = nameController.text.trim().isNotEmpty;
  }

  @override
  void onClose() {
    nameController.removeListener(_handleNameChanged);
    nameController.dispose();
    super.onClose();
  }

  void clearName() {
    nameController.clear();
  }
}

class CreateFolderView extends StatefulWidget {
  const CreateFolderView({super.key});

  @override
  State<CreateFolderView> createState() => _CreateFolderViewState();
}

class _CreateFolderViewState extends State<CreateFolderView> {
  late final CreateFolderController controller;

  @override
  void initState() {
    super.initState();
    controller = CreateFolderController();
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final scheme = style.theme.colorScheme;

    return Scaffold(
      backgroundColor: style.background,
      appBar: AppBar(
        backgroundColor: style.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 88,
        leading: _FolderToolbarButton(
          label: 'Cancel',
          onPressed: () => Get.back(),
        ),
        title: Text(
          'New Folder',
          style: TextStyle(
            color: style.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FolderToolbarButton(
                label: 'Done',
                isEmphasized: true,
                onPressed: controller.canDone.value
                    ? () => Get.back(
                        result: controller.nameController.text.trim(),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CreateFolderSectionLabel('Folder Name'),
              Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 66),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          CupertinoIcons.folder_fill,
                          color: scheme.onPrimary,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: TextField(
                          controller: controller.nameController,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!controller.canDone.value) return;
                            Get.back(
                              result: controller.nameController.text.trim(),
                            );
                          },
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                          cursorColor: scheme.primary,
                          decoration: InputDecoration(
                            hintText: 'Name',
                            hintStyle: TextStyle(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.65,
                              ),
                            ),
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      Obx(
                        () => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: controller.folderName.value.isNotEmpty
                              ? IconButton(
                                  key: const ValueKey('clear-folder-name'),
                                  tooltip: 'Clear folder name',
                                  onPressed: controller.clearName,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 44,
                                    height: 44,
                                  ),
                                  icon: Icon(
                                    CupertinoIcons.clear_thick_circled,
                                    size: 19,
                                    color: scheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                )
                              : const SizedBox(
                                  key: ValueKey('empty-clear-folder-name'),
                                  width: 44,
                                  height: 44,
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _CreateFolderSectionLabel('Options'),
              Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Get.snackbar(
                      'Smart Folder',
                      'Smart Folder features coming soon!',
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 76),
                    padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            CupertinoIcons.gear_alt_fill,
                            color: scheme.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Make Into Smart Folder',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Organize using tags and other filters',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.2,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.chevron_forward,
                          size: 15,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 0),
                child: Text(
                  'Smart folders automatically collect notes that match the filters you choose.',
                  style: style.theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
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

class _CreateFolderSectionLabel extends StatelessWidget {
  const _CreateFolderSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _FolderToolbarButton extends StatelessWidget {
  const _FolderToolbarButton({
    required this.label,
    required this.onPressed,
    this.isEmphasized = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurfaceVariant.withValues(
            alpha: 0.45,
          ),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: TextStyle(
            fontSize: 17,
            fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
