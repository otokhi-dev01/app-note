class AccountDevice {
  final String id;
  final String clientDeviceId;
  final String name;
  final String platform;
  final String model;
  final String appVersion;
  final bool isCurrent;

  const AccountDevice({
    required this.id,
    this.clientDeviceId = '',
    this.name = '',
    this.platform = '',
    this.model = '',
    this.appVersion = '',
    this.isCurrent = false,
  });
}
