import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A compact refresh action with optional progress and haptic feedback.
class AppRefreshButton extends StatelessWidget {
  const AppRefreshButton({
    required this.semanticsLabel,
    required this.onPressed,
    this.isLoading = false,
    this.enableHaptics = false,
    super.key,
  });

  final String semanticsLabel;
  final Future<void> Function() onPressed;
  final bool isLoading;
  final bool enableHaptics;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      enabled: !isLoading,
      label: semanticsLabel,
      child: SizedBox(
        width: 38,
        height: 38,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          pressedOpacity: 0.45,
          onPressed: isLoading ? null : _handlePressed,
          child: isLoading
              ? CupertinoActivityIndicator(radius: 9, color: primaryColor)
              : Icon(CupertinoIcons.refresh, size: 21, color: primaryColor),
        ),
      ),
    );
  }

  void _handlePressed() {
    if (enableHaptics) {
      HapticFeedback.selectionClick();
    }

    onPressed();
  }
}
