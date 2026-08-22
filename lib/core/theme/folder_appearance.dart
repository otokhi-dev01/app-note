import 'package:flutter/cupertino.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:get/get.dart';

import 'package:Note/features/folder/domain/entities/folder.dart';

/// Renders a [Folder]'s stored `iconName` / `colorValue` as Flutter types.
///
/// This lives in the theme layer, not on the entity: the domain knows a folder
/// has an icon *name*, and only the UI knows what glyph that draws as.
extension FolderAppearanceX on Folder {
  bool get isEmojiIcon => FolderAppearance.isEmoji(iconName);

  IconData get icon => FolderAppearance.iconFor(iconName);

  Color get color => FolderAppearance.colorFor(colorValue);

  /// The name as it should be shown in the UI. The "Pii Cloud" / "Shared"
  /// section a folder lives in is encoded as a keyword baked into the raw
  /// [Folder.name] (the API has no dedicated field for it) — that keyword is
  /// an implementation detail the user should never see as literal text, so
  /// every screen that renders a folder's name shows this instead.
  String get displayName => FolderAppearance.displayName(name);
}

/// Renders a folder's stored icon: an [Icon] for a named glyph, or the raw
/// emoji character as text when [Folder.iconName] holds one instead.
class FolderGlyph extends StatelessWidget {
  final Folder folder;
  final double size;
  final Color? color;

  const FolderGlyph({
    super.key,
    required this.folder,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (folder.isEmojiIcon) {
      return Text(folder.iconName, style: TextStyle(fontSize: size, height: 1));
    }
    return Icon(folder.icon, color: color ?? folder.color, size: size);
  }
}

/// One pickable folder icon: the `iconName` persisted by the API, the glyph it
/// renders as, and the label shown under it in the picker.
class FolderIconOption {
  final String name;
  final IconData icon;

  /// Translation key for the label shown under this icon in the picker —
  /// resolve with `.tr` at display time, not stored pre-translated (this
  /// list is `const`, so it can't call `.tr` itself).
  final String label;

  const FolderIconOption(this.name, this.icon, this.label);
}

/// Shared catalog for the icon and color a folder can be given.
///
/// Both [FolderModel] and the folder picker UI read from here, so a stored
/// `iconName` / `colorValue` always resolves back to the same swatch it was
/// picked from.
class FolderAppearance {
  const FolderAppearance._();

  static const String defaultIconName = 'folder';
  static const String defaultColorValue = '#FF69B4';

  static const List<FolderIconOption> icons = [
    FolderIconOption('folder', CupertinoIcons.folder_fill, 'folder_icon_folder'),
    FolderIconOption('work', CupertinoIcons.briefcase_fill, 'folder_icon_work'),
    FolderIconOption('school', CupertinoIcons.book_fill, 'folder_icon_school'),
    FolderIconOption(
      'favorite',
      CupertinoIcons.heart_fill,
      'folder_icon_favorite',
    ),
    FolderIconOption('star', CupertinoIcons.star_fill, 'folder_icon_star'),
    FolderIconOption('note', CupertinoIcons.doc_text_fill, 'folder_icon_note'),
    FolderIconOption('home', CupertinoIcons.house_fill, 'folder_icon_home'),
    FolderIconOption('travel', CupertinoIcons.airplane, 'folder_icon_travel'),
    FolderIconOption(
      'idea',
      CupertinoIcons.lightbulb_fill,
      'folder_icon_idea',
    ),
    FolderIconOption(
      'money',
      CupertinoIcons.money_dollar_circle_fill,
      'folder_icon_money',
    ),
    FolderIconOption(
      'calendar',
      CupertinoIcons.calendar,
      'folder_icon_calendar',
    ),
    FolderIconOption('flag', CupertinoIcons.flag_fill, 'folder_icon_flag'),
    FolderIconOption('bolt', CupertinoIcons.bolt_fill, 'folder_icon_bolt'),
    FolderIconOption(
      'game',
      CupertinoIcons.game_controller_solid,
      'folder_icon_game',
    ),
    FolderIconOption('music', CupertinoIcons.music_note_2, 'folder_icon_music'),
    FolderIconOption('photo', CupertinoIcons.photo_fill, 'folder_icon_photo'),
    FolderIconOption(
      'cart',
      CupertinoIcons.cart_fill,
      'folder_icon_shopping',
    ),
    FolderIconOption('gift', CupertinoIcons.gift_fill, 'folder_icon_gift'),
    FolderIconOption(
      'code',
      CupertinoIcons.chevron_left_slash_chevron_right,
      'folder_icon_code',
    ),
    FolderIconOption(
      'people',
      CupertinoIcons.person_2_fill,
      'folder_icon_people',
    ),
  ];

  /// Emoji alternative to [icons] — the same 20 concepts, so switching
  /// between the two picker tabs doesn't lose the folder's "meaning".
  /// Stored verbatim as [Folder.iconName] when picked.
  static const List<String> emojis = [
    '📁',
    '💼',
    '🎓',
    '❤️',
    '⭐',
    '📝',
    '🏠',
    '✈️',
    '💡',
    '💰',
    '📅',
    '🚩',
    '⚡',
    '🎮',
    '🎵',
    '📷',
    '🛒',
    '🎁',
    '💻',
    '👥',
  ];

  static final EmojiParser _emojiParser = EmojiParser();

  /// `#FFB703` is kept in the palette because every folder created before the
  /// picker existed was saved with it — without it those folders would open the
  /// editor with no swatch selected.
  static const List<String> colors = [
    '#FF69B4',
    '#FF3B30',
    '#FF9500',
    '#FFB703',
    '#FFCC00',
    '#34C759',
    '#00C7BE',
    '#32ADE6',
    '#007AFF',
    '#5856D6',
    '#AF52DE',
    '#8E8E93',
  ];

  /// Icon names written by older builds that are no longer offered directly.
  static const Map<String, String> _legacyIconAliases = {'5': 'code'};

  /// Whether [name] is (or contains) an emoji character rather than one of
  /// the named [icons] keys — `flutter_emoji` does the actual detection.
  static bool isEmoji(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return false;
    return _emojiParser.hasEmoji(trimmed);
  }

  /// The section keyword ('iCloud' / 'Shared' / '') baked into [name] — the
  /// only place the API has to encode which sidebar section a folder is in.
  static String sectionKeywordOf(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('icloud')) return 'iCloud';
    if (lower.contains('shared')) return 'Shared';
    return '';
  }

  /// The display label for [sectionKeywordOf]'s return value.
  static String sectionLabel(String keyword) => switch (keyword) {
    'iCloud' => 'folder_section_icloud'.tr,
    'Shared' => 'folder_section_shared'.tr,
    _ => 'folder_on_my_iphone'.tr,
  };

  /// Strips the section/status keyword out of [name], leaving just the part
  /// meant to be shown to the user.
  static String stripSectionKeyword(String name) => name
      .replaceAll(RegExp(r'icloud', caseSensitive: false), '')
      .replaceAll(RegExp(r'shared', caseSensitive: false), '')
      .replaceAll(RegExp(r'pinned', caseSensitive: false), '')
      .replaceAll(RegExp(r'favorite', caseSensitive: false), '')
      .trim();

  /// The name as it should be shown anywhere in the UI — the section keyword
  /// is an internal storage convention, never something the user typed or
  /// should see as literal text.
  static String displayName(String name) {
    final stripped = stripSectionKeyword(name);
    return stripped.isEmpty ? name : stripped;
  }

  static IconData iconFor(String? name) {
    final key = (name ?? '').trim().toLowerCase();
    final resolved = _legacyIconAliases[key] ?? key;
    for (final option in icons) {
      if (option.name == resolved) return option.icon;
    }
    return CupertinoIcons.folder_fill;
  }

  static Color colorFor(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return parseHex(defaultColorValue);
    return parseHex(raw);
  }

  static Color parseHex(String value) {
    var hex = value.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse(hex, radix: 16) ?? 0xFFFF69B4);
  }

  /// Normalizes a stored value so it can be compared against [colors].
  static String normalizeColor(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return defaultColorValue;
    final hex = raw.replaceFirst('#', '').toUpperCase();
    return '#${hex.length == 8 ? hex.substring(2) : hex}';
  }

  static String normalizeIcon(String? name) {
    final raw = (name ?? '').trim();
    if (raw.isEmpty) return defaultIconName;
    if (isEmoji(raw)) return raw;
    final key = raw.toLowerCase();
    final resolved = _legacyIconAliases[key] ?? key;
    final known = icons.any((o) => o.name == resolved);
    return known ? resolved : defaultIconName;
  }
}
