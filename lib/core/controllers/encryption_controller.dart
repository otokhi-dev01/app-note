import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:Note/core/services/encryption_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/services/auth_device_service.dart';

class EncryptionController extends GetxController {
  final EncryptionService _encryptionService = EncryptionService();
  final _sessionStorage = Get.find<SessionStorage>();
  final _deviceService = AuthDeviceService();

  var isInitializing = false.obs;
  var isReady = false.obs;

  // Coalesces concurrent callers (e.g. the token listener firing at the same
  // moment login() calls this explicitly) into a single in-flight setup, so
  // we never generate/upload two different key pairs for the same device.
  Future<void>? _setupFuture;

  @override
  void onInit() {
    super.onInit();
    // Auto-setup when user changes or session token becomes available
    ever(_sessionStorage.token, (token) {
      if (token != null && token.isNotEmpty) {
        setupForCurrentUser();
      }
    });
    if (_sessionStorage.isLoggedIn) {
      setupForCurrentUser();
    }
  }

  /// Call right after a successful login/register or when a session is active.
  /// Safe to call multiple times concurrently — overlapping calls share the
  /// same in-flight setup instead of racing separate key uploads.
  Future<void> setupForCurrentUser() {
    return _setupFuture ??= _setup().whenComplete(() => _setupFuture = null);
  }

  Future<void> _setup() async {
    final user = _sessionStorage.user.value;
    final token = _sessionStorage.token.value;
    final device = await _deviceService.read();

    if (user == null || token == null || token.isEmpty) {
      print('⚠️ Cannot initialize E2EE — missing user or token.');
      return;
    }

    isInitializing.value = true;
    try {
      await _encryptionService.initializeEncryption(
        userId: user.id ?? 'unknown',
        deviceId: device.clientDeviceId,
        accessToken: token,
      );
      isReady.value = true;
    } catch (e) {
      print('❌ E2EE initialization failed: $e');
      isReady.value = false;
    } finally {
      isInitializing.value = false;
    }
  }

  Future<Map<String, String?>> myPublicKeys() async {
    final device = await _deviceService.read();
    return _encryptionService.getLocalPublicKeys(device.clientDeviceId);
  }
}
