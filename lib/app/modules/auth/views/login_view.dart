import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              expandedHeight: 100.0,
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: true,
              systemOverlayStyle: theme.brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final double percentage =
                      (constraints.maxHeight - kToolbarHeight) /
                      (140.0 - kToolbarHeight);
                  final opacity = (1.0 - percentage).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity > 0.8 ? 1.0 : 0.0,
                    child: Text(
                      "Login",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                  );
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.fromLTRB(25, 0, 16, 12),
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    final double percentage =
                        (constraints.maxHeight - kToolbarHeight) /
                        (140.0 - kToolbarHeight);
                    return Opacity(
                      opacity: percentage.clamp(0.0, 1.0),
                      child: Text(
                        "Login",
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/icons/otokhi_logo_cover.jpg',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(height: 32),
                    Text(
                          "Welcome Back",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      "Login to your account",
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 15),
                    // Login Card
                    LiquidGlassContainer(
                      borderRadius: 30,
                      blur: 35,
                      opacity: 0.1,
                      thickness: 15,
                      showGlow: true,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: theme.dividerColor.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              _buildTextField(
                                context,
                                controller: controller.phoneController,
                                hint: "Phone Number",
                                icon: FontAwesomeIcons.phone,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 20),
                              Obx(() => _buildTextField(
                                  context,
                                  controller: controller.passwordController,
                                  hint: "Password",
                                  icon: FontAwesomeIcons.lock,
                                  isPassword:
                                      !controller.isPasswordVisible.value,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      controller.isPasswordVisible.value
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    onPressed:
                                        controller.togglePasswordVisibility,
                                  ),
                                )),
                            const SizedBox(height: 20), const Divider(height: 1),
                            Row(
                              children: [
                                Obx(() => Checkbox(
                                      value: controller.rememberMe.value,
                                      onChanged: (_) =>
                                          controller.toggleRememberMe(),
                                      activeColor: AppTheme.folderPink,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    )),
                                GestureDetector(
                                  onTap: controller.toggleRememberMe,
                                  child: Text(
                                    "Remember Me",
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: controller.forgotPassword,
                                  child: const Text(
                                    "Forgot Password\?",
                                    style:
                                        TextStyle(color: AppTheme.folderPink),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Obx(
                              () => SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : controller.login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.folderPink,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: controller.isLoading.value
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "LOGIN",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.toNamed(Routes.REGISTER),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.folderPink,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                          ),
                          child: Text(
                            "Register",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.folderPink,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: icon is IconData
              ? Icon(icon, color: theme.colorScheme.onSurfaceVariant)
              : Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: FaIcon(
                    icon,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
