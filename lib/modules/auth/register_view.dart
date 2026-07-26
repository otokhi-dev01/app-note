import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../app/theme/colors.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note_rounded, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join Modern Notes for seamless organization.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              
              // Full Name
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.fullNameController,
                decoration: const InputDecoration(
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 20),
              
              // Phone
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: const [
                        Text('+1 (US)'),
                        Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: controller.phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '555-0123',
                        prefixIcon: Icon(Icons.phone_iphone_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Password
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Obx(() => TextField(
                controller: controller.passwordController,
                obscureText: controller.obscurePassword.value,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value 
                        ? Icons.visibility_off_outlined 
                        : Icons.visibility_outlined,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ),
              )),
              const SizedBox(height: 20),
              
              // Device Name
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Device Name', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.deviceNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Work Laptop',
                  prefixIcon: Icon(Icons.devices_rounded),
                ),
              ),
              
              const SizedBox(height: 40),
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.register,
                child: controller.isLoading.value 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Register'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
              )),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
