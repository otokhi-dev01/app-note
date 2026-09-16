import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Note/features/profile/data/services/card_camera_session.dart';
import 'package:Note/features/profile/domain/entities/card_scan_recognition.dart';
import 'package:Note/features/profile/domain/entities/card_text_parser.dart';
import 'package:Note/features/profile/domain/entities/credit_card.dart';
import 'package:Note/features/profile/presentation/widgets/card_flow_widgets.dart';

class CardCameraView extends StatefulWidget {
  const CardCameraView({
    super.key,
    required this.onComplete,
    required this.onCancel,
    required this.onEnterManually,
    required this.onSideChanged,
    this.createSession = CardCameraSession.new,
    this.pickText = CardCameraSession.pickText,
  });

  final ValueChanged<CreditCard> onComplete;
  final VoidCallback onCancel;
  final VoidCallback onEnterManually;
  final ValueChanged<bool> onSideChanged;
  final CardCameraSession Function() createSession;
  final Future<String?> Function() pickText;

  @override
  State<CardCameraView> createState() => _CardCameraViewState();
}

class _CardCameraViewState extends State<CardCameraView>
    with WidgetsBindingObserver {
  CardCameraSession? _session;
  Future<void> _lifecycle = Future.value();
  bool _active = true;
  bool _ready = false;
  bool _busy = false;
  bool _picking = false;
  bool _torch = false;
  bool _front = true;
  bool _finished = false;
  bool _permissionDenied = false;
  bool _automatic = true;
  String _frontText = '';
  String? _error;
  String _status = 'Hold steady...';
  String? _candidate;
  int _matches = 0;
  int _sideVersion = 0;
  Timer? _turnTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _queueCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_picking) _queueCamera();
  }

  void _queueCamera() {
    _lifecycle = _lifecycle.then((_) async {
      await _closeCamera();
      if (mounted && _active && !_finished && !_picking) await _openCamera();
    });
  }

  Future<void> _closeCamera() async {
    final session = _session;
    _session = null;
    if (mounted) {
      setState(() {
        _ready = false;
        _torch = false;
      });
    }
    try {
      await session?.dispose();
    } catch (_) {
      // A disconnected camera may already have been closed by the OS.
    }
  }

  Future<void> _openCamera() async {
    final session = widget.createSession();
    _session = session;
    try {
      await session.initialize();
      if (!mounted ||
          !_active ||
          _picking ||
          _finished ||
          _session != session) {
        return;
      }
      setState(() {
        _ready = true;
        _error = null;
        _permissionDenied = false;
      });
      await _startDetection();
    } catch (error) {
      if (!mounted || _session != session) return;
      final denied =
          error is CameraException && error.code.startsWith('CameraAccess');
      setState(() {
        _ready = false;
        _permissionDenied = denied;
        _error = denied
            ? 'Allow camera access in Settings to scan your card.'
            : 'The camera could not open. Try again or choose a card photo.';
      });
    }
  }

  Future<void> _startDetection() async {
    final session = _session;
    if (!_ready || _busy || !_active || session == null || _finished) return;
    final version = _sideVersion;
    try {
      await session.startDetection((text) {
        if (!mounted ||
            _busy ||
            _finished ||
            !_active ||
            version != _sideVersion ||
            session != _session) {
          return;
        }
        final candidate = _front
            ? CardScanRecognition.frontCandidate(text)
            : CardScanRecognition.backCandidate(
                text,
                fourDigitCode:
                    CardTextParser.parse(_frontText)?.cardBrand == 'AMEX',
              );
        if (candidate == null) {
          _candidate = null;
          _matches = 0;
          return;
        }
        _matches = _candidate == candidate ? _matches + 1 : 1;
        _candidate = candidate;
        if (_matches >= 2) unawaited(_acceptText(text, automatic: true));
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _automatic = false;
          _status = 'Tap the shutter to capture';
        });
      }
    }
  }

  Future<void> _acceptText(String text, {bool automatic = false}) async {
    if (!mounted || _finished) return;
    if (text.trim().isEmpty) {
      setState(() {
        _busy = false;
        _status = 'No text found. Hold steady and try again.';
      });
      await _startDetection();
      return;
    }
    final version = _sideVersion;
    setState(() => _busy = true);
    try {
      await _session?.stopDetection();
    } catch (_) {
      // The OS may release the camera while a recognized frame is in flight.
    }
    if (!mounted || _finished || version != _sideVersion) return;
    if (_front) {
      _frontText = text;
      _sideVersion++;
      _candidate = null;
      _matches = 0;
      setState(() {
        _front = false;
        _status = 'Front captured. Turn your card over.';
      });
      widget.onSideChanged(false);
      unawaited(HapticFeedback.lightImpact());
      // Give the user time to turn the card before accepting another frame.
      _turnTimer?.cancel();
      _turnTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted || _finished) return;
        setState(() {
          _busy = false;
          _status = 'Hold steady...';
        });
        unawaited(_startDetection());
      });
      return;
    }
    final card = CardScanRecognition.parseSides(_frontText, text);
    if (card == null) {
      setState(() {
        _busy = false;
        _status = 'Card number not read. Retake the front or enter manually.';
      });
      // Avoid repeatedly accepting the same unreadable pair automatically.
      if (!automatic) unawaited(HapticFeedback.lightImpact());
      return;
    }
    _finished = true;
    await _closeCamera();
    if (mounted) widget.onComplete(card);
  }

  Future<void> _capture() async {
    final session = _session;
    if (!_ready || _busy || session == null) return;
    final version = _sideVersion;
    setState(() {
      _busy = true;
      _status = 'Reading card...';
    });
    try {
      final text = await session.captureText();
      if (!mounted || _session != session || version != _sideVersion) return;
      await _acceptText(text);
    } catch (_) {
      if (mounted && _session == session) {
        setState(() {
          _busy = false;
          _status = 'Could not read the photo. Please try again.';
        });
        await _startDetection();
      }
    } finally {
      if (mounted &&
          _session != session &&
          !_finished &&
          _turnTimer?.isActive != true) {
        setState(() => _busy = false);
        await _startDetection();
      }
    }
  }

  Future<void> _pickPhoto() async {
    if (_busy || _picking) return;
    setState(() {
      _busy = true;
      _picking = true;
    });
    await _lifecycle;
    await _closeCamera();
    try {
      final text = await widget.pickText();
      if (!mounted) return;
      if (text != null) await _acceptText(text);
    } catch (_) {
      if (mounted) {
        setState(
          () => _status = 'Could not read that photo. Please try another.',
        );
      }
    } finally {
      _picking = false;
      if (mounted && !_finished) {
        setState(() {
          if (_turnTimer?.isActive != true) _busy = false;
        });
        _queueCamera();
      }
    }
  }

  Future<void> _toggleTorch() async {
    if (!_ready || _busy) return;
    try {
      await _session?.setTorch(!_torch);
      if (mounted) setState(() => _torch = !_torch);
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Flash is unavailable on this camera.');
      }
    }
  }

  void _back() {
    if (_front) {
      _finished = true;
      widget.onCancel();
      return;
    }
    _turnTimer?.cancel();
    _sideVersion++;
    _candidate = null;
    _matches = 0;
    setState(() {
      _front = true;
      _frontText = '';
      _busy = false;
      _status = 'Hold steady...';
    });
    widget.onSideChanged(true);
    unawaited(_restartDetection());
  }

  Future<void> _restartDetection() async {
    try {
      await _session?.stopDetection();
      await _startDetection();
    } catch (_) {
      if (mounted) setState(() => _status = 'Tap the shutter to capture');
    }
  }

  @override
  void dispose() {
    _finished = true;
    _turnTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_lifecycle.then((_) => _closeCamera()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF111719),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final padding = MediaQuery.paddingOf(context);
            final landscape = size.width > size.height;
            final guideWidth = landscape
                ? math.min(size.width * 0.52, (size.height - 100) * 1.586)
                : math.min(size.width - 36, 440.0);
            final guideHeight = guideWidth / 1.586;
            final guide = Rect.fromLTWH(
              landscape ? 24 : (size.width - guideWidth) / 2,
              landscape
                  ? (size.height - guideHeight) / 2 + 20
                  : math.max(padding.top + 130, size.height * 0.27),
              guideWidth,
              guideHeight,
            );
            _session?.viewport = size;
            _session?.frame = guide.deflate(8);
            return Stack(
              children: [
                if (_ready && _session != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onTapDown: (details) {
                        final point = Offset(
                          details.localPosition.dx / size.width,
                          details.localPosition.dy / size.height,
                        );
                        unawaited(
                          _session?.focus(point).catchError((Object _) {}) ??
                              Future<void>.value(),
                        );
                      },
                      child: _session!.buildPreview(),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _CardGuidePainter(guide)),
                  ),
                ),
                Positioned(
                  top: padding.top + 6,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: _front ? 'Cancel scanning' : 'Retake front',
                        onPressed: _back,
                        icon: const Icon(
                          CupertinoIcons.back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _front ? 'Scan Front Side' : 'Scan Back Side',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                if (!landscape)
                  Positioned(
                    top: padding.top + 74,
                    left: 32,
                    right: 32,
                    child: Text(
                      _front
                          ? 'Align your card within the frame.\n${_automatic ? 'The card will be detected automatically.' : 'Tap the shutter when your card is in focus.'}'
                          : 'Turn your card over and align the back side\nwithin the frame.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                if (_error == null && !_ready)
                  Positioned.fromRect(
                    rect: guide,
                    child: const Center(
                      child: CircularProgressIndicator(color: cardFlowBlue),
                    ),
                  ),
                if (_error != null)
                  Positioned.fromRect(
                    rect: guide.deflate(10),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: _permissionDenied
                                  ? () {
                                      unawaited(openAppSettings());
                                    }
                                  : _queueCamera,
                              child: Text(
                                _permissionDenied
                                    ? 'Open Settings'
                                    : 'Try Again',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: landscape ? size.width * 0.60 : 24,
                  right: 24,
                  bottom: padding.bottom + 14,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF27333E,
                          ).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                      SizedBox(height: landscape ? 14 : 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            tooltip: _torch
                                ? 'Turn flash off'
                                : 'Turn flash on',
                            onPressed: _ready && !_busy ? _toggleTorch : null,
                            icon: Icon(
                              _torch
                                  ? CupertinoIcons.bolt_fill
                                  : CupertinoIcons.bolt,
                              size: 27,
                              color: _torch ? cardFlowBlue : Colors.white,
                            ),
                          ),
                          Semantics(
                            label: _front
                                ? 'Capture front of card'
                                : 'Capture back of card',
                            button: true,
                            child: GestureDetector(
                              onTap: _ready && !_busy ? _capture : null,
                              child: Container(
                                width: 76,
                                height: 76,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _busy
                                      ? const Padding(
                                          padding: EdgeInsets.all(18),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: cardFlowInk,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Choose card photo',
                            onPressed: _busy ? null : _pickPhoto,
                            icon: const Icon(
                              CupertinoIcons.photo,
                              size: 26,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: landscape ? 12 : 28),
                      Text(
                        _front ? 'Front of card' : 'Back of card',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _sideDot(_front),
                          Container(
                            width: 50,
                            height: 2,
                            color: const Color(0xFF657184),
                          ),
                          _sideDot(!_front),
                        ],
                      ),
                      if (_error != null || _status.contains('not read'))
                        TextButton(
                          onPressed: widget.onEnterManually,
                          child: const Text('Enter Card Manually'),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _sideDot(bool selected) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? cardFlowBlue : const Color(0xFF69717E),
    ),
    child: selected
        ? const Icon(Icons.diamond, size: 11, color: Colors.white)
        : null,
  );
}

class _CardGuidePainter extends CustomPainter {
  const _CardGuidePainter(this.guide);
  final Rect guide;

  @override
  void paint(Canvas canvas, Size size) {
    final cutout = RRect.fromRectAndRadius(guide, const Radius.circular(16));
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(cutout);
    canvas.drawPath(
      shade,
      Paint()..color = Colors.black.withValues(alpha: 0.60),
    );
    final line = Paint()
      ..color = const Color(0xFF648CFA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const length = 27.0;
    const radius = 10.0;
    for (final corner in [
      guide.topLeft,
      guide.topRight,
      guide.bottomRight,
      guide.bottomLeft,
    ]) {
      final dx = corner.dx == guide.left ? 1.0 : -1.0;
      final dy = corner.dy == guide.top ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(corner.dx, corner.dy + dy * length)
        ..lineTo(corner.dx, corner.dy + dy * radius)
        ..quadraticBezierTo(
          corner.dx,
          corner.dy,
          corner.dx + dx * radius,
          corner.dy,
        )
        ..lineTo(corner.dx + dx * length, corner.dy);
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant _CardGuidePainter oldDelegate) =>
      oldDelegate.guide != guide;
}
