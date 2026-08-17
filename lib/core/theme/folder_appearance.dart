import 'package:flutter/cupertino.dart';

import 'package:Note/features/folder/domain/entities/folder.dart';

/// Renders a [Folder]'s stored `iconName` / `colorValue` as Flutter types.
///
/// This lives in the theme layer, not on the entity: the domain knows a folder
/// has an icon *name*, and only the UI knows what glyph that draws as.
extension FolderAppearanceX on Folder {
  IconData get icon => FolderAppearance.iconFor(iconName);

  Color get color => FolderAppearance.colorFor(colorValue);
}

/// One pickable folder icon: the `iconName` persisted by the API, the glyph it
/// renders as, and the label shown under it in the picker.
class FolderIconOption {
  final String name;
  final IconData icon;
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
    FolderIconOption('folder', CupertinoIcons.folder_fill, 'Folder'),
    FolderIconOption('work', CupertinoIcons.briefcase_fill, 'Work'),
    FolderIconOption('school', CupertinoIcons.book_fill, 'School'),
    FolderIconOption('favorite', CupertinoIcons.heart_fill, 'Favorite'),
    FolderIconOption('star', CupertinoIcons.star_fill, 'Star'),
    FolderIconOption('note', CupertinoIcons.doc_text_fill, 'Note'),
    FolderIconOption('home', CupertinoIcons.house_fill, 'Home'),
    FolderIconOption('travel', CupertinoIcons.airplane, 'Travel'),
    FolderIconOption('idea', CupertinoIcons.lightbulb_fill, 'Idea'),
    FolderIconOption('money', CupertinoIcons.money_dollar_circle_fill, 'Money'),
    FolderIconOption('calendar', CupertinoIcons.calendar, 'Calendar'),
    FolderIconOption('flag', CupertinoIcons.flag_fill, 'Flag'),
    FolderIconOption('bolt', CupertinoIcons.bolt_fill, 'Bolt'),
    FolderIconOption('game', CupertinoIcons.game_controller_solid, 'Game'),
    FolderIconOption('music', CupertinoIcons.music_note_2, 'Music'),
    FolderIconOption('photo', CupertinoIcons.photo_fill, 'Photo'),
    FolderIconOption('cart', CupertinoIcons.cart_fill, 'Shopping'),
    FolderIconOption('gift', CupertinoIcons.gift_fill, 'Gift'),
    FolderIconOption(
      'code',
      CupertinoIcons.chevron_left_slash_chevron_right,
      'Code',
    ),
    FolderIconOption('people', CupertinoIcons.person_2_fill, 'People'),
  ];

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
    final key = (name ?? '').trim().toLowerCase();
    if (key.isEmpty) return defaultIconName;
    final resolved = _legacyIconAliases[key] ?? key;
    final known = icons.any((o) => o.name == resolved);
    return known ? resolved : defaultIconName;
  }
}
