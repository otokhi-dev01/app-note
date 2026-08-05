import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import 'auth_controller.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark 
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent) 
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Column(
            children: [
              // Sticky Top Bar Actions (Matching Folder Style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    LiquidGlassContainer(
                      width: 44,
                      height: 44,
                      borderRadius: 22,
                      child: IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(
                          Icons.chevron_left, 
                          color: theme.colorScheme.onSurfaceVariant, 
                          size: 30,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Large Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 18),
                        child: Text(
                          "Register",
                          style: theme.textTheme.headlineLarge?.copyWith(fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.black26 : Colors.black12, 
                                    blurRadius: 10, 
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                                child: Icon(Icons.note_alt, color: AppTheme.folderYellow, size: 68)
                            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                            
                            const SizedBox(height: 32),

                            Text(
                              "Create Account",
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 30),
                            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              "Sign up to get started",
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18),
                            ).animate().fadeIn(delay: 100.ms),
                            
                            const SizedBox(height: 40),
                            
                            // Register Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildTextField(
                                    context,
                                    controller: controller.nameController,
                                    hint: "Full Name",
                                    icon: FontAwesomeIcons.user,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    context,
                                    controller: controller.phoneController,
                                    hint: "Phone Number",
                                    icon: FontAwesomeIcons.phone,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    context,
                                    controller: controller.passwordController,
                                    hint: "Password",
                                    icon: FontAwesomeIcons.lock,
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  Obx(() => SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: controller.isLoading.value ? null : controller.register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.folderYellow,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: controller.isLoading.value 
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : const Text("REGISTER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                    ),
                                  )),
                                ],
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                            
                            const SizedBox(height: 28),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account?",
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 15),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(),
                                  style: TextButton.styleFrom(foregroundColor: AppTheme.folderYellow, padding: const EdgeInsets.symmetric(horizontal: 5)),
                                  child: Text(
                                    "Login",
                                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.folderYellow, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 600.ms),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required dynamic icon,
    bool isPassword = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          prefixIcon: icon is IconData 
              ? Icon(icon, color: theme.colorScheme.onSurfaceVariant)
              : Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: FaIcon(icon, color: theme.colorScheme.onSurfaceVariant, size: 18),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
