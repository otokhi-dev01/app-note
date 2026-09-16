import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/features/profile/presentation/widgets/card_flow_widgets.dart';
import 'package:Note/features/profile/presentation/controllers/credit_card_controller.dart';
import 'package:Note/features/profile/presentation/views/card_camera_view.dart';

class CardScanView extends GetView<CreditCardController> {
  const CardScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: cardFlowTheme(context),
      child: Builder(
        builder: (context) => Obx(() {
          return switch (controller.currentStep.value) {
            CardScanStep.intro || CardScanStep.list => _buildIntroStep(context),
            CardScanStep.scanningFront ||
            CardScanStep.scanningBack => CardCameraView(
              onComplete: controller.onCameraScanComplete,
              onCancel: controller.onCancelCamera,
              onEnterManually: controller.onEnterManually,
              onSideChanged: controller.onCameraSideChanged,
            ),
            CardScanStep.processing => _buildProcessingStep(context),
            CardScanStep.result => _buildResultStep(context),
            CardScanStep.confirmation => _buildConfirmationStep(context),
            CardScanStep.success => _buildSuccessStep(context),
          };
        }),
      ),
    );
  }

  AppBar _appBar({String? title}) => AppBar(
    leading: IconButton(
      icon: const Icon(CupertinoIcons.back, size: 23),
      onPressed: () => Get.back(),
    ),
    title: title == null ? null : Text(title),
  );

  Widget _primaryAction(String label, VoidCallback onPressed) => ElevatedButton(
    onPressed: controller.isLoading.value ? null : onPressed,
    child: controller.isLoading.value
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label),
  );

  Widget _subtitle(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(color: cardFlowMuted, fontSize: 14, height: 1.5),
  );

  Widget _buildIntroStep(BuildContext context) => Scaffold(
    appBar: _appBar(),
    body: CardFlowBody(
      children: [
        const Spacer(),
        const CardIntroArtwork(),
        const SizedBox(height: 26),
        const Text(
          'Scan Your Card',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        _subtitle(
          'Quickly and securely scan your credit or debit card to automatically fill in the details.',
        ),
        const SizedBox(height: 30),
        _buildFeatureRow(
          CupertinoIcons.bolt_fill,
          'Fast & Accurate',
          'Auto-detects card information',
          const Color(0xFF2EBB83),
        ),
        const SizedBox(height: 22),
        _buildFeatureRow(
          CupertinoIcons.lock_fill,
          'Secure',
          'Your data stays private',
          cardFlowBlue,
        ),
        const SizedBox(height: 22),
        _buildFeatureRow(
          CupertinoIcons.camera_fill,
          'Scan Both Sides',
          'Capture front and back of your card',
          const Color(0xFF7554DE),
        ),
        const SizedBox(height: 32),
        const Spacer(),
        _primaryAction('Start Scanning', controller.onStartScanningPressed),
        TextButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.onEnterManually,
          child: const Text('Enter Card Manually'),
        ),
      ],
    ),
  );

  Widget _buildFeatureRow(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 23),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: cardFlowMuted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildProcessingStep(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF10161E),
    appBar: AppBar(
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back),
        onPressed: () => Get.back(),
      ),
    ),
    body: CardFlowBody(
      children: [
        const Spacer(),
        const Center(
          child: SizedBox(
            width: 146,
            height: 146,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    backgroundColor: Color(0xFF273246),
                    color: cardFlowBlue,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(CupertinoIcons.creditcard, size: 62, color: cardFlowBlue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 34),
        const Text(
          'Extracting Card Information',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _subtitle('Please wait while we process\nyour card details...'),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1B222D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Column(
            children: [
              _buildExtractionItem('Reading card number'),
              const SizedBox(height: 18),
              _buildExtractionItem('Detecting cardholder name'),
              const SizedBox(height: 18),
              _buildExtractionItem('Extracting expiry date'),
              const SizedBox(height: 18),
              _buildExtractionItem('Reading security code (CVV)'),
            ],
          ),
        ),
        const Spacer(flex: 2),
      ],
    ),
  );

  Widget _buildExtractionItem(String text) => Row(
    children: [
      const Icon(
        CupertinoIcons.checkmark_circle_fill,
        size: 24,
        color: Color(0xFF7CA4EC),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFFACB4C2), fontSize: 13),
        ),
      ),
    ],
  );

  Widget _buildResultStep(BuildContext context) {
    final card = controller.scannedCard.value;
    if (card == null) return _buildIntroStep(context);
    return Scaffold(
      appBar: _appBar(title: 'Card Details Found'),
      body: CardFlowBody(
        children: [
          _subtitle(
            "We've successfully scanned your card.\nPlease review the information below.",
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: PaymentCardPreview(card: card, obscureNumber: false),
          ),
          const SizedBox(height: 32),
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
            '${card.expiryMonth} / ${card.expiryYear}',
          ),
          _buildResultRow(CupertinoIcons.creditcard, 'CVV', card.cvv),
          _buildResultRow(
            CupertinoIcons.creditcard_fill,
            'Card Brand',
            card.cardBrand,
          ),
          const SizedBox(height: 24),
          const Spacer(),
          _primaryAction('Continue', controller.onContinueToConfirmation),
          const SizedBox(height: 8),
          TextButton(
            onPressed: controller.isLoading.value
                ? null
                : controller.onRetakeScan,
            child: const Text('Retake'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: cardFlowMuted),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(color: cardFlowMuted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  Widget _buildConfirmationStep(BuildContext context) => Scaffold(
    appBar: _appBar(title: 'Confirm Details'),
    body: CardFlowBody(
      children: [
        _subtitle('You can edit the information if needed.'),
        const SizedBox(height: 28),
        _buildFieldLabel('Card Number', context),
        _buildCardTextField(
          controller.cardNumberController,
          context: context,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('Cardholder Name', context),
        _buildCardTextField(
          controller.cardholderNameController,
          context: context,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Expiry Month', context),
                  _buildDropdown(
                    controller.expiryMonth,
                    List.generate(
                      12,
                      (i) => (i + 1).toString().padLeft(2, '0'),
                    ),
                    context,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
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
        const SizedBox(height: 22),
        _buildFieldLabel('CVV', context),
        _CardSecurityField(controller: controller.cvvController),
        const SizedBox(height: 18),
        _buildFieldLabel('Card Brand', context),
        _buildDropdown(controller.cardBrand, [
          'Visa',
          'Mastercard',
          'AMEX',
        ], context),
        const SizedBox(height: 40),
        const Spacer(),
        _primaryAction('Save Card', controller.onSaveCardPressed),
        const SizedBox(height: 8),
        TextButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.onRetakeScan,
          child: const Text('Retake Scan'),
        ),
      ],
    ),
  );

  Widget _buildFieldLabel(String label, BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );

  Widget _buildCardTextField(
    TextEditingController controller, {
    required BuildContext context,
    TextInputType keyboardType = TextInputType.text,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    style: const TextStyle(fontSize: 14),
    decoration: _cardInputDecoration(context),
  );

  Widget _buildDropdown(
    RxString value,
    List<String> items,
    BuildContext context,
  ) => Obx(
    () => DropdownButtonFormField<String>(
      // Recreate when scanning replaces a previously edited value.
      key: ValueKey(value.value),
      initialValue: value.value.isEmpty ? null : value.value,
      hint: const Text('Select'),
      isExpanded: true,
      icon: const Icon(CupertinoIcons.chevron_down, size: 14),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
      ),
      decoration: _cardInputDecoration(context),
      items: {...items, if (value.value.isNotEmpty) value.value}
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (selected) {
        if (selected != null) value.value = selected;
      },
    ),
  );

  Widget _buildSuccessStep(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF102A23)
        : const Color(0xFFEFFFF5),
    body: CardFlowBody(
      children: [
        const Spacer(),
        const CardSuccessArtwork(),
        const SizedBox(height: 14),
        const Text(
          'Card Added Successfully!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        _subtitle(
          'Your card has been added securely.\nYou can now use it for tracking your\nexpenses.',
        ),
        const SizedBox(height: 28),
        if (controller.cards.isNotEmpty)
          PaymentCardPreview(card: controller.cards.last),
        const SizedBox(height: 36),
        const Spacer(),
        _primaryAction('Done', controller.onDonePressed),
        const SizedBox(height: 8),
        TextButton(
          onPressed: controller.onAddAnotherCard,
          child: const Text('Add Another Card'),
        ),
      ],
    ),
  );
}

InputDecoration _cardInputDecoration(BuildContext context) => InputDecoration(
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(7),
    borderSide: BorderSide(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(7),
    borderSide: const BorderSide(color: cardFlowBlue),
  ),
);

class _CardSecurityField extends StatefulWidget {
  const _CardSecurityField({required this.controller});
  final TextEditingController controller;

  @override
  State<_CardSecurityField> createState() => _CardSecurityFieldState();
}

class _CardSecurityFieldState extends State<_CardSecurityField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextField(
    controller: widget.controller,
    obscureText: _obscure,
    keyboardType: TextInputType.number,
    style: const TextStyle(fontSize: 14),
    decoration: _cardInputDecoration(context).copyWith(
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Show CVV' : 'Hide CVV',
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
          size: 18,
          color: cardFlowMuted,
        ),
      ),
    ),
  );
}
