import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/settings/data/datasources/device_remote_data_source.dart';
import 'package:Note/features/settings/data/repositories/device_repository_impl.dart';
import 'package:Note/features/settings/domain/repositories/device_repository.dart';
import 'package:Note/features/settings/domain/usecases/get_devices.dart';
import 'package:Note/features/settings/presentation/controllers/device_controller.dart';

class DeviceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DeviceRemoteDataSource(Get.find<ApiClient>()));
    Get.lazyPut<DeviceRepository>(
      () => DeviceRepositoryImpl(Get.find<DeviceRemoteDataSource>()),
    );
    Get.lazyPut(() => GetDevices(Get.find<DeviceRepository>()));
    Get.put(
      DeviceController(
        getDevices: Get.find<GetDevices>(),
        session: Get.find<SessionStorage>(),
        guestMode: Get.find<GuestModeService>(),
        clientDeviceId:
            GetStorage().read<String>('auth_client_device_id') ?? '',
      ),
    );
  }
}
