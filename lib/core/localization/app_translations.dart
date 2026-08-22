import 'package:get/get.dart';

import 'package:Note/core/localization/en_us.dart';
import 'package:Note/core/localization/km_kh.dart';

/// GetX's built-in i18n: `'key'.tr` resolves against whichever locale is
/// active. Covers every screen in the app; a handful of proper nouns and
/// hardcoded data values (e.g. the app name, a stored join date) are
/// intentionally left as literals rather than translated.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'en_US': enUS, 'km_KH': kmKH};
}
