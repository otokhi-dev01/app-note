import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

class AuthDeviceInfo {
  final String clientDeviceId;
  final String appVersion;
  final String deviceName;
  final String platform;
  final String deviceModel;

  const AuthDeviceInfo({
    required this.clientDeviceId,
    required this.appVersion,
    required this.deviceName,
    required this.platform,
    required this.deviceModel,
  });
}

/// Identifies this app installation without using a hardware identifier.
class AuthDeviceService {
  final GetStorage _storage;
  final Future<PackageInfo> Function() _packageInfo;
  final Future<BaseDeviceInfo> Function() _deviceInfo;

  AuthDeviceService({
    GetStorage? storage,
    Future<PackageInfo> Function()? packageInfo,
    Future<BaseDeviceInfo> Function()? deviceInfo,
  }) : _storage = storage ?? GetStorage(),
       _packageInfo = packageInfo ?? PackageInfo.fromPlatform,
       _deviceInfo = deviceInfo ?? (() => DeviceInfoPlugin().deviceInfo);

  Future<AuthDeviceInfo> read() async {
    const key = 'auth_client_device_id';
    var id = _storage.read<String>(key);
    if (id == null || !Uuid.isValidUUID(fromString: id)) {
      id = const Uuid().v4();
      // Session logout only clears secure token storage, so this ID survives it.
      await _storage.write(key, id);
    }

    var appVersion = '';
    try {
      appVersion = (await _packageInfo()).version;
    } catch (error) {
      // Optional metadata must not block credentials when a native plugin is
      // unavailable (for example, after hot reload adds a new plugin).
      debugPrint('[AUTH] App version unavailable: ${error.runtimeType}');
    }
    BaseDeviceInfo? device;
    try {
      device = await _deviceInfo();
    } catch (error) {
      debugPrint('[AUTH] Device details unavailable: ${error.runtimeType}');
    }
    final (name, platform, model) = switch (device) {
      IosDeviceInfo info => (info.name, 'iOS', info.utsname.machine),
      AndroidDeviceInfo info => (
        '${info.manufacturer} ${info.model}'.trim(),
        'Android',
        info.model,
      ),
      MacOsDeviceInfo info => (info.computerName, 'macOS', info.model),
      WindowsDeviceInfo info => (
        info.computerName,
        'Windows',
        info.productName,
      ),
      LinuxDeviceInfo info => (info.name, 'Linux', info.prettyName),
      WebBrowserInfo info => (
        info.browserName.name,
        'Web',
        info.platform ?? '',
      ),
      _ => (
        '',
        switch (defaultTargetPlatform) {
          TargetPlatform.iOS => 'iOS',
          TargetPlatform.android => 'Android',
          TargetPlatform.macOS => 'macOS',
          TargetPlatform.windows => 'Windows',
          TargetPlatform.linux => 'Linux',
          TargetPlatform.fuchsia => 'Fuchsia',
        },
        '',
      ),
    };
    return AuthDeviceInfo(
      clientDeviceId: id,
      appVersion: appVersion,
      deviceName: name,
      platform: platform,
      deviceModel: model,
    );
  }
}
