import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../folders/data/repositories/folder_repository_impl.dart';
import '../../../folders/domain/repositories/folder_repository.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FolderRepository>()) {
      Get.put<FolderRepository>(
        FolderRepositoryImpl(
          apiClient: Get.find<ApiClient>(),
        ),
        permanent: true,
      );
    }
  }
}