import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthPrimaryButtonWidget extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const AuthPrimaryButtonWidget({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 220),
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isLoading
              ? colorScheme.primary.withValues(
            alpha: 0.60,
          )
              : colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.18,
            ),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.primary.withValues(
                alpha: isLoading ? 0.12 : 0.30,
              ),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration:
            const Duration(milliseconds: 180),
            child: isLoading
                ? SizedBox(
              key:
              const ValueKey('loading'),
              width: 23,
              height: 23,
              child:
              CircularProgressIndicator
                  .adaptive(
                strokeWidth: 2.2,
                valueColor:
                AlwaysStoppedAnimation<
                    Color>(
                  colorScheme.onPrimary,
                ),
              ),
            )
                : Row(
              key: ValueKey<String>(label),
              mainAxisSize:
              MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: theme
                      .textTheme.titleMedium
                      ?.copyWith(
                    color:
                    colorScheme.onPrimary,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 9),
                Icon(
                  CupertinoIcons.arrow_right,
                  size: 18,
                  color:
                  colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}