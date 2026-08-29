import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/features/settings/presentation/widgets/settings_app_bar.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class _FaqEntry {
  final String question;
  final String answer;
  const _FaqEntry(this.question, this.answer);
}

List<_FaqEntry> get _faqEntries => [
  _FaqEntry('help_center_faq_q1'.tr, 'help_center_faq_a1'.tr),
  _FaqEntry('help_center_faq_q2'.tr, 'help_center_faq_a2'.tr),
  _FaqEntry('help_center_faq_q3'.tr, 'help_center_faq_a3'.tr),
  _FaqEntry('help_center_faq_q4'.tr, 'help_center_faq_a4'.tr),
];

/// Placeholder support screen — the app doesn't have a support inbox or FAQ
/// backend yet, so this covers the features that already exist.
class HelpCenterView extends StatelessWidget {
  const HelpCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SettingsSliverAppBar(
              title: "help_center_title".tr,
              useSurfaceBackButtonColor: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: GlassCard(
                  borderRadius: 28,
                  children: [
                    for (int i = 0; i < _faqEntries.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _faqEntries[i].question,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _faqEntries[i].answer,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < _faqEntries.length - 1)
                        const Divider(indent: 16, height: 1),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
