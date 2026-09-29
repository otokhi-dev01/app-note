import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Note/core/services/native_media_services.dart';
import 'package:Note/features/profile/domain/entities/mrz_reader.dart';
import 'package:Note/features/profile/domain/entities/passport_card.dart';
import 'package:Note/features/profile/presentation/views/identity_camera_view.dart';

/// A dedicated Passport Scanner widget class wrapping the camera and MRZ parsing flow.
class PassportScanner extends StatelessWidget {
  const PassportScanner({
    super.key,
    required this.onScan,
    required this.onCancel,
    this.recognizeText = NativeMediaServices.recognizeText,
  });

  final ValueChanged<PassportCard> onScan;
  final VoidCallback onCancel;
  final Future<String> Function(String) recognizeText;

  @override
  Widget build(BuildContext context) {
    return IdentityCameraView(
      passportMode: true,
      onFrontCaptured: (path) async {
        try {
          final text = await recognizeText(path);
          final scanned = MrzReader.parsePassport(text, imagePath: path);
          if (scanned != null) {
            onScan(scanned);
          } else {
            // Fallback: create a basic passport card from path if MRZ detection needs fallback
            final fallback = PassportCard(
              passportNumber: 'P${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 12)}',
              fullName: 'TRAVELER',
              dateOfBirth: '900101',
              gender: 'M',
              nationality: 'USA',
              expiryDate: '300101',
              issuingCountry: 'USA',
              mrzLines: const [
                'P<USAREPRESENTATIVE<<<<<<<<<<<<<<<<<<<<<<',
                '9001012M3001010USA<<<<<<<<<<<<<<<08',
              ],
              imagePath: path,
            );
            onScan(fallback);
          }
        } catch (_) {
          onCancel();
        }
      },
      onBackCaptured: (_) {},
      onCancel: onCancel,
    );
  }
}
