import 'package:flutter_test/flutter_test.dart';
import 'package:notes/presentation/modules/auth/login_view.dart';
import 'package:notes/presentation/modules/auth/signup_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('login ignores another submission while one is in progress', () async {
    final controller = LoginController();
    addTearDown(controller.onClose);
    controller.isLoading.value = true;

    await controller.login();

    expect(controller.isLoading.value, isTrue);
  });

  test('signup ignores another submission while one is in progress', () async {
    final controller = SignupController();
    addTearDown(controller.onClose);
    controller.isLoading.value = true;

    await controller.signup();

    expect(controller.isLoading.value, isTrue);
  });
}
