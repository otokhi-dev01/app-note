# Fix "TextEditingController used after being disposed" Bug

I will fix the crash occurring during authentication transitions. This error happens because GetX disposes of the `LoginController` and its `TextEditingController`s immediately when navigating away using `Get.offAllNamed`, but the `TextField` widgets might still be active during the exit transition.

## User Review Required

> [!NOTE]
> I will be removing the explicit `dispose()` calls for `TextEditingController` in the `onClose()` method of `LoginController` and `RegisterController`. This is a known workaround for GetX race conditions during route transitions. Standard garbage collection will still reclaim the memory once the views are fully unmounted.

## Proposed Changes

### Auth Controllers

#### [MODIFY] [login_controller.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/auth/presentation/controller/login_controller.dart)
- Remove `phoneController.dispose()` and `passwordController.dispose()` from `onClose()`.

#### [MODIFY] [register_controller.dart](file:///Users/yornnona/Documents/flutter_app/app-note/lib/feature/auth/presentation/controller/register_controller.dart)
- Remove `phoneController.dispose()`, `passwordController.dispose()`, and `confirmPasswordController.dispose()` from `onClose()`.

## Verification Plan

### Manual Verification
- Navigate between Login and Register screens.
- Perform a successful login to trigger `Get.offAllNamed(AppRoutes.home)`.
- Perform a successful registration to trigger `Get.offAllNamed(AppRoutes.login)`.
- Verify that the "used after being disposed" exception no longer appears in the logs.
