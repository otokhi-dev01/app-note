import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/features/profile/presentation/controllers/identity_scan_controller.dart';

/// Shows the complete source image, with pinch-to-zoom and local export.
class IdentityImageView extends GetView<IdentityScanController> {
  const IdentityImageView({super.key, required this.front});

  final bool front;

  @override
  Widget build(BuildContext context) => Obx(() {
    final path = front
        ? controller.card.value?.frontImagePath
        : controller.card.value?.backImagePath;
    final available = controller.hasImage(front: front);
    final busy = controller.isLoading.value;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text((front ? 'identity_side_front' : 'identity_side_back').tr),
        actions: [
          IconButton(
            tooltip: 'identity_download_image'.tr,
            onPressed: busy || !available
                ? null
                : () => controller.onDownloadCard(front: front),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (busy) const LinearProgressIndicator(),
            Expanded(
              child: available
                  ? InteractiveViewer(
                      key: ValueKey(path),
                      minScale: 1,
                      maxScale: 5,
                      child: Center(
                        child: Image.file(
                          File(path!),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Text(
                            'document_image_failed'.tr,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        'document_image_failed'.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: busy || controller.card.value == null
                        ? null
                        : () => controller.onScanImage(front: front),
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(
                      (front ? 'identity_scan_front' : 'identity_scan_back').tr,
                    ),
                  ),
                  if (controller.card.value != null &&
                      !controller.savedToProfile.value)
                    FilledButton.icon(
                      onPressed: busy ? null : controller.onSaveCard,
                      icon: const Icon(Icons.save_outlined),
                      label: Text('identity_save_card'.tr),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
}
