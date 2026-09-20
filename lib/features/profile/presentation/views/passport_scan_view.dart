import 'dart:io';

import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/features/profile/presentation/controllers/passport_scan_controller.dart';
import 'package:Note/features/profile/presentation/views/identity_camera_view.dart';
import 'package:Note/features/profile/presentation/widgets/identity_flow_widgets.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class PassportScanView extends GetView<PassportScanController> {
  const PassportScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return switch (controller.currentStep.value) {
        PassportScanStep.main => _buildMainStep(context),
        PassportScanStep.scanning => IdentityCameraView(
          passportMode: true,
          onFrontCaptured: controller.onPassportCaptured,
          onBackCaptured: (_) {}, // Not used in passport mode
          onCancel: controller.onCancelCamera,
        ),
        PassportScanStep.processing => _buildProcessingStep(context),
      };
    });
  }

  Widget _buildMainStep(BuildContext context) {
    final theme = Theme.of(context);
    final passport = controller.passport.value;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          IdentityAppHeader(
            onBackTap: () => Get.back(),
            onCameraTap: controller.isLoading.value ? null : controller.onRescan,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPassportHeader(context),
                        const SizedBox(height: 24),
                        if (passport != null)
                          _buildPassportPreview(context, passport)
                        else
                          _buildEmptyPassport(context),
                        const SizedBox(height: 28),
                        IdentitySectionHeader(
                          icon: CupertinoIcons.doc_text_fill,
                          label: 'passport_information_title'.tr,
                          trailing: CustomGlassButton(
                            onPressed: () => Get.find<ProfileController>().updatePassportInformation(),
                            width: 100,
                            height: 32,
                            borderRadius: 10,
                            opacity: 0.1,
                            padding: EdgeInsets.zero,
                            child: Text(
                              'identity_edit_details'.tr,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (passport != null)
                          _buildPassportFields(context, passport),
                        const SizedBox(height: 32),
                        if (passport == null)
                          IdentityPrimaryButton(
                            label: 'identity_start_scanning_action'.tr,
                            loading: controller.isLoading.value,
                            onPressed: controller.onStartScan,
                            icon: CupertinoIcons.camera_fill,
                          ),
                        if (passport != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: IdentityDestructiveButton(
                              label: 'passport_information_deleted'.tr,
                              onPressed: controller.isLoading.value ? null : controller.onDeletePassport,
                            ),
                          ),
                        const SizedBox(height: 24),
                        IdentityFooterNote(
                          text: 'identity_footer_protection'.tr,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassportHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const Icon(CupertinoIcons.doc_text_fill, size: 48, color: idAccent),
        const SizedBox(height: 12),
        Text(
          'passport_information_title'.tr,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPassportPreview(BuildContext context, dynamic passport) {
    final theme = Theme.of(context);
    return CustomGlassContainer(
      borderRadius: 16,
      blur: 20,
      opacity: 0.1,
      thickness: 1,
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1.5,
        child: passport.imagePath != null && File(passport.imagePath).existsSync()
            ? Image.file(File(passport.imagePath), fit: BoxFit.cover)
            : Center(child: Icon(CupertinoIcons.doc_text, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.2))),
      ),
    );
  }

  Widget _buildEmptyPassport(BuildContext context) {
    return CustomGlassContainer(
      borderRadius: 16,
      blur: 20,
      opacity: 0.05,
      thickness: 1,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(CupertinoIcons.camera_viewfinder, size: 48, color: idMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'identity_tap_to_scan'.tr,
            style: const TextStyle(color: idMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPassportFields(BuildContext context, dynamic passport) {
    return Column(
      children: [
        IdentityFieldCard(
          label: 'passport_number_label'.tr,
          child: Text(passport.passportNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        const SizedBox(height: 12),
        IdentityFieldCard(
          label: 'full_name_label'.tr,
          child: Text(passport.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: IdentityFieldCard(
                label: 'gender_label'.tr,
                child: Text(passport.gender),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: IdentityFieldCard(
                label: 'nationality_label'.tr,
                child: Text(passport.nationality),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        IdentityMrzBlock(lines: passport.mrzLines),
      ],
    );
  }

  Widget _buildProcessingStep(BuildContext context) {
    return Scaffold(
      backgroundColor: idInk,
      body: Column(
        children: [
          const IdentityAppHeader(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: idAccent),
                  const SizedBox(height: 24),
                  Text(
                    'identity_processing_title'.tr,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
