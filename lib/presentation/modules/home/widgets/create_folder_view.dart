import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/app/theme/colors.dart';
import '../home_style.dart';

class CreateFolderController extends GetxController {
  final nameController = TextEditingController(text: 'New Folder');
  final isSmartFolder = false.obs;
  final canDone = true.obs;
  final folderName = 'New Folder'.obs;

  @override
  void onInit() {
    super.onInit();
    // Select all text on init to match the image behavior
    nameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: nameController.text.length,
    );
    nameController.addListener(() {
      folderName.value = nameController.text;
      canDone.value = nameController.text.trim().isNotEmpty;
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }
  void clearName() {
    nameController.clear();
  }
}

class CreateFolderView extends StatelessWidget {
  const CreateFolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final controller = Get.put(CreateFolderController());

    return Scaffold(
      backgroundColor: style.background,
      appBar: AppBar(
        backgroundColor: style.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 70,
        leading: Center(
          child: _TopCircleButton(
            onTap: () => Get.back(),
            child: Icon(CupertinoIcons.xmark, color: Colors.black, size: 20),
          ),
        ),
        title: Text(
          'New Folder',
          style: TextStyle(
            color: style.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(() => Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: _TopCircleButton(
                onTap: controller.canDone.value
                    ? () => Get.back(result: controller.nameController.text.trim())
                    : null,
                backgroundColor: controller.canDone.value
                    ? AppColors.yellow
                    : AppColors.yellow.withValues(alpha: 0.5),
                child: Icon(CupertinoIcons.check_mark, color: Colors.white, size: 18),
              ),
            ),
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Name Input Section
            Container(
              decoration: BoxDecoration(
                color: style.isDark ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.nameController,
                      autofocus: true,
                      style: TextStyle(
                        color: style.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                      cursorColor: AppColors.yellow,
                      decoration: InputDecoration(
                        hintText: 'Name',
                        hintStyle: TextStyle(
                          color: style.secondaryText.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Obx(() => controller.folderName.value.isNotEmpty
                      ? GestureDetector(
                          onTap: controller.clearName,
                          child: Icon(
                            CupertinoIcons.clear_fill,
                            size: 20,
                            color: style.secondaryText.withValues(alpha: 0.3),
                          ),
                        )
                      : SizedBox.shrink()),
                ],
              ),
            ),
             SizedBox(height: 24),
            // Smart Folder Section
            Container(
              decoration: BoxDecoration(
                color: style.isDark ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Get.snackbar("Smart Folder", "Smart Folder features coming soon!");
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.yellow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.gear_alt_fill,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Make Into Smart Folder',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: style.primaryText,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Organize using tags and other filters',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: style.secondaryText.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: style.secondaryText.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color? backgroundColor;

  const _TopCircleButton({
    required this.onTap,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
