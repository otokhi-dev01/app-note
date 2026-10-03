import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/features/auth/presentation/widgets/auth_success.dart';

/// The final signup step. Credentials have already been cleared by this point.
class RegistrationSuccess extends StatelessWidget {
  const RegistrationSuccess({
    super.key,
    required this.onDone,
    required this.emailVerified,
    this.account,
  });

  final VoidCallback onDone;
  final bool emailVerified;
  final String? account;

  @override
  Widget build(BuildContext context) => AuthSuccess(
    title:
        (emailVerified ? 'register_verified_title' : 'register_created_title')
            .tr,
    description: !emailVerified && account != null && account!.isNotEmpty
        ? 'register_created_description'.trParams({'account': account!})
        : 'register_verified_description'.tr,
    onDone: onDone,
  );
}
