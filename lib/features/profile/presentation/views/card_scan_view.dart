import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/features/profile/presentation/controllers/credit_card_controller.dart';
import 'package:Note/features/profile/domain/entities/credit_card.dart';

class CardScanView extends GetView<CreditCardController> {
  const CardScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.currentStep.value) {
        case CardScanStep.intro:
          return _buildIntroStep(context);
        case CardScanStep.scanningFront:
          return _buildScanningStep(context, isFront: true);
        case CardScanStep.scanningBack:
          return _buildScanningStep(context, isFront: false);
        case CardScanStep.processing:
          return _buildProcessingStep(context);
        case CardScanStep.result:
          return _buildResultStep(context);
        case CardScanStep.confirmation:
          return _buildConfirmationStep(context);
        case CardScanStep.success:
          return _buildSuccessStep(context);
        default:
          return _buildIntroStep(context);
      }
    });
  }

  Widget _buildIntroStep(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: theme.colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const Spacer(),
            Container(
              height: 180,
              width: 280,
              decoration: BoxDecoration(
                color: colors.primaryText.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Scan Your Card',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quickly and securely scan your credit or debit card to automatically fill in the details.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 48),
            _buildFeatureRow(
              CupertinoIcons.bolt_fill,
              'Scan & Review',
              'Check the details before saving',
              IosSemanticColors.green,
              context,
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(
              CupertinoIcons.lock_fill,
              'Secure',
              'Your data stays private',
              IosSemanticColors.blue,
              context,
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(
              CupertinoIcons.camera_fill,
              'Scan Both Sides',
              'Capture each side, then tap Save',
              IosSemanticColors.purple,
              context,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.onStartScanningPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: AppColors.onAccent(theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Start Scanning',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            TextButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.onEnterManually,
              child: Text(
                'Enter Card Manually',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScanningStep(BuildContext context, {required bool isFront}) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview Simulation
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Image.network(
                'https://images.unsplash.com/photo-1613243555988-441166d4d6fd?q=80&w=2070&auto=format&fit=crop',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Dark overlay with cutout
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 320,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scanning UI Layer
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Get.back(),
                      ),
                      Text(
                        isFront ? 'Scan Front Side' : 'Scan Back Side',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Instructions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    isFront
                        ? 'Align your card within the frame.\nThe card will be detected automatically.'
                        : 'Turn your card over and align the back side\nwithin the frame.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const Spacer(),

                // Frame Brackets
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 200,
                    child: Stack(
                      children: [
                        _buildCornerBracket(Alignment.topLeft),
                        _buildCornerBracket(Alignment.topRight),
                        _buildCornerBracket(Alignment.bottomLeft),
                        _buildCornerBracket(Alignment.bottomRight),

                        // Mock card hint inside
                        Center(
                          child: Opacity(
                            opacity: 0.2,
                            child: _buildMiniCard(
                              const CreditCard(
                                id: '',
                                cardNumber: '4532 3100 9999 1234',
                                cardholderName: 'VUTHUL VUN',
                                expiryMonth: '08',
                                expiryYear: '2030',
                                cvv: '123',
                                cardBrand: 'Visa',
                              ),
                              context,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                Text(
                  'Hold steady...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // Controls Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _CircleAction(icon: CupertinoIcons.bolt_fill),
                      GestureDetector(
                        onTap: isFront
                            ? controller.onFrontScanned
                            : controller.onBackScanned,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const _CircleAction(
                        icon: CupertinoIcons.photo_on_rectangle,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Mode Label
                Text(
                  isFront ? 'Front of card' : 'Back of card',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Custom Indicator Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 100),
                  child: SizedBox(
                    height: 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Track
                        Container(
                          height: 3,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Dots
                        Positioned(
                          left: 0,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Active Handle
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignment: isFront
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: IosSemanticColors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBracket(Alignment alignment) {
    const double size = 32.0;
    const double thickness = 4.0;
    const Color color = IosSemanticColors.blue;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Vertical line
            Positioned(
              top:
                  alignment == Alignment.topLeft ||
                      alignment == Alignment.topRight
                  ? 0
                  : null,
              bottom:
                  alignment == Alignment.bottomLeft ||
                      alignment == Alignment.bottomRight
                  ? 0
                  : null,
              left:
                  alignment == Alignment.topLeft ||
                      alignment == Alignment.bottomLeft
                  ? 0
                  : null,
              right:
                  alignment == Alignment.topRight ||
                      alignment == Alignment.bottomRight
                  ? 0
                  : null,
              child: Container(
                width: thickness,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(thickness / 2),
                ),
              ),
            ),
            // Horizontal line
            Positioned(
              top:
                  alignment == Alignment.topLeft ||
                      alignment == Alignment.topRight
                  ? 0
                  : null,
              bottom:
                  alignment == Alignment.bottomLeft ||
                      alignment == Alignment.bottomRight
                  ? 0
                  : null,
              left:
                  alignment == Alignment.topLeft ||
                      alignment == Alignment.bottomLeft
                  ? 0
                  : null,
              right:
                  alignment == Alignment.topRight ||
                      alignment == Alignment.bottomRight
                  ? 0
                  : null,
              child: Container(
                width: size,
                height: thickness,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(thickness / 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingStep(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? Colors.black
          : theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: 0.7,
                      strokeWidth: 4,
                      backgroundColor: Colors.white10,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.creditcard,
                        size: 56,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              const Text(
                'Extracting Card Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please wait while we process\nyour card details...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 60),
              _buildExtractionItem('Reading card number', true, context),
              _buildExtractionItem('Detecting cardholder name', true, context),
              _buildExtractionItem('Extracting expiry date', true, context),
              _buildExtractionItem('Reading security code (CVV)', true, context),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtractionItem(String text, bool completed, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            completed
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            color: completed ? IosSemanticColors.blue : Colors.white24,
            size: 26,
          ),
          const SizedBox(width: 18),
          Text(
            text,
            style: TextStyle(
              color: completed ? Colors.white : Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStep(BuildContext context) {
    final card = controller.scannedCard.value!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: theme.colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const Text(
              'Card Details Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review the details and fill in any missing fields on the next screen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 40),
            _buildMiniCard(card, context),
            const SizedBox(height: 48),
            _buildResultRow(
              CupertinoIcons.creditcard,
              'Card Number',
              card.cardNumber,
            ),
            _buildResultRow(
              CupertinoIcons.person,
              'Cardholder Name',
              card.cardholderName,
            ),
            _buildResultRow(
              CupertinoIcons.calendar,
              'Expiry Date',
              card.expiryDate,
            ),
            _buildResultRow(CupertinoIcons.lock, 'CVV', card.cvv),
            _buildResultRow(Icons.credit_card, 'Card Brand', card.cardBrand),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.onContinueToConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: AppColors.onAccent(theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: controller.onRetakeScan,
              child: Text(
                'Retake',
                style: TextStyle(
                  color: IosSemanticColors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: theme.colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Confirm Details',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'You can edit the information if needed.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 32),
            _buildFieldLabel('Card Number', context),
            _buildCardTextField(controller.cardNumberController, context: context),
            const SizedBox(height: 20),
            _buildFieldLabel('Cardholder Name', context),
            _buildCardTextField(controller.cardholderNameController, context: context),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Expiry Month', context),
                      _buildDropdown(controller.expiryMonth, [
                        '01',
                        '02',
                        '03',
                        '04',
                        '05',
                        '06',
                        '07',
                        '08',
                        '09',
                        '10',
                        '11',
                        '12',
                      ], context),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Expiry Year', context),
                      _buildDropdown(
                        controller.expiryYear,
                        List.generate(
                          20,
                          (i) => (DateTime.now().year + i).toString(),
                        ),
                        context,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFieldLabel('CVV', context),
            _buildCardTextField(
              controller.cvvController,
              context: context,
              suffix: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(CupertinoIcons.eye, color: Colors.grey, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            _buildFieldLabel('Card Brand', context),
            _buildDropdown(controller.cardBrand, [
              'Visa',
              'Mastercard',
              'AMEX',
            ], context),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.onSaveCardPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: AppColors.onAccent(theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Card',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: controller.onRetakeScan,
                child: Text(
                  'Retake Scan',
                  style: TextStyle(
                    color: IosSemanticColors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCardTextField(
    TextEditingController controller, {
    Widget? suffix,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(RxString value, List<String> items, BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value.value.isEmpty ? null : value.value,
            hint: Text('Select', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            isExpanded: true,
            icon: const Icon(CupertinoIcons.chevron_down, size: 14),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            items: {...items, if (value.value.isNotEmpty) value.value}
                .map(
                  (String item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) value.value = v;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: IosSemanticColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.checkmark,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Card Added Successfully!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your card has been added securely.\nYou can now use it for tracking your\nexpenses.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 48),
              _buildMiniCard(controller.cards.last, context),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.onDonePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: controller.onAddAnotherCard,
                child: const Text(
                  'Add Another Card',
                  style: TextStyle(
                    color: IosSemanticColors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniCard(CreditCard card, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Text(
              card.cardBrand.toUpperCase(),
              style: TextStyle(
                color: AppColors.onAccent(theme.colorScheme.primary),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            card.obscuredNumber,
            style: TextStyle(
              color: AppColors.onAccent(theme.colorScheme.primary),
              fontSize: 18,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.cardholderName,
                style: TextStyle(
                  color: AppColors.onAccent(theme.colorScheme.primary),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                card.expiryDate,
                style: TextStyle(
                  color: AppColors.onAccent(theme.colorScheme.primary),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;

  const _CircleAction({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}
