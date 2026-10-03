import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/features/auth/presentation/widgets/auth_success.dart';

/// The final signup step. Credentials have already been cleared by this point.
class RegistrationSuccess extends StatelessWidget {
  const RegistrationSuccess({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => AuthSuccess(
    title: 'register_verified_title'.tr,
    description: 'register_verified_description'.tr,
    onDone: onDone,
  );
}
