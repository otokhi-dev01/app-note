import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Note/core/constants/app_constants.dart';

/// Handles E2EE key generation, local secure storage, and uploading the
/// PUBLIC halves to the server.
///
/// Identity Key Pair  -> Ed25519 (signing)
/// Signed Pre-Key Pair -> X25519 (ECDH), public bytes signed by the
/// identity key so a server-side MITM can't swap it undetected.
///
/// PRIVATE keys never leave the device — only *Public and the signature
/// are ever sent over the network.
class EncryptionService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: Duration(seconds: AppConstants.connectTimeoutSeconds),
    receiveTimeout: Duration(seconds: AppConstants.receiveTimeoutSeconds),
    headers: {'Content-Type': AppConstants.contentTypeJson},
  ));

  final FlutterSecureStorage _box;
  final Ed25519 _identityAlgo = Ed25519();
  final X25519 _preKeyAlgo = X25519();

  EncryptionService({FlutterSecureStorage? box})
      : _box = box ?? const FlutterSecureStorage();

  // ---- secure-storage key names, scoped per device ----
  String _idPrivKey(String deviceId) => 'e2ee_identity_priv_$deviceId';
  String _idPubKey(String deviceId) => 'e2ee_identity_pub_$deviceId';
  String _preKeyPrivKey(String deviceId) => 'e2ee_prekey_priv_$deviceId';
  String _preKeyPubKey(String deviceId) => 'e2ee_prekey_pub_$deviceId';
  String _preKeyIdKey(String deviceId) => 'e2ee_prekey_id_$deviceId';

  /// Call this once right after login/register succeeds.
  /// Idempotent — if keys already exist locally it does nothing.
  Future<void> initializeEncryption({
    required String userId,
    required String deviceId,
    required String accessToken,
  }) async {
    final existingIdentityPriv = await _box.read(key: _idPrivKey(deviceId));
    final existingPreKeyPriv = await _box.read(key: _preKeyPrivKey(deviceId));

    if (existingIdentityPriv != null && existingPreKeyPriv != null) {
      print('🔐 E2EE keys already exist for device $deviceId — skipping generation.');
      return;
    }

    print('🔐 No local E2EE keys found for device $deviceId — generating...');

    // ---- 1. Identity Key Pair (Ed25519) ----
    final identityKeyPair = await _identityAlgo.newKeyPair();
    final identityPublicKey = await identityKeyPair.extractPublicKey();
    final identityPrivateBytes = await identityKeyPair.extractPrivateKeyBytes();

    // ---- 2. Signed Pre-Key Pair (X25519) ----
    final preKeyPair = await _preKeyAlgo.newKeyPair();
    final preKeyPublicKey = await preKeyPair.extractPublicKey();
    final preKeyPrivateBytes = await preKeyPair.extractPrivateKeyBytes();

    // Sign the pre-key's public bytes with the identity private key.
    final signature = await _identityAlgo.sign(
      preKeyPublicKey.bytes,
      keyPair: identityKeyPair,
    );

    final identityPrivB64 = base64Encode(identityPrivateBytes);
    final identityPubB64 = base64Encode(identityPublicKey.bytes);
    final preKeyPrivB64 = base64Encode(preKeyPrivateBytes);
    final preKeyPubB64 = base64Encode(preKeyPublicKey.bytes);
    final signatureB64 = base64Encode(signature.bytes);

    // PRIVATE keys -> secure storage ONLY. Never sent to the server.
    await _box.write(key: _idPrivKey(deviceId), value: identityPrivB64);
    await _box.write(key: _idPubKey(deviceId), value: identityPubB64);
    await _box.write(key: _preKeyPrivKey(deviceId), value: preKeyPrivB64);
    await _box.write(key: _preKeyPubKey(deviceId), value: preKeyPubB64);
    await _box.write(key: _preKeyIdKey(deviceId), value: '0');

    print('🔑 Identity key pair (Ed25519) generated.');
    print('🔑 Signed pre-key pair (X25519) generated.');

    await _uploadIdentityKey(
      accessToken: accessToken,
      deviceId: deviceId,
      publicKeyB64: identityPubB64,
    );

    await _uploadPreKey(
      accessToken: accessToken,
      deviceId: deviceId,
      keyId: 0,
      publicKeyB64: preKeyPubB64,
    );

    print('✅ E2EE ready for device $deviceId.');
  }

  /// POST /api/encryption/identity-key
  Future<Map<String, dynamic>> _uploadIdentityKey({
    required String accessToken,
    required String deviceId,
    required String publicKeyB64,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.encryptionBaseUrl}${AppConstants.identityKeyEndpoint}',
        data: {
          'deviceId': deviceId,
          'publicKey': publicKeyB64,
          'keyVersion': 0,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print('📤 identity-key upload -> ${response.statusCode}: ${response.data}');
      return {'statusCode': response.statusCode, 'body': response.data};
    } on DioException catch (e) {
      print('❌ identity-key upload failed: ${e.response?.data ?? e.message}');
      return {
        'statusCode': e.response?.statusCode ?? -1,
        'body': e.response?.data ?? {'message': e.message},
      };
    }
  }

  /// POST /api/encryption/pre-keys
  Future<Map<String, dynamic>> _uploadPreKey({
    required String accessToken,
    required String deviceId,
    required int keyId,
    required String publicKeyB64,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.authBaseUrl}${AppConstants.preKeyEndpoint}',
        data: {
          'deviceId': deviceId,
          'keys': [
            {'keyId': keyId, 'publicKey': publicKeyB64},
          ],
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print('📤 pre-keys upload -> ${response.statusCode}: ${response.data}');
      return {'statusCode': response.statusCode, 'body': response.data};
    } on DioException catch (e) {
      print('❌ pre-keys upload failed: ${e.response?.data ?? e.message}');
      return {
        'statusCode': e.response?.statusCode ?? -1,
        'body': e.response?.data ?? {'message': e.message},
      };
    }
  }

  /// GET /api/encryption/bundle/{deviceId} — fetches a *target* device's
  /// public bundle, used in diagram "2. START A PRIVATE E2EE CHAT".
  Future<Map<String, dynamic>> getPublicBundle({
    required String accessToken,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.authBaseUrl}/encryption/bundle/$deviceId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return {'statusCode': response.statusCode, 'body': response.data};
    } on DioException catch (e) {
      return {
        'statusCode': e.response?.statusCode ?? -1,
        'body': e.response?.data ?? {'message': e.message},
      };
    }
  }

  /// Reads this device's own local public keys back out of secure storage
  /// (handy for showing "your device's fingerprint" in Settings, etc).
  Future<Map<String, String?>> getLocalPublicKeys(String deviceId) async {
    return {
      'identityPublicKey': await _box.read(key: _idPubKey(deviceId)),
      'signedPreKeyPublic': await _box.read(key: _preKeyPubKey(deviceId)),
    };
  }
}
