import 'package:get/get.dart';

import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/storage/theme_storage.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:Note/features/profile/domain/repositories/profile_repository.dart';
import 'package:Note/features/profile/domain/usecases/profile_usecases.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileRepository>(
      () => ProfileRepositoryImpl(Get.find<SessionStorage>()),
      fenix: true,
    );
    Get.lazyPut(
      () => UpdateUserName(Get.find<ProfileRepository>()),
      fenix: true,
    );
    Get.lazyPut(
      () => UpdateProfileImage(Get.find<ProfileRepository>()),
      fenix: true,
    );
    Get.lazyPut(() => ThemeStorage(), fenix: true);

    Get.put(
      ProfileController(
        updateUserName: Get.find<UpdateUserName>(),
        updateProfileImage: Get.find<UpdateProfileImage>(),
        logout: Get.find<Logout>(),
        profile: Get.find<ProfileRepository>(),
        theme: Get.find<ThemeStorage>(),
      ),
    );
  }
}
