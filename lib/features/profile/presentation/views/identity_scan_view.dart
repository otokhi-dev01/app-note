import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/presentation/controllers/identity_scan_controller.dart';
import 'package:Note/features/profile/presentation/views/identity_camera_view.dart';
import 'package:Note/features/profile/presentation/views/identity_details_edit_view.dart';
import 'package:Note/features/profile/presentation/widgets/identity_flow_widgets.dart';

/// Digital Civic ID (national ID) scan-and-verify screen.
///
/// Shows the bilingual (Khmer/English) OCR result once both sides of the ID
/// have been scanned, and doubles as the entry point ("Camera Scan / New
/// OCR") before any scan has happened. The scan itself is driven by
/// `IdentityScanController.onStartScan`: BlinkID's native scanning UI when a
/// license is configured, or this app's own camera screen
/// ([IdentityScanStep.scanning], see `IdentityCameraView`) otherwise — see
/// that controller's doc comment for the full story.
class IdentityScanView extends GetView<IdentityScanController> {
  const IdentityScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return switch (controller.currentStep.value) {
        IdentityScanStep.main => _buildMainStep(context),
        IdentityScanStep.scanning => IdentityCameraView(
          onFrontCaptured: controller.onFrontCaptured,
          onBackCaptured: controller.onBackCaptured,
          onCancel: controller.onCancelCamera,
        ),
        IdentityScanStep.processing => _buildProcessingStep(context),
      };
    });
  }

  Widget _buildMainStep(BuildContext context) {
    final card = controller.card.value;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          IdentityAppHeader(
            onBackTap: () => Get.back(),
            onCameraTap: controller.onRescan,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (card == null)
                          const IdentityStatusBanner(verified: false)
                        else
                          IdentityFieldCard(
                            label:
                                (controller.savedToProfile.value
                                        ? 'id_information_saved'
                                        : 'id_information_save_failed_title')
                                    .tr,
                            child: Text(
                              (controller.savedToProfile.value
                                      ? 'identity_profile_review_hint'
                                      : 'id_information_save_failed_message')
                                  .tr,
                            ),
                          ),
                        const SizedBox(height: 22),
                        IdentitySectionHeader(
                          icon: CupertinoIcons.square_stack_3d_up_fill,
                          label: 'identity_scanned_previews_title'.tr,
                          trailing: TextButton.icon(
                            onPressed: controller.onRescan,
                            icon: const Icon(
                              CupertinoIcons.arrow_2_circlepath,
                              size: 13,
                            ),
                            label: Text('identity_refresh_action'.tr),
                            style: TextButton.styleFrom(
                              foregroundColor: idGreen,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(fontSize: 11.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: IdentityPreviewCard(
                                label: 'identity_photo_hologram_label'.tr,
                                imagePath: card?.frontImagePath,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: IdentityPreviewCard(
                                label: 'identity_mrz_chip_data_label'.tr,
                                imagePath: card?.backImagePath,
                                front: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        IdentitySectionHeader(
                          icon: CupertinoIcons.doc_person_fill,
                          label: 'id_information_title'.tr,
                          trailing: card == null
                              ? null
                              : TextButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () => Get.to<void>(
                                          () => IdentityDetailsEditView(
                                            card: card,
                                            onSave: controller.saveCorrections,
                                          ),
                                        ),
                                  child: Text('identity_edit_details'.tr),
                                ),
                        ),
                        const SizedBox(height: 12),
                        if (card == null)
                          _buildEmptyFields(context)
                        else
                          _buildFields(context, card),
                        const SizedBox(height: 26),
                        if (card != null) ...[
                          IdentityPrimaryButton(
                            label:
                                (controller.savedToProfile.value
                                        ? 'identity_view_profile'
                                        : 'identity_save_profile')
                                    .tr,
                            loading: controller.isLoading.value,
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.onViewProfile,
                          ),
                          const SizedBox(height: 10),
                        ],
                        IdentityPrimaryButton(
                          label: 'document_review_upload'.tr,
                          loading: controller.isLoading.value,
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.onConfirm,
                        ),
                        const SizedBox(height: 10),
                        IdentitySecondaryButton(
                          label: card == null
                              ? 'identity_start_scanning_action'.tr
                              : 'identity_rescan_action'.tr,
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.onRescan,
                        ),
                        const SizedBox(height: 18),
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

  Widget _buildFields(BuildContext context, NationalIdCard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IdentityFieldCard(
          label: 'id_number_label'.tr,
          tag: IdentityTag(
            'identity_chip_matched_tag'.tr.toUpperCase(),
            color: idGreen,
            icon: CupertinoIcons.checkmark_shield_fill,
          ),
          child: IdentityCopyableValue(card.idNumber),
        ),
        const SizedBox(height: 12),
        IdentityFieldCard(
          label: 'identity_name_khmer_label'.tr,
          tag: const Icon(
            CupertinoIcons.checkmark_alt_circle_fill,
            size: 16,
            color: idGreen,
          ),
          child: Text(
            card.nameKhmer,
            style: const TextStyle(
              color: idInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        IdentityFieldCard(
          label: 'identity_name_latin_label'.tr,
          tag: const Icon(
            CupertinoIcons.checkmark_alt_circle_fill,
            size: 16,
            color: idGreen,
          ),
          child: Text(
            card.nameLatin,
            style: const TextStyle(
              color: idInk,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: IdentityFieldCard(
                label: 'date_of_birth_label'.tr,
                child: Text(
                  card.dateOfBirth,
                  style: const TextStyle(
                    color: idInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: IdentityFieldCard(
                label: 'id_expiry_date_label'.tr,
                tag: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: idGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.expiryDate,
                      style: const TextStyle(
                        color: idInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: idGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'identity_valid_years_caption'.trParams({
                            'years': '${card.validityYears}',
                          }).toUpperCase(),
                          style: const TextStyle(
                            color: idGreen,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        IdentityFieldCard(
          label: 'place_of_birth_label'.tr,
          leadingIcon: CupertinoIcons.map_pin_ellipse,
          child: Text(
            card.displayPlaceOfBirth.isEmpty
                ? 'identity_not_read'.tr
                : card.displayPlaceOfBirth,
            style: const TextStyle(color: idInk, fontSize: 13.5, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        IdentityFieldCard(
          label: 'current_address_label'.tr,
          leadingIcon: CupertinoIcons.location_solid,
          tag: const Icon(
            CupertinoIcons.checkmark_alt_circle_fill,
            size: 16,
            color: idGreen,
          ),
          child: Text(
            card.displayCurrentAddress.isEmpty
                ? 'identity_not_read'.tr
                : card.displayCurrentAddress,
            style: const TextStyle(color: idInk, fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        IdentityMrzBlock(lines: card.mrzLines),
      ],
    );
  }

  Widget _buildEmptyFields(BuildContext context) {
    final labels = [
      'id_number_label'.tr,
      'identity_name_khmer_label'.tr,
      'identity_name_latin_label'.tr,
      'date_of_birth_label'.tr,
      'place_of_birth_label'.tr,
      'current_address_label'.tr,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final label in labels) ...[
          IdentityFieldCard(
            label: label,
            child: const Text(
              '—',
              style: TextStyle(
                color: idMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
            child: SafeArea(
              top: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 96,
                        height: 96,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          color: idAccent,
                          backgroundColor: idNavyLight,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'identity_processing_title'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'identity_processing_subtitle'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: idMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
