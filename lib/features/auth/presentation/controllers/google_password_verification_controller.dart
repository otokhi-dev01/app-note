import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/features/auth/data/services/google_sign_in_service.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';

/// Acquires a Google ID token and exchanges it for a password-reset proof.
/// Neither token is stored here; this flow never creates an app login session.
class GooglePasswordVerificationController extends GetxController {
  GooglePasswordVerificationController({
    required VerifyPasswordGoogle verify,
    GoogleSignInService? googleSignIn,
  }) : _verify = verify,
       _googleSignIn = googleSignIn ?? GoogleSignInService();

  final VerifyPasswordGoogle _verify;
  final GoogleSignInService _googleSignIn;
  final isLoading = false.obs;

  /// Null means cancellation, a duplicate call, or a closed screen.
  Future<Result<String>?> verify() async {
    if (isLoading.value || isClosed) return null;
    isLoading.value = true;
    try {
      final idToken = await _googleSignIn.signInIdToken();
      if (isClosed || idToken == null) return null;
      final result = await _verify(
        VerifyPasswordGoogleParams(idToken: idToken),
      );
      if (isClosed) return null;
      return result;
    } on PlatformException catch (error) {
      if (isClosed || error.code == 'sign_in_canceled') return null;
      return Err(
        ValidationFailure(
          (error.code == 'google_not_configured'
                  ? 'google_verification_unavailable'
                  : 'google_verification_failed')
              .tr,
        ),
      );
    } catch (_) {
      if (isClosed) return null;
      return Err(UnknownFailure('google_verification_failed'.tr));
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }
}
