import 'package:Note/core/error/result.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/settings/domain/entities/account_device.dart';
import 'package:Note/features/settings/domain/repositories/device_repository.dart';

class GetDevices extends UseCase<List<AccountDevice>, NoParams> {
  final DeviceRepository _repository;

  const GetDevices(this._repository);

  @override
  Future<Result<List<AccountDevice>>> call(NoParams params) =>
      _repository.getDevices();
}
