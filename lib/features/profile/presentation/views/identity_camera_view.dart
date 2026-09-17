import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Note/features/profile/presentation/widgets/identity_flow_widgets.dart';

/// Fallback front/back capture screen for the Digital Civic ID scan flow,
/// used only when no BlinkID license is configured for the current platform
/// (see `IdentityScanController.onStartScan` — BlinkID's own native UI is
/// preferred and never routes through this screen).
///
/// This screen only captures the two card photos on-device; the parsing
/// happens server-side afterwards (see `ScanNationalId`), so the guide frame
/// and "Auto-detecting" pill drawn over the viewfinder are illustrative
/// guidance rather than a live detector. Capture is manual: the user aligns
/// the card and taps the shutter.
class IdentityCameraView extends StatefulWidget {
  const IdentityCameraView({
    super.key,
    required this.onFrontCaptured,
    required this.onBackCaptured,
    required this.onCancel,
  });

  final ValueChanged<String> onFrontCaptured;
  final ValueChanged<String> onBackCaptured;
  final VoidCallback onCancel;

  @override
  State<IdentityCameraView> createState() => _IdentityCameraViewState();
}

class _IdentityCameraViewState extends State<IdentityCameraView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _lensIndex = 0;
  bool _active = true;
  bool _ready = false;
  bool _busy = false;
  bool _torch = false;
  bool _front = true;
  bool _finished = false;
  bool _permissionDenied = false;
  String? _error;
  Future<void> _lifecycle = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _queueCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _queueCamera();
  }

  void _queueCamera() {
    _lifecycle = _lifecycle.then((_) async {
      await _closeCamera();
      if (mounted && _active && !_finished) await _openCamera();
    });
  }

  Future<void> _closeCamera() async {
    final controller = _controller;
    _controller = null;
    if (mounted) setState(() => _ready = false);
    try {
      await controller?.dispose();
    } catch (_) {
      // A disconnected camera may already have been closed by the OS.
    }
  }

  Future<void> _openCamera() async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera is available.');
      }
      if (_lensIndex >= _cameras.length) _lensIndex = 0;
      final controller = CameraController(
        _cameras[_lensIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted || !_active || _finished || _controller != controller) {
        return;
      }
      await controller.setFlashMode(FlashMode.off);
      setState(() {
        _ready = true;
        _error = null;
        _permissionDenied = false;
      });
    } catch (error) {
      if (!mounted) return;
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

  Future<void> _switchLens() async {
    if (!_ready || _busy || _cameras.length < 2) return;
    _lensIndex = (_lensIndex + 1) % _cameras.length;
    setState(() => _ready = false);
    _queueCamera();
  }

  Future<void> _toggleTorch() async {
    if (!_ready || _busy) return;
    try {
      await _controller?.setFlashMode(_torch ? FlashMode.off : FlashMode.torch);
      if (mounted) setState(() => _torch = !_torch);
    } catch (_) {
      // Flash is unavailable on some lenses (e.g. the front camera).
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (!_ready || _busy || controller == null) return;
    setState(() => _busy = true);
    try {
      final photo = await controller.takePicture();
      await _accept(photo.path);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (image != null) await _accept(image.path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(String path) async {
    unawaited(HapticFeedback.lightImpact());
    if (_front) {
      widget.onFrontCaptured(path);
      if (!mounted) return;
      setState(() {
        _front = false;
        _busy = false;
      });
      return;
    }
    _finished = true;
    await _closeCamera();
    if (mounted) widget.onBackCaptured(path);
  }

  void _selectSide(bool front) {
    if (_busy || _finished || front == _front) return;
    setState(() => _front = front);
  }

  @override
  void dispose() {
    _finished = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_lifecycle.then((_) => _closeCamera()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onCancel();
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
                AspectRatio(aspectRatio: 0.85, child: _viewfinder()),
                const SizedBox(height: 16),
                _sideTabs(),
                const SizedBox(height: 14),
                _hintBar(),
                const SizedBox(height: 22),
                _captureControls(),
                const SizedBox(height: 18),
                IdentitySecondaryButton(
                  label: 'identity_upload_document_action'.tr,
                  icon: CupertinoIcons.arrow_up_doc,
                  onPressed: _busy ? null : _pickFromGallery,
                ),
                const SizedBox(height: 14),
                IdentityFooterNote(
                  text: 'identity_camera_footer_encrypted'.tr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbar() {
    return Row(
      children: [
        _chromeButton(icon: CupertinoIcons.xmark, onTap: widget.onCancel),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: idInk,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _front
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
              onTap: _cameras.length > 1 ? _switchLens : null,
              enabled: _cameras.length > 1,
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

  Widget _viewfinder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: idInk),
          if (_ready && _controller != null)
            CameraPreview(_controller!)
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
              child: AspectRatio(aspectRatio: 1.55, child: _guideFrame()),
            ),
          ),
          Positioned(
            bottom: 14,
            left: 16,
            right: 16,
            child: Center(
              child: _darkPill('identity_auto_detecting'.tr, muted: true),
            ),
          ),
        ],
      ),
    );
  }

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
                CupertinoIcons.person_crop_rectangle,
                color: Colors.white.withValues(alpha: 0.35),
                size: 28,
              ),
              const SizedBox(height: 10),
              Container(
                width: 90,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.16),
              ),
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

  /// The Front/Back switch as one segmented pill (rather than two separate
  /// cards) — selected side shows as a white chip on the dark track.
  Widget _sideTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: idInk,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              selected: _front,
              icon: CupertinoIcons.creditcard,
              label: 'identity_side_front'.tr,
              onTap: () => _selectSide(true),
            ),
          ),
          Expanded(
            child: _segment(
              selected: !_front,
              icon: CupertinoIcons.rectangle_stack,
              label: 'identity_side_back'.tr,
              onTap: () => _selectSide(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? idInk : Colors.white60),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? idInk : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
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
            _front
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
