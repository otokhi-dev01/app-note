import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import 'liquid_glass_container.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool isError;

  const CustomTextField({
    super.key,
    this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
        ],
        LiquidGlassContainer(
          borderRadius: BorderRadius.circular(16),
          opacity: 0.1,
          blur: 10,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.4),
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: Icon(
                prefixIcon, 
                size: 22, 
                color: AppColors.primary.withValues(alpha: 0.6),
                weight: 800,
              ),
              suffixIcon: suffixIcon,
              fillColor: Colors.transparent,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              
              // Default border
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isError ? AppColors.error : AppColors.primary.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
              // Focused border
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isError ? AppColors.error : AppColors.accent.withValues(alpha: 0.5),
                  width: 2.0,
                ),
              ),
              // Error and base borders
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isError ? AppColors.error : Colors.transparent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
