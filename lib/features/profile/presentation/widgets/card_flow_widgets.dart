import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Note/features/profile/domain/entities/credit_card.dart';

const cardFlowInk = Color(0xFF151D25);
const cardFlowBlue = Color(0xFF427AF0);
const cardFlowMuted = Color(0xFF7C8492);

/// A scrollable page that keeps actions at the bottom when space permits.
class CardFlowBody extends StatelessWidget {
  const CardFlowBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              minHeight: (constraints.maxHeight - 28).clamp(0, double.infinity),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

ThemeData cardFlowTheme(BuildContext context) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  return theme.copyWith(
    scaffoldBackgroundColor: dark ? cardFlowInk : Colors.white,
    appBarTheme: theme.appBarTheme.copyWith(
      backgroundColor: Colors.transparent,
      foregroundColor: dark ? Colors.white : cardFlowInk,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: dark ? Colors.white : cardFlowInk,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: dark ? cardFlowBlue : cardFlowInk,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cardFlowBlue,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

class PaymentCardPreview extends StatelessWidget {
  const PaymentCardPreview({
    super.key,
    required this.card,
    this.obscureNumber = true,
  });

  final CreditCard card;
  final bool obscureNumber;

  @override
  Widget build(BuildContext context) {
    final year = card.expiryYear;
    final expiry =
        '${card.expiryMonth}/${year.length > 2 ? year.substring(year.length - 2) : year}';
    final digits = card.cardNumber.replaceAll(RegExp(r'\s'), '');
    final number = obscureNumber
        ? card.obscuredNumber
        : digits
              .replaceAllMapped(RegExp(r'.{1,4}'), (match) => '${match[0]} ')
              .trim();
    return AspectRatio(
      aspectRatio: 1.75,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4671B2), Color(0xFF203F70), Color(0xFF142D54)],
            stops: [0, 0.48, 1],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF203F70).withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const CardChip(),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        card.cardBrand.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      card.cardholderName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    expiry,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardChip extends StatelessWidget {
  const CardChip({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 34,
    height: 27,
    child: CustomPaint(painter: _ChipPainter()),
  );
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF5DE92), Color(0xFFC5A658), Color(0xFFF0D58A)],
        ).createShader(rect),
    );
    final line = Paint()
      ..color = const Color(0xFF9B8247)
      ..strokeWidth = 0.7;
    for (final x in [0.3, 0.7]) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        line,
      );
    }
    for (final y in [0.33, 0.67]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChipPainter oldDelegate) => false;
}

class CardIntroArtwork extends StatelessWidget {
  const CardIntroArtwork({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 192,
    child: Center(
      child: SizedBox(
        width: 240,
        height: 174,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              top: 12,
              right: 14,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  width: 200,
                  height: 125,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF1EBFF), Color(0xFFDBEDF7)],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 136,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF345A7E),
                    Color(0xFF172945),
                    Color(0xFF203F64),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: cardFlowBlue.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CardChip(),
                      const Spacer(),
                      Container(
                        width: 38,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 118,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 88,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CardSuccessArtwork extends StatelessWidget {
  const CardSuccessArtwork({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 140,
    child: Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 8; i++)
            Transform.rotate(
              angle: i * 0.79,
              child: Transform.translate(
                offset: const Offset(0, -62),
                child: Container(
                  width: 4,
                  height: 8,
                  color: [
                    const Color(0xFF35BB75),
                    const Color(0xFFFFD766),
                    const Color(0xFF80B9F9),
                  ][i % 3],
                ),
              ),
            ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFF32C477).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF34CF77), Color(0xFF14A15B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                CupertinoIcons.checkmark_alt,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
