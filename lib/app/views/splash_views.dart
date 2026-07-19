import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controllers.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.note_alt_rounded,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Piisiit Note',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.errorMessage.value.isEmpty) {
                  return const Text('Starting application...');
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.error,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}