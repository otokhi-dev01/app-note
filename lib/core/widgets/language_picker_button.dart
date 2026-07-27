import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/colors.dart';
import '../../app/services/storage_service.dart';
import 'liquid_glass_container.dart';

class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLanguagePicker(context),
      child: LiquidGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: BorderRadius.circular(12),
        opacity: 0.6,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrentFlag(),
            const SizedBox(width: 8),
            Text(
              _getCurrentLanguageName(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentFlag() {
    final locale = Get.locale ?? Get.deviceLocale;
    String? flagPath;
    if (locale?.languageCode == 'km') {
      flagPath = 'assets/images/flags/cambodia.png';
    } else if (locale?.languageCode == 'en') {
      flagPath = 'assets/images/flags/usa.png';
    } else if (locale?.languageCode == 'zh') {
      flagPath = 'assets/images/flags/china.png';
    }

    if (flagPath != null) {
      return Image.asset(flagPath, width: 24, height: 16, fit: BoxFit.cover);
    }
    return const Icon(Icons.language_rounded, size: 20, color: AppColors.primary);
  }

  String _getCurrentLanguageName() {
    final locale = Get.locale ?? Get.deviceLocale;
    if (locale?.languageCode == 'km') return 'ខ្មែរ';
    if (locale?.languageCode == 'zh') return '中文';
    return 'English';
  }

  void _showLanguagePicker(BuildContext context) {
    Get.dialog(
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: LiquidGlassContainer(
            borderRadius: BorderRadius.circular(30),
            padding: const EdgeInsets.all(24),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Language',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildLanguageOption(
                    'English',
                    const Locale('en', 'US'),
                    'assets/images/flags/usa.png',
                  ),
                  _buildLanguageOption(
                    'ខ្មែរ (Khmer)',
                    const Locale('km', 'KH'),
                    'assets/images/flags/cambodia.png',
                  ),
                  _buildLanguageOption(
                    '中文 (Chinese)',
                    const Locale('zh', 'CN'),
                    'assets/images/flags/china.png',
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String name, Locale locale, String? flagPath) {
    final isSelected = Get.locale?.languageCode == locale.languageCode;
    final storage = Get.find<StorageService>();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: flagPath != null
          ? Image.asset(flagPath, width: 30, height: 20, fit: BoxFit.cover)
          : const Icon(Icons.language, size: 24),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
      onTap: () {
        Get.updateLocale(locale);
        storage.languageCode = locale.languageCode;
        storage.countryCode = locale.countryCode;
        Get.back();
      },
    );
  }
}
