import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// Shared floating profile popup matching the app's Languages glass menu.
class ProfileGlassPopup extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ProfileGlassPopup({
    super.key,
    required this.child,
    this.maxWidth = 360,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double maxWidth = 360,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, _) =>
          ProfileGlassPopup(maxWidth: maxWidth, child: builder(context)),
      transitionBuilder: (context, animation, _, child) {
        final entrance = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: entrance,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(entrance),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: lg.GlassCard(
        useOwnLayer: true,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: const lg.LiquidRoundedSuperellipse(borderRadius: 32),
        settings: const lg.LiquidGlassSettings(
          blur: 10,
          thickness: 10,
          glassColor: Color.fromRGBO(255, 255, 255, 0.12),
          lightAngle: lg.GlassDefaults.lightAngle,
          lightIntensity: 0.7,
          ambientStrength: 0.4,
          saturation: 1.2,
          refractiveIndex: 0.7,
          chromaticAberration: 0,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
