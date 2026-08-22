import 'package:get/get.dart';

import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/settings/presentation/controllers/account_controller.dart';

class AccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      AccountController(
        logout: Get.find<Logout>(),
        deleteAccount: Get.find<DeleteAccount>(),
        guestMode: Get.find<GuestModeService>(),
      ),
    );
  }
}
