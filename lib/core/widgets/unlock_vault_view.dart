import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class UnlockVaultView extends StatefulWidget {
  final Function(String) onUnlock;
  final VoidCallback? onCancel;

  const UnlockVaultView({
    super.key, 
    required this.onUnlock,
    this.onCancel,
  });

  @override
  State<UnlockVaultView> createState() => _UnlockVaultViewState();
}

class _UnlockVaultViewState extends State<UnlockVaultView> {
  String _pin = '';
  final int _maxPinLength = 4;

  void _onNumberTap(String number) {
    if (_pin.length < _maxPinLength) {
      HapticFeedback.lightImpact();
      setState(() => _pin += number);
      if (_pin.length == _maxPinLength) {
        Future.delayed(const Duration(milliseconds: 200), () {
          widget.onUnlock(_pin);
        });
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fingerprint_rounded, size: 40, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Unlock Vault',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter your PIN or use biometrics to\naccess private notes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 32),
          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_maxPinLength, (index) {
              bool isFilled = index < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? const Color(0xFF1E293B) : Colors.transparent,
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 48),
          // Number Pad
          Column(
            children: [
              _buildNumRow(['1', '2', '3']),
              const SizedBox(height: 12),
              _buildNumRow(['4', '5', '6']),
              const SizedBox(height: 12),
              _buildNumRow(['7', '8', '9']),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton('CANCEL', onTap: widget.onCancel ?? () => Get.back()),
                  _buildNumButton('0'),
                  IconButton(
                    onPressed: _onBackspace,
                    icon: const Icon(Icons.backspace_outlined, size: 28, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: numbers.map((n) => _buildNumButton(n)).toList(),
    );
  }

  Widget _buildNumButton(String number) {
    return InkWell(
      onTap: () => _onNumberTap(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
      ),
    );
  }
}
