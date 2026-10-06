import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/storage/guest_mode_service.dart';

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
  ProfileExtrasStorage({SessionStorage? session}) : _session = session;

  final SessionStorage? _session;

  String _key(String key) {
    final session =
        _session ??
        (Get.isRegistered<SessionStorage>()
            ? Get.find<SessionStorage>()
            : null);
    final guest =
        Get.isRegistered<GuestModeService>() &&
        Get.find<GuestModeService>().isGuestMode.value;
    final owner = guest ? null : session?.user.value?.id;
    final encoded = base64Url.encode(utf8.encode(owner ?? 'guest'));
    return '${key}_$encoded';
  }

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
  static const _keyPhone = 'profile_extra_phone';
  static const _keyFavoriteColor = 'profile_extra_favorite_color_q';
  static const _keyFavoriteSong = 'profile_extra_favorite_song_q';
  static const _keyFavoriteFood = 'profile_extra_favorite_food_q';
  static const _keyProfileImage = 'profile_extra_profile_image';

  final _storage = GetStorage();

  String get profileImagePath =>
      _storage.read<String>(_key(_keyProfileImage)) ?? '';
  set profileImagePath(String value) =>
      _storage.write(_key(_keyProfileImage), value);

  String get username => _storage.read<String>(_key(_keyUsername)) ?? '';
  set username(String value) => _storage.write(_key(_keyUsername), value);

  String get account => _storage.read<String>(_key(_keyAccount)) ?? '';
  set account(String value) => _storage.write(_key(_keyAccount), value);

  String get email => _storage.read<String>(_key(_keyEmail)) ?? '';
  set email(String value) => _storage.write(_key(_keyEmail), value);

  String get job => _storage.read<String>(_key(_keyJob)) ?? '';
  set job(String value) => _storage.write(_key(_keyJob), value);

  String get bio => _storage.read<String>(_key(_keyBio)) ?? '';
  set bio(String value) => _storage.write(_key(_keyBio), value);

  String? get colorHex => _storage.read<String>(_key(_keyColorHex));
  set colorHex(String? value) {
    if (value == null || value.isEmpty) {
      _storage.remove(_key(_keyColorHex));
    } else {
      _storage.write(_key(_keyColorHex), value);
    }
  }

  String get guestName => _storage.read<String>(_keyGuestName) ?? '';
  set guestName(String value) => _storage.write(_keyGuestName, value);

  /// Relative path under the app documents directory, same convention as a
  /// signed-in user's `profileImage` — see `AppMediaStorage`.
  String get guestImagePath => _storage.read<String>(_keyGuestImage) ?? '';
  set guestImagePath(String value) => _storage.write(_keyGuestImage, value);

  String get phone => _storage.read<String>(_key(_keyPhone)) ?? '';
  set phone(String value) => _storage.write(_key(_keyPhone), value);

  String get highSchool => _storage.read<String>(_key(_keyHighSchool)) ?? '';
  set highSchool(String value) => _storage.write(_key(_keyHighSchool), value);

  String get firstChildName =>
      _storage.read<String>(_key(_keyFirstChildName)) ?? '';
  set firstChildName(String value) =>
      _storage.write(_key(_keyFirstChildName), value);

  String get fatherName => _storage.read<String>(_key(_keyFatherName)) ?? '';
  set fatherName(String value) => _storage.write(_key(_keyFatherName), value);

  String get motherName => _storage.read<String>(_key(_keyMotherName)) ?? '';
  set motherName(String value) => _storage.write(_key(_keyMotherName), value);

  String get favoriteColor =>
      _storage.read<String>(_key(_keyFavoriteColor)) ?? '';
  set favoriteColor(String value) =>
      _storage.write(_key(_keyFavoriteColor), value);

  String get favoriteSong =>
      _storage.read<String>(_key(_keyFavoriteSong)) ?? '';
  set favoriteSong(String value) =>
      _storage.write(_key(_keyFavoriteSong), value);

  String get favoriteFood =>
      _storage.read<String>(_key(_keyFavoriteFood)) ?? '';
  set favoriteFood(String value) =>
      _storage.write(_key(_keyFavoriteFood), value);
}
