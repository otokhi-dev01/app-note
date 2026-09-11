import 'package:Note/core/error/result.dart';
import 'package:Note/features/settings/domain/entities/account_device.dart';

abstract class DeviceRepository {
  Future<Result<List<AccountDevice>>> getDevices();
}
