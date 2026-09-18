import 'package:get/get.dart';
import 'package:Note/features/profile/data/datasources/identity_remote_data_source.dart';
import 'package:Note/features/profile/data/repositories/identity_repository_impl.dart';
import 'package:Note/features/profile/domain/repositories/identity_repository.dart';
import 'package:Note/features/profile/domain/usecases/identity_usecases.dart';
import 'package:Note/features/profile/presentation/controllers/identity_scan_controller.dart';

class IdentityScanBinding extends Bindings {
  @override
  void dependencies() {
    // IdentityRemoteDataSource itself is registered once, globally, in
    // InitialBinding (see lib/core/di/injector.dart) — same as
    // UserRemoteDataSource.
    Get.lazyPut<IdentityRepository>(
      () => IdentityRepositoryImpl(Get.find<IdentityRemoteDataSource>()),
    );
    Get.lazyPut(() => ScanNationalId(Get.find<IdentityRepository>()));
    Get.lazyPut(() => UploadIdentityDocument(Get.find<IdentityRepository>()));
    Get.lazyPut(() => IdentityScanController(Get.find<ScanNationalId>()));
  }
}
