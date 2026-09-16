import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/features/profile/presentation/controllers/credit_card_controller.dart';
import 'package:Note/features/profile/presentation/widgets/card_flow_widgets.dart';

class MyCardsView extends GetView<CreditCardController> {
  const MyCardsView({super.key});

  @override
  Widget build(BuildContext context) => Theme(
    data: cardFlowTheme(context),
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('My Cards'),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, size: 23),
            onPressed: () => Get.back(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                tooltip: 'Add new card',
                icon: const Icon(CupertinoIcons.add, size: 21),
                style: IconButton.styleFrom(
                  backgroundColor: cardFlowBlue.withValues(alpha: 0.08),
                  foregroundColor: cardFlowBlue,
                ),
                onPressed: controller.startScanning,
              ),
            ),
          ],
        ),
        body: Obx(
          () => CardFlowBody(
            children: [
              const SizedBox(height: 16),
              for (final card in controller.cards) ...[
                PaymentCardPreview(card: card),
                const SizedBox(height: 24),
              ],
              if (controller.cards.isEmpty) ...[
                const SizedBox(height: 48),
                const Icon(
                  CupertinoIcons.creditcard,
                  size: 60,
                  color: cardFlowMuted,
                ),
                const SizedBox(height: 16),
                const Text('No cards added yet', textAlign: TextAlign.center),
                const SizedBox(height: 32),
              ],
              Material(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF242D3A)
                    : const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: controller.startScanning,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cardFlowBlue.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.add,
                            color: cardFlowBlue,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Card',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Scan or enter card details manually',
                                style: TextStyle(
                                  color: cardFlowMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.lock_fill,
                      size: 23,
                      color: cardFlowMuted,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your card information is private to this session.',
                        style: TextStyle(
                          color: cardFlowMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
