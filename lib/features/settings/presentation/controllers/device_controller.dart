import 'dart:async';

import 'package:get/get.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/settings/domain/entities/account_device.dart';
import 'package:Note/features/settings/domain/usecases/get_devices.dart';

class DeviceController extends GetxController {
  final GetDevices _getDevices;
  final SessionStorage _session;
  final GuestModeService _guestMode;
  final String _clientDeviceId;
  final devices = <AccountDevice>[].obs;
  final isLoading = false.obs;
  final error = RxnString();
  final List<Worker> _workers = [];
  int _request = 0;

  DeviceController({
    required GetDevices getDevices,
    required SessionStorage session,
    required GuestModeService guestMode,
    String clientDeviceId = '',
  }) : _getDevices = getDevices,
       _session = session,
       _guestMode = guestMode,
       _clientDeviceId = clientDeviceId;

  bool get canLoad => _session.isLoggedIn && !_guestMode.isGuestMode.value;

  bool isCurrent(AccountDevice device) =>
      device.isCurrent ||
      (_clientDeviceId.isNotEmpty &&
          device.clientDeviceId.toLowerCase() == _clientDeviceId.toLowerCase());

  @override
  void onInit() {
    super.onInit();
    _workers.add(ever(_session.token, (_) => unawaited(load())));
    _workers.add(ever(_guestMode.isGuestMode, (_) => unawaited(load())));
    unawaited(load());
  }

  Future<void> load() async {
    final request = ++_request;
    devices.clear();
    error.value = null;
    isLoading.value = canLoad;
    if (!canLoad) return;
    final result = await _getDevices(const NoParams());
    if (isClosed || request != _request) return;
    switch (result) {
      case Ok(:final value):
        devices.assignAll(value);
      case Err(:final failure):
        error.value = failure.message;
    }
    isLoading.value = false;
  }

  @override
  void onClose() {
    _request++;
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }
}
