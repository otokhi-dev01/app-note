import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/shared/widgets/glass_widgets.dart';

/// Shared full-screen shell for every profile editor.
class ProfileEditScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const ProfileEditScreen({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          slivers: [
            AppScreenSliverAppBar(
              centerTitle: true,
              leading: CustomGlassButton(
                semanticLabel: MaterialLocalizations.of(
                  context,
                ).backButtonTooltip,
                onPressed: () => Get.back(),
                width: 44,
                height: 44,
                shape: GlassShape.circle,
                blur: 10,
                opacity: 0.15,
                thickness: 8,
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.chevron_left, size: 23),
              ),
              title: title,
            ),
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: CustomGlassContainer(
                      width: double.infinity,
                      borderRadius: 24,
                      blur: 20,
                      opacity: 0.12,
                      thickness: 8,
                      clipBehavior: Clip.antiAlias,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDatePickerScreen extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const ProfileDatePickerScreen({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<ProfileDatePickerScreen> createState() =>
      _ProfileDatePickerScreenState();
}

class _ProfileDatePickerScreenState extends State<ProfileDatePickerScreen> {
  late DateTime _selectedDate = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    return ProfileEditScreen(
      title: 'date_of_birth_label'.tr,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CalendarDatePicker(
              initialDate: widget.initialDate,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              onDateChanged: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 18),
            CustomGlassButton(
              semanticLabel: 'done_action'.tr,
              onPressed: () => Get.back(result: _selectedDate),
              minHeight: 50,
              borderRadius: 18,
              glassColor: const Color(0xFF007AFF).withValues(alpha: 0.88),
              foregroundColor: Colors.white,
              child: Text(
                'done_action'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
