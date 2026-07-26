import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/colors.dart';

class PinDialog extends StatefulWidget {
  final Function(String) onConfirm;

  const PinDialog({super.key, required this.onConfirm});

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  String pin = '';

  void _onKeyTap(String key) {
    if (pin.length < 4) {
      setState(() => pin += key);
      if (pin.length == 4) {
        widget.onConfirm(pin);
        Get.back();
      }
    }
  }

  void _onDelete() {
    if (pin.isNotEmpty) {
      setState(() => pin = pin.substring(0, pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
              child: const Icon(Icons.fingerprint, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('Unlock Vault', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Enter your PIN or use biometrics to access private notes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                height: 16,
                width: 16,
                decoration: BoxDecoration(
                  color: index < pin.length ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                ),
              )),
            ),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                ...List.generate(9, (index) => _buildKey((index + 1).toString())),
                _buildKey('CANCEL', fontSize: 12),
                _buildKey('0'),
                _buildKey('BACKSPACE', isIcon: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String label, {double fontSize = 24, bool isIcon = false}) {
    return InkWell(
      onTap: () {
        if (label == 'CANCEL') {
          Get.back();
        } else if (label == 'BACKSPACE') {
          _onDelete();
        } else {
          _onKeyTap(label);
        }
      },
      child: Center(
        child: isIcon 
          ? const Icon(Icons.backspace_outlined) 
          : Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
