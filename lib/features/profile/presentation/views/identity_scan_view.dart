import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/presentation/controllers/identity_scan_controller.dart';
import 'package:Note/features/profile/presentation/views/identity_camera_view.dart';
import 'package:Note/features/profile/presentation/views/identity_details_edit_view.dart';
import 'package:Note/features/profile/presentation/views/identity_image_view.dart';
import 'package:Note/features/profile/presentation/widgets/identity_flow_widgets.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// Digital Civic ID (national ID) scan-and-verify screen.
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
    final theme = Theme.of(context);
    final card = controller.card.value;

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
                        _buildCardTabs(context, card),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: IdentityPreviewCard(
                                label: 'identity_side_front'.tr,
                                imagePath: card?.frontImagePath,
                                onScan: controller.isLoading.value
                                    ? null
                                    : () => controller.onScanImage(front: true),
                                onView: () => Get.to<void>(
                                  () => const IdentityImageView(front: true),
                                ),
                                onDownload: controller.isLoading.value
                                    ? null
                                    : () => controller.onDownloadCard(front: true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: IdentityPreviewCard(
                                label: 'identity_side_back'.tr,
                                imagePath: card?.backImagePath,
                                front: false,
                                onScan: controller.isLoading.value
                                    ? null
                                    : () => controller.onScanImage(front: false),
                                onView: () => Get.to<void>(
                                  () => const IdentityImageView(front: false),
                                ),
                                onDownload: controller.isLoading.value
                                    ? null
                                    : () => controller.onDownloadCard(front: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        IdentitySectionHeader(
                          icon: CupertinoIcons.doc_person_fill,
                          label: 'id_information_title'.tr,
                          trailing: card == null
                              ? null
                              : CustomGlassButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () => Get.to<void>(
                                            () => IdentityDetailsEditView(
                                              card: card,
                                              onSave: controller.saveCorrections,
                                            ),
                                          ),
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
                        if (card == null)
                          _buildEmptyFields(context)
                        else
                          _buildFields(context, card),
                        const SizedBox(height: 32),
                        IdentityPrimaryButton(
                          label: 'document_review_upload'.tr,
                          loading: controller.isLoading.value,
                          onPressed: controller.isLoading.value ? null : controller.onConfirm,
                        ),
                        if (card != null) ...[
                          const SizedBox(height: 12),
                          IdentityDestructiveButton(
                            label: 'identity_delete_info_action'.tr,
                            onPressed: controller.isLoading.value ? null : controller.onDeleteInfo,
                          ),
                        ],
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

  Widget _buildCardTabs(BuildContext context, NationalIdCard? activeCard) {
    final theme = Theme.of(context);
    final savedCards = controller.savedCards;
    final cards = <NationalIdCard?>[...savedCards];
    if (activeCard != null &&
        !cards.any((card) => card?.idNumber == activeCard.idNumber)) {
      // Keep a newly scanned card visible while a failed save is retried.
      cards.add(activeCard);
    }
    if (cards.isEmpty) cards.add(null);
    final busy = controller.isLoading.value;
    return Row(
      key: const ValueKey('identity_card_tabs'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (index, card) in cards.indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: card == null
                          ? 'identity_add_new_action'.tr
                          : [
                              card.nameKhmer,
                              card.nameLatin,
                              card.idNumber,
                            ].where((value) => value.isNotEmpty).join(' • '),
                      child: ChoiceChip(
                        key: ValueKey(
                          'identity_card_tab_${card?.idNumber ?? 'empty'}',
                        ),
                        label: Text(
                          'identity_card_number'.trParams({
                            'number': '${index + 1}',
                          }),
                        ),
                        selected: card?.idNumber == activeCard?.idNumber,
                        showCheckmark: false,
                        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: card?.idNumber == activeCard?.idNumber 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurfaceVariant,
                          fontWeight: card?.idNumber == activeCard?.idNumber 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: card?.idNumber == activeCard?.idNumber 
                            ? theme.colorScheme.primary.withValues(alpha: 0.5) 
                            : theme.dividerColor.withValues(alpha: 0.1),
                        ),
                        onSelected:
                            busy ||
                                card == null ||
                                !savedCards.any(
                                  (saved) => saved.idNumber == card.idNumber,
                                )
                            ? null
                            : (selected) {
                                if (selected) {
                                  controller.onSelectIdentity(card.idNumber);
                                }
                              },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'identity_add_new_action'.tr,
          child: TextButton.icon(
            key: const ValueKey('identity_add_button'),
            onPressed: busy ? null : controller.onAddIdentity,
            icon: const Icon(CupertinoIcons.plus, size: 18),
            label: Text('identity_add_action'.tr),
            style: TextButton.styleFrom(foregroundColor: idAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildFields(BuildContext context, NationalIdCard card) {
    final theme = Theme.of(context);
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
            style: theme.textTheme.titleMedium?.copyWith(
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
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
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
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
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    IdentityTag(
                      'identity_valid_years_caption'.trParams({
                        'years': '${card.validityYears}',
                      }),
                      color: idGreen,
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
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
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
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
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
