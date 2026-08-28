import 'package:get_storage/get_storage.dart';

/// Profile fields the backend's user model has no columns for yet — only
/// `fullName`, `phone`, and `profileImage` round-trip through the API today,
/// so username/account/email/job/bio/color live on-device only. Real and
/// persistent (survives restarts), just not synced across devices or to a
/// signed-in session on another install.
class ProfileExtrasStorage {
  static const _keyUsername = 'profile_extra_username';
  static const _keyAccount = 'profile_extra_account';
  static const _keyEmail = 'profile_extra_email';
  static const _keyJob = 'profile_extra_job';
  static const _keyBio = 'profile_extra_bio';
  static const _keyColorHex = 'profile_extra_color_hex';

  final _storage = GetStorage();

  String get username => _storage.read<String>(_keyUsername) ?? '';
  set username(String value) => _storage.write(_keyUsername, value);

  String get account => _storage.read<String>(_keyAccount) ?? '';
  set account(String value) => _storage.write(_keyAccount, value);

  String get email => _storage.read<String>(_keyEmail) ?? '';
  set email(String value) => _storage.write(_keyEmail, value);

  String get job => _storage.read<String>(_keyJob) ?? '';
  set job(String value) => _storage.write(_keyJob, value);

  String get bio => _storage.read<String>(_keyBio) ?? '';
  set bio(String value) => _storage.write(_keyBio, value);

  String? get colorHex => _storage.read<String>(_keyColorHex);
  set colorHex(String? value) {
    if (value == null || value.isEmpty) {
      _storage.remove(_keyColorHex);
    } else {
      _storage.write(_keyColorHex, value);
    }
  }
}
