import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/constants/app_constants.dart';

class StorageService extends GetxService {
  late GetStorage _storage;

  Future<StorageService> init() async {
    await GetStorage.init();
    _storage = GetStorage();
    return this;
  }

  void write(String key, dynamic value) => _storage.write(key, value);
  T? read<T>(String key) => _storage.read<T>(key);
  void remove(String key) => _storage.remove(key);
  void clear() => _storage.erase();

  String? get token => read<String>(AppConstants.tokenKey);
  set token(String? value) => write(AppConstants.tokenKey, value);

  bool get isFirstTime => read<bool>(AppConstants.isFirstTimeKey) ?? true;
  set isFirstTime(bool value) => write(AppConstants.isFirstTimeKey, value);

  String? get languageCode => read<String>(AppConstants.languageCodeKey);
  set languageCode(String? value) => write(AppConstants.languageCodeKey, value);

  String? get countryCode => read<String>(AppConstants.countryCodeKey);
  set countryCode(String? value) => write(AppConstants.countryCodeKey, value);
}
