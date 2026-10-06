import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:Note/core/storage/app_media_storage.dart';
import 'package:Note/core/storage/id_information_storage.dart';

/// Removes only the deleted account's local records; other accounts and guests
/// keep their data.
abstract final class AccountDataStorage {
  static Future<void> delete(String accountId) async {
    final storage = GetStorage();
    final encoded = base64Url.encode(utf8.encode(accountId));
    final keys = <String>{
      for (final prefix in [
        'account_notes_cache',
        'account_notes_queue',
        'account_notes_next_id',
        'account_notes_next_attachment_id',
        'account_folders_cache',
        'account_folders_queue',
        'account_folders_next_id',
        'account_folders_temp_map',
      ])
        '${prefix}_$accountId',
      for (final field in [
        'username',
        'account',
        'email',
        'job',
        'bio',
        'color_hex',
        'high_school',
        'first_child_name',
        'father_name',
        'mother_name',
        'phone',
        'favorite_color_q',
        'favorite_song_q',
        'favorite_food_q',
        'profile_image',
      ])
        'profile_extra_${field}_$encoded',
      'daily_notes_v1_account_$accountId',
    };
    await const IdInformationStorage().delete('id:$accountId');
    await AppMediaStorage.deleteFolderIfManaged(
      folder: 'account_attachments_pending/$encoded',
    );
    await AppMediaStorage.deleteFolderIfManaged(
      folder: 'daily_note_photos/${Uri.encodeComponent('account_$accountId')}',
    );
    for (final key in keys) {
      await storage.remove(key);
    }
  }
}
