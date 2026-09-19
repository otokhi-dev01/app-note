import 'package:get_storage/get_storage.dart';

/// Profile fields the backend's user model has no columns for yet — only
/// `fullName`, `phone`, and `profileImage` round-trip through the API today,
/// so username/account/email/job/bio/color live on-device only. Real and
/// persistent (survives restarts), just not synced across devices or to a
/// signed-in session on another install.
///
/// Also holds the guest identity (name + avatar): a signed-in account's
/// `fullName`/`profileImage` already live only on-device too (see
/// `ProfileRepositoryImpl` — the real update endpoint 404s), so a "Continue
/// without account" guest gets the same on-device-only editing rather than
/// being blocked from setting a name or photo entirely.
class ProfileExtrasStorage {
  static const _keyUsername = 'profile_extra_username';
  static const _keyAccount = 'profile_extra_account';
  static const _keyEmail = 'profile_extra_email';
  static const _keyJob = 'profile_extra_job';
  static const _keyBio = 'profile_extra_bio';
  static const _keyColorHex = 'profile_extra_color_hex';
  static const _keyGuestName = 'profile_extra_guest_name';
  static const _keyGuestImage = 'profile_extra_guest_image';
  static const _keyHighSchool = 'profile_extra_high_school';
  static const _keyFirstChildName = 'profile_extra_first_child_name';
  static const _keyFatherName = 'profile_extra_father_name';
  static const _keyMotherName = 'profile_extra_mother_name';

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

  String get guestName => _storage.read<String>(_keyGuestName) ?? '';
  set guestName(String value) => _storage.write(_keyGuestName, value);

  /// Relative path under the app documents directory, same convention as a
  /// signed-in user's `profileImage` — see `AppMediaStorage`.
  String get guestImagePath => _storage.read<String>(_keyGuestImage) ?? '';
  set guestImagePath(String value) => _storage.write(_keyGuestImage, value);

  String get highSchool => _storage.read<String>(_keyHighSchool) ?? '';
  set highSchool(String value) => _storage.write(_keyHighSchool, value);

  String get firstChildName =>
      _storage.read<String>(_keyFirstChildName) ?? '';
  set firstChildName(String value) =>
      _storage.write(_keyFirstChildName, value);

  String get fatherName => _storage.read<String>(_keyFatherName) ?? '';
  set fatherName(String value) => _storage.write(_keyFatherName, value);

  String get motherName => _storage.read<String>(_keyMotherName) ?? '';
  set motherName(String value) => _storage.write(_keyMotherName, value);
}
