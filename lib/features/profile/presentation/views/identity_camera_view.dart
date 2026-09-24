import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Note/features/profile/presentation/widgets/identity_flow_widgets.dart';
import 'package:Note/features/profile/data/services/card_camera_session.dart';
import 'package:Note/features/profile/domain/entities/identity_scan_recognition.dart';

/// Identity-card camera with live OCR detection and a card-shaped guide.
/// Supports a complete front/back scan or capture of one selected side.
/// Single-side captures are validated before the image is returned.
class IdentityCameraView extends StatefulWidget {
  const IdentityCameraView({
    super.key,
    required this.onFrontCaptured,
    required this.onBackCaptured,
    required this.onCancel,
    this.passportMode = false,
    this.singleSideFront,
    this.validateCapture,
    this.createSession = _createSession,
    this.pickPhoto = _pickPhoto,
  });

  final ValueChanged<String> onFrontCaptured;
  final ValueChanged<String> onBackCaptured;
  final VoidCallback onCancel;
  final bool passportMode;

  /// Null scans both sides; true locks the front, false locks the back.
  final bool? singleSideFront;
  final Future<bool> Function(String path)? validateCapture;
  final CardCameraSession Function(int lensIndex) createSession;
  final Future<String?> Function() pickPhoto;

  static CardCameraSession _createSession(int lensIndex) =>
      CardCameraSession(lensIndex: lensIndex);

  static Future<String?> _pickPhoto() async => (await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 2400,
    maxHeight: 2400,
  ))?.path;

  @override
  State<IdentityCameraView> createState() => _IdentityCameraViewState();
}

class _IdentityCameraViewState extends State<IdentityCameraView>
    with WidgetsBindingObserver {
  CardCameraSession? _session;
  int _cameraCount = 0;
  bool _picking = false;
  bool _hasFront = false;
  bool _automatic = true;
  String? _candidate;
  int _matches = 0;
  int _sideVersion = 0;
  Timer? _turnTimer;
  int _lensIndex = 0;
  bool _active = true;
  bool _ready = false;
  bool _busy = false;
  bool _torch = false;
  bool _front = true;
  bool _finished = false;
  bool _permissionDenied = false;
  bool _validationFailed = false;
  String? _error;
  Future<void> _lifecycle = Future.value();

  @override
  void initState() {
    super.initState();
    _front = widget.singleSideFront ?? true;
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
    _candidate = null;
    _matches = 0;
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
    final session = widget.createSession(_lensIndex);
    _session = session;
    try {
      await session.initialize();
      if (!mounted ||
          !_active ||
          _finished ||
          _picking ||
          _session != session) {
        return;
      }
      setState(() {
        _cameraCount = session.cameraCount;
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
            ? 'identity_camera_permission_denied'.tr
            : 'identity_camera_unavailable'.tr;
      });
    }
  }

  Future<void> _startDetection() async {
    final session = _session;
    if (!_ready || _busy || !_active || _finished || session == null) return;
    final version = _sideVersion;
    try {
      await session.startDetection((text) {
        if (!mounted ||
            _busy ||
            !_active ||
            _finished ||
            session != _session ||
            version != _sideVersion) {
          return;
        }
        final candidate = widget.passportMode
            ? IdentityScanRecognition.passportCandidate(text)
            : IdentityScanRecognition.candidate(text, front: _front);
        if (candidate == null) {
          _candidate = null;
          _matches = 0;
          return;
        }
        _matches = candidate == _candidate ? _matches + 1 : 1;
        _candidate = candidate;
        if (_matches >= 2) unawaited(_capture());
      });
      if (mounted && session == _session) setState(() => _automatic = true);
    } catch (_) {
      if (mounted && session == _session) setState(() => _automatic = false);
    }
  }

  Future<void> _restartDetection() async {
    try {
      await _session?.stopDetection();
      await _startDetection();
    } catch (_) {
      if (mounted) setState(() => _automatic = false);
    }
  }

  Future<void> _switchLens() async {
    if (!_ready || _busy || _cameraCount < 2) return;
    _lensIndex = (_lensIndex + 1) % _cameraCount;
    setState(() => _ready = false);
    _queueCamera();
  }

  Future<void> _toggleTorch() async {
    if (!_ready || _busy) return;
    try {
      await _session?.setTorch(!_torch);
      if (mounted) setState(() => _torch = !_torch);
    } catch (_) {
      // Flash is unavailable on some lenses (e.g. the front camera).
    }
  }

  Future<void> _capture() async {
    final session = _session;
    if (!_ready || _busy || session == null || _finished) return;
    final version = _sideVersion;
    setState(() => _busy = true);
    try {
      final path = await session.capturePhoto();
      if (!mounted ||
          !_active ||
          session != _session ||
          version != _sideVersion) {
        return;
      }
      await _accept(path);
    } catch (_) {
      if (mounted && session == _session) {
        setState(() => _busy = false);
        await _startDetection();
      }
    } finally {
      if (mounted && !_finished && _turnTimer?.isActive != true) {
        setState(() => _busy = false);
        await _startDetection();
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy || _picking || _finished) return;
    setState(() {
      _busy = true;
      _picking = true;
    });
    await _lifecycle;
    await _closeCamera();
    try {
      final path = await widget.pickPhoto();
      if (mounted && !_finished && path != null) await _accept(path);
    } catch (_) {
      if (mounted) setState(() => _error = 'identity_camera_unavailable'.tr);
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

  Future<void> _accept(String path) async {
    if (!mounted || _finished) return;
    unawaited(HapticFeedback.lightImpact());
    _candidate = null;
    _matches = 0;
    _sideVersion++;

    final validate = widget.validateCapture;
    if (validate != null) {
      var valid = false;
      try {
        valid = await validate(path);
      } catch (_) {
        // An unreadable capture stays in the scanner for another attempt.
      }
      if (!mounted || _finished) return;
      if (!valid || !_active) {
        setState(() => _validationFailed = true);
        return;
      }
      setState(() => _validationFailed = false);
    }

    if (widget.singleSideFront != null) {
      setState(() => _finished = true);
      await _closeCamera();
      if (!mounted) return;
      if (_front) {
        widget.onFrontCaptured(path);
      } else {
        widget.onBackCaptured(path);
      }
      return;
    }

    if (widget.passportMode) {
      _finished = true;
      await _closeCamera();
      if (mounted) widget.onFrontCaptured(path);
      return;
    }

    if (_front) {
      _hasFront = true;
      widget.onFrontCaptured(path);
      if (!mounted) return;
      setState(() {
        _front = false;
        _busy = true;
      });
      _turnTimer?.cancel();
      _turnTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted || _finished) return;
        setState(() => _busy = false);
        unawaited(_startDetection());
      });
      return;
    }
    _finished = true;
    await _closeCamera();
    if (mounted) widget.onBackCaptured(path);
  }

  void _selectSide(bool front) {
    if (widget.singleSideFront != null ||
        _busy ||
        _finished ||
        front == _front ||
        (!front && !_hasFront)) {
      return;
    }
    _sideVersion++;
    _candidate = null;
    _matches = 0;
    setState(() => _front = front);
    unawaited(_restartDetection());
  }

  void _cancel() {
    setState(() => _finished = true);
    _turnTimer?.cancel();
    widget.onCancel();
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: idScreenBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              children: [
                _toolbar(),
                const SizedBox(height: 14),
                AspectRatio(aspectRatio: 1.3, child: _viewfinder()),
                const SizedBox(height: 16),
                _hintBar(),
                const SizedBox(height: 16),
                _largeCardsTemplatesRow(),
                const SizedBox(height: 22),
                _captureControls(),
                const SizedBox(height: 18),
                // IdentitySecondaryButton(
                //   label: 'identity_upload_document_action'.tr,
                //   icon: CupertinoIcons.arrow_up_doc,
                //   onPressed: _busy ? null : _pickFromGallery,
                // ),
                const SizedBox(height: 14),
                IdentityFooterNote(text: 'identity_camera_footer_encrypted'.tr),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _largeCardsTemplatesRow() {
    return Row(
      children: [
        Expanded(
          child: _cardImageTemplateBanner(
            title: 'identity_side_front'.tr,
            selected: _front,
            isFront: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _cardImageTemplateBanner(
            title: 'identity_side_back'.tr,
            selected: !_front,
            isFront: false,
          ),
        ),
      ],
    );
  }

  Widget _cardImageTemplateBanner({
    required String title,
    required bool selected,
    required bool isFront,
  }) {
    return GestureDetector(
      onTap: () => _selectSide(isFront),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? idAccent : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? idAccent.withValues(alpha: 0.25)
                  : Colors.black12,
              blurRadius: selected ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFront
                      ? CupertinoIcons.creditcard_fill
                      : CupertinoIcons.rectangle_stack_fill,
                  size: 14,
                  color: selected ? idAccent : idInk,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? idAccent : idInk,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 1.586,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFront
                        ? [const Color(0xFFF9FBF9), const Color(0xFFE2EBE5)]
                        : [const Color(0xFFEFEFEF), const Color(0xFFDCDEDD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black38, width: 1),
                ),
                child: isFront
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 20,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDA291C),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 10,
                                      height: 6,
                                      color: const Color(0xFF032EA1),
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      width: 55,
                                      height: 3,
                                      color: const Color(0xFF032EA1),
                                    ),
                                    const SizedBox(height: 1.5),
                                    Container(
                                      width: 45,
                                      height: 2,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1BE48),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5C158),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: Colors.brown,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 14,
                                      height: 11,
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 4,
                                        color: const Color(0xFF032EA1),
                                      ),
                                      const SizedBox(height: 3),
                                      Container(
                                        width: 50,
                                        height: 2.5,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: double.infinity,
                              height: 2,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD0D0D0),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.black26,
                                  width: 0.8,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 30,
                                    height: 4,
                                    color: Colors.black38,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 2.5,
                                  color: Colors.black54,
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: double.infinity,
                                  height: 2,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC8D6CE),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.black26,
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 2.5,
                                    color: Colors.black87,
                                  ),
                                  const SizedBox(height: 1.5),
                                  Container(
                                    width: double.infinity,
                                    height: 2.5,
                                    color: Colors.black87,
                                  ),
                                  const SizedBox(height: 1.5),
                                  Container(
                                    width: 90,
                                    height: 2.5,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbar() {
    return Row(
      children: [
        _chromeButton(icon: CupertinoIcons.xmark, onTap: _cancel),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: idInk,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.passportMode
                    ? 'passport_information_title'.tr
                    : widget.singleSideFront != null
                    ? (_front ? 'identity_scan_front' : 'identity_scan_back').tr
                    : _front
                    ? 'identity_step_front_label'.tr
                    : 'identity_step_back_label'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        Row(
          spacing: 8,
          children: [
            _chromeButton(
              icon: _torch ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt,
              iconColor: _torch ? idAmber : idInk,
              onTap: _toggleTorch,
            ),
            _chromeButton(
              icon: CupertinoIcons.camera_rotate,
              onTap: _cameraCount > 1 ? _switchLens : null,
              enabled: _cameraCount > 1,
            ),
          ],
        ),
      ],
    );
  }

  /// A small round white button used for the toolbar and capture-row icons
  /// (close, torch, flip lens, gallery) — the light equivalent of the old
  /// bare white-on-navy icon buttons, now that the chrome around the
  /// viewfinder is a light page rather than solid navy.
  Widget _chromeButton({
    required IconData icon,
    required VoidCallback? onTap,
    Color iconColor = idInk,
    bool enabled = true,
    double size = 18,
    double padding = 10,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(icon, size: size, color: enabled ? iconColor : idMuted),
        ),
      ),
    );
  }

  Widget _viewfinder() => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final guideWidth = size.width - 52;
      final ratio = widget.passportMode ? 1.4 : 1.586;
      _session?.viewport = size;
      _session?.frame = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: guideWidth,
        height: guideWidth / ratio,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: idInk),
            if (_ready && _session != null)
              _session!.buildPreview()
            else if (_error == null)
              const Center(child: CircularProgressIndicator(color: idAccent)),
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _permissionDenied
                            ? () => unawaited(openAppSettings())
                            : _queueCamera,
                        child: Text(
                          _permissionDenied
                              ? 'identity_open_settings_action'.tr
                              : 'identity_try_again_action'.tr,
                          style: const TextStyle(color: idAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: Center(child: _darkPill('identity_place_card_hint'.tr)),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: AspectRatio(aspectRatio: ratio, child: _guideFrame()),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 16,
              right: 16,
              child: Center(
                child: _darkPill(
                  (_busy
                          ? (widget.singleSideFront != null
                                ? 'identity_checking_capture'
                                : 'identity_hint_flip_back')
                          : _ready && _automatic
                          ? 'identity_auto_detecting'
                          : 'identity_manual_capture')
                      .tr,
                  muted: true,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  /// The inset card outline drawn over the live preview: a faint bordered
  /// box with rounded teal corner brackets (see [_CornerGuidePainter]) and a
  /// small placeholder card glyph, illustrating where to lay the ID.
  Widget _guideFrame() {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
        ),
        const IgnorePointer(child: CustomPaint(painter: _CornerGuidePainter())),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.passportMode
                    ? CupertinoIcons.doc_text_fill
                    : CupertinoIcons.person_crop_rectangle,
                color: Colors.white.withValues(alpha: 0.35),
                size: 28,
              ),
              const SizedBox(height: 10),
              Container(
                width: 90,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.16),
              ),
              if (widget.passportMode) ...[
                const SizedBox(height: 10),
                Container(
                  width: 90,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _darkPill(String text, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: muted ? 0.4 : 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: muted ? Colors.white70 : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _hintBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.info_circle_fill, size: 14, color: idGreen),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _validationFailed
                ? (_front
                          ? 'identity_front_scan_retry'
                          : 'identity_back_scan_retry')
                      .tr
                : widget.passportMode
                ? 'passport_number_hint'.tr
                : _front
                ? 'identity_hint_flat_front'.tr
                : 'identity_hint_flip_back'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: idMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _captureControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _chromeButton(
          icon: CupertinoIcons.photo,
          onTap: _busy ? null : _pickFromGallery,
          size: 22,
          padding: 14,
        ),
        Semantics(
          label: _front
              ? 'identity_capture_front_semantic'.tr
              : 'identity_capture_back_semantic'.tr,
          button: true,
          child: GestureDetector(
            onTap: _ready && !_busy ? _capture : null,
            child: Container(
              width: 74,
              height: 74,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: idInk, width: 3),
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
                          color: idInk,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
        _chromeButton(
          icon: _torch ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt,
          iconColor: _torch ? idAmber : idInk,
          onTap: _toggleTorch,
          size: 22,
          padding: 14,
        ),
      ],
    );
  }
}

class _CornerGuidePainter extends CustomPainter {
  const _CornerGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Offset.zero & size;
    final line = Paint()
      ..color = const Color(0xFF59D6C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const length = 22.0;
    const radius = 12.0;
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
  bool shouldRepaint(covariant _CornerGuidePainter oldDelegate) => false;
}
