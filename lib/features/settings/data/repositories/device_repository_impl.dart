import 'package:Note/core/error/guard.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/features/settings/data/datasources/device_remote_data_source.dart';
import 'package:Note/features/settings/domain/entities/account_device.dart';
import 'package:Note/features/settings/domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource _remote;

  const DeviceRepositoryImpl(this._remote);

  @override
  Future<Result<List<AccountDevice>>> getDevices() => guard(_remote.getDevices);
}
