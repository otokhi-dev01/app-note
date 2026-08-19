import 'package:get/get.dart';

import 'en_us.dart';
import 'km_kh.dart';

/// GetX's built-in i18n: `'key'.tr` resolves against whichever locale is
/// active. Only Splash/Onboarding/Login/Register are translated today —
/// every other screen's hardcoded English text falls through untouched.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'en_US': enUS, 'km_KH': kmKH};
}
