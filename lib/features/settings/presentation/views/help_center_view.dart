import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/shared/widgets/glass_widgets.dart';

class _FaqEntry {
  final String question;
  final String answer;
  const _FaqEntry(this.question, this.answer);
}

const _faqEntries = [
  _FaqEntry(
    'How do I create a note without an account?',
    'From the welcome screen, tap "Continue without account." Notes you create '
        'this way are saved only on this device.',
  ),
  _FaqEntry(
    'How do I organize notes into folders?',
    'Tap the "+" on the Pii Cloud or On My Phone section header on the Folders '
        'screen to create a folder there, then move notes into it from the note\'s '
        'options menu.',
  ),
  _FaqEntry(
    'How do I change the app\'s appearance?',
    'Go to Settings > Appearance and choose System Default, Light, or Dark.',
  ),
  _FaqEntry(
    'Where did a deleted note go?',
    'Deleted notes and folders move to Recently Deleted, where they can be '
        'restored.',
  ),
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
            CustomGlassSliverAppBar(
              expandedHeight: 120,
              toolbarHeight: 56,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              centerTitle: true,
              leading: CustomGlassButton(
                onPressed: () => Get.back(),
                width: 44,
                height: 44,
                shape: GlassShape.circle,
                blur: 10,
                opacity: 0.15,
                thickness: 8,
                padding: EdgeInsets.zero,
                child: Icon(
                  CupertinoIcons.chevron_left,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
              ),
              title: Text(
                "Help Center",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              largeTitlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
              largeTitle: Text(
                "Help Center",
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 34,
                ),
              ),
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
