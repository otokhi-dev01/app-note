import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/presentation/controllers/identity_scan_controller.dart';
import 'package:Note/features/profile/presentation/views/identity_camera_view.dart';
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
                        IdentityStatusBanner(verified: card != null),
                        const SizedBox(height: 22),
                        IdentitySectionHeader(
                          icon: CupertinoIcons.square_stack_3d_up_fill,
                          khmerLabel: 'ចំណុចដែលបានស្កេន្',
                          englishLabel: 'Scanned Previews',
                          trailing: TextButton.icon(
                            onPressed: controller.onRescan,
                            icon: const Icon(
                              CupertinoIcons.arrow_2_circlepath,
                              size: 13,
                            ),
                            label: const Text('Refresh'),
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
                                khmerLabel: 'ផ្ទៃខាងមុខ',
                                englishLabel: 'Photo & Hologram',
                                imagePath: card?.frontImagePath,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: IdentityPreviewCard(
                                khmerLabel: 'ផ្ទៃខាងក្រោយ',
                                englishLabel: 'MRZ & Chip Data',
                                imagePath: card?.backImagePath,
                                front: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const IdentitySectionHeader(
                          icon: CupertinoIcons.doc_person_fill,
                          khmerLabel: 'ព័ត៌មានអត្តសញ្ញាណប័ណ្ណ',
                          englishLabel: 'ID Information',
                        ),
                        const SizedBox(height: 12),
                        if (card == null)
                          _buildEmptyFields(context)
                        else
                          _buildFields(context, card),
                        const SizedBox(height: 26),
                        IdentityPrimaryButton(
                          khmerLabel: 'បញ្ជាក់ព័ត៌មាន',
                          englishLabel: 'Confirm & Continue',
                          loading: controller.isLoading.value,
                          onPressed: card == null ? null : controller.onConfirm,
                        ),
                        const SizedBox(height: 10),
                        IdentitySecondaryButton(
                          label: card == null ? 'Start Scanning' : 'Rescan Card',
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.onRescan,
                        ),
                        const SizedBox(height: 18),
                        const IdentityFooterNote(
                          text:
                              'End-to-End Cryptographic Ledger Protection • ISO/IEC 18013-5\n'
                              'Protected under Royal Government of Cambodia Data Privacy & '
                              'Digital Identity Framework.',
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
          khmerLabel: 'លេខអត្តសញ្ញាណប័ណ្ណ',
          englishLabel: 'National ID Number',
          tag: const IdentityTag(
            'CHIP MATCHED',
            color: idGreen,
            icon: CupertinoIcons.checkmark_shield_fill,
          ),
          child: IdentityCopyableValue(card.idNumber),
        ),
        const SizedBox(height: 12),
        IdentityFieldCard(
          khmerLabel: 'ឈ្មោះជាភាសាខ្មែរ',
          englishLabel: 'Name in Khmer',
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
          khmerLabel: 'ឈ្មោះជាអក្សរឡាតាំង',
          englishLabel: 'Name in Latin',
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
                khmerLabel: 'ថ្ងៃខែឆ្នាំកំណើត',
                englishLabel: 'Date of Birth',
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
                khmerLabel: 'កាលបរិច្ឆេទផុតកំណត់',
                englishLabel: 'Expiry Date',
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
                          'VALID (${card.validityYears} YEARS)',
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
          khmerLabel: 'ទីកន្លែងកំណើត',
          englishLabel: 'Place of Birth',
          leadingIcon: CupertinoIcons.map_pin_ellipse,
          child: Text(
            '${card.placeOfBirthKhmer} / ${card.placeOfBirthEnglish}',
            style: const TextStyle(color: idInk, fontSize: 13.5, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        IdentityFieldCard(
          khmerLabel: 'អាសយដ្ឋានបច្ចុប្បន្ន',
          englishLabel: 'Current Residence',
          leadingIcon: CupertinoIcons.location_solid,
          tag: const Icon(
            CupertinoIcons.checkmark_alt_circle_fill,
            size: 16,
            color: idGreen,
          ),
          child: Text(
            '${card.currentAddressKhmer}\n${card.currentAddressEnglish}',
            style: const TextStyle(color: idInk, fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        IdentityMrzBlock(lines: card.mrzLines),
      ],
    );
  }

  Widget _buildEmptyFields(BuildContext context) {
    const labels = [
      ('លេខអត្តសញ្ញាណប័ណ្ណ', 'National ID Number'),
      ('ឈ្មោះជាភាសាខ្មែរ', 'Name in Khmer'),
      ('ឈ្មោះជាអក្សរឡាតាំង', 'Name in Latin'),
      ('ថ្ងៃខែឆ្នាំកំណើត', 'Date of Birth'),
      ('ទីកន្លែងកំណើត', 'Place of Birth'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (khmer, english) in labels) ...[
          IdentityFieldCard(
            khmerLabel: khmer,
            englishLabel: english,
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
                      const Text(
                        'កំពុងស្រង់ព័ត៌មានអត្តសញ្ញាណប័ណ្ណ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Extracting ID Information…',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: idMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Validating chip signature and MRZ checksum.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: idMuted, fontSize: 12),
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
