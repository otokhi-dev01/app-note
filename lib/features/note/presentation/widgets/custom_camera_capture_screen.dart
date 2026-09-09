import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';

/// One capture [CustomCameraCaptureScreen] took during its session: the file
/// it wrote, and whether that file is a photo or a video.
class CameraCaptureResult {
  final String path;
  final bool isVideo;

  const CameraCaptureResult({required this.path, required this.isVideo});
}

/// Pushes the custom camera screen and, if the user captured anything before
/// tapping Done, attaches every capture from that session to the note — one
/// block each, in the order they were taken. Replaces the old "Take Photo or
/// Video" action sheet: the mode choice now lives on-screen, in the camera
/// itself, the way a phone's own camera app works, and a session can mix
/// photos and videos freely before you're done.
Future<void> openCustomCameraCapture(
  BuildContext context,
  NoteDetailController controller,
) async {
  final results = await Navigator.of(context).push<List<CameraCaptureResult>>(
    MaterialPageRoute(
      builder: (_) => const CustomCameraCaptureScreen(),
      fullscreenDialog: true,
    ),
  );
  if (results == null || results.isEmpty) return;
  await controller.addCapturedMedia(results);
}

enum _CaptureMode { photo, video }

/// A live, in-app camera screen that replaces launching the OS's own camera
/// app for "Camera" on the attachment sheet: a preview, a Photo/Video
/// toggle, flash, zoom presets sized to whatever this device's lenses
/// actually support, a thumbnail of the last shot, and a front/back flip —
/// the general shape of a modern phone camera app.
///
/// Deliberately doesn't attempt hardware-specific extras no plugin exposes
/// generically, like multi-frame night mode or on-device scene "AI" — those
/// aren't things `package:camera` can turn on, only real per-device camera
/// apps built against a specific vendor's own APIs can.
class CustomCameraCaptureScreen extends StatefulWidget {
  const CustomCameraCaptureScreen({super.key});

  @override
  State<CustomCameraCaptureScreen> createState() =>
      _CustomCameraCaptureScreenState();
}

class _CustomCameraCaptureScreenState extends State<CustomCameraCaptureScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _cameraIndex = 0;

  _CaptureMode _mode = _CaptureMode.photo;
  FlashMode _flashMode = FlashMode.off;

  double _minZoom = 1;
  double _maxZoom = 1;
  double _currentZoom = 1;
  List<double> _zoomPresets = const [1];

  final List<CameraCaptureResult> _captures = [];

  bool _isBusy = false;
  bool _isRecording = false;
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTimer;

  Object? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_setup());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      unawaited(controller.dispose());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_openCamera(controller.description));
    }
  }

  Future<void> _setup() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() => _initError = 'No camera available on this device.');
        return;
      }
      _cameras = cameras;
      final backIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _cameraIndex = backIndex >= 0 ? backIndex : 0;
      await _openCamera(cameras[_cameraIndex]);
    } catch (error) {
      debugPrint('[CAMERA SETUP ERROR] $error');
      if (mounted) setState(() => _initError = error);
    }
  }

  Future<void> _openCamera(CameraDescription description) async {
    final previous = _controller;
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
    );
    _controller = controller;
    try {
      await controller.initialize();
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      try {
        await controller.setFlashMode(_flashMode);
      } catch (error) {
        // Not every lens supports every flash mode (the ultra-wide often
        // has no flash at all) — fall back to off rather than fail setup.
        debugPrint('[CAMERA FLASH ERROR] $error');
        _flashMode = FlashMode.off;
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      final clampedZoom = 1.0.clamp(minZoom, maxZoom).toDouble();
      await controller.setZoomLevel(clampedZoom);
      setState(() {
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _currentZoom = clampedZoom;
        _zoomPresets = _buildZoomPresets(minZoom, maxZoom);
        _initError = null;
      });
    } catch (error) {
      debugPrint('[CAMERA OPEN ERROR] $error');
      if (mounted) setState(() => _initError = error);
    } finally {
      await previous?.dispose();
    }
  }

  /// Zoom presets sized to what this camera actually supports — an ultra-wide
  /// lens's min zoom if there is one, always 1x, and a longer preset only if
  /// the hardware actually goes past 1x. No hardcoded "0.5/1/2.5": those are
  /// one specific phone's lens set, not a universal number.
  List<double> _buildZoomPresets(double min, double max) {
    final presets = <double>{};
    if (min < 1) presets.add(min);
    presets.add(1);
    if (max >= 2) {
      presets.add(2);
    } else if (max > 1) {
      presets.add(max);
    }
    final sorted = presets.where((zoom) => zoom >= min && zoom <= max).toList()
      ..sort();
    return sorted.isEmpty ? [_clampZoom(1, min, max)] : sorted;
  }

  double _clampZoom(double value, double min, double max) =>
      value.clamp(min, max).toDouble();

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _isBusy || _isRecording) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _openCamera(_cameras[_cameraIndex]);
  }

  Future<void> _cycleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    const cycle = [FlashMode.off, FlashMode.auto, FlashMode.always];
    final next = cycle[(cycle.indexOf(_flashMode) + 1) % cycle.length];
    try {
      await controller.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (error) {
      debugPrint('[CAMERA FLASH ERROR] $error');
    }
  }

  Future<void> _setZoom(double zoom) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final clamped = _clampZoom(zoom, _minZoom, _maxZoom);
    try {
      await controller.setZoomLevel(clamped);
      if (mounted) setState(() => _currentZoom = clamped);
    } catch (error) {
      debugPrint('[CAMERA ZOOM ERROR] $error');
    }
  }

  Future<void> _handleShutterTap() async {
    if (_mode == _CaptureMode.video) {
      if (_isRecording) {
        await _stopRecording();
      } else {
        await _startRecording();
      }
      return;
    }
    await _takePhoto();
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _captures.add(CameraCaptureResult(path: file.path, isVideo: false));
        _isBusy = false;
      });
    } catch (error) {
      debugPrint('[CAMERA CAPTURE ERROR] $error');
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isBusy) {
      return;
    }
    try {
      await controller.startVideoRecording();
      _recordingElapsed = Duration.zero;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingElapsed += const Duration(seconds: 1));
      });
      if (mounted) setState(() => _isRecording = true);
    } catch (error) {
      debugPrint('[CAMERA RECORD START ERROR] $error');
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_isRecording) return;
    _recordingTimer?.cancel();
    setState(() => _isBusy = true);
    try {
      final file = await controller.stopVideoRecording();
      if (!mounted) return;
      setState(() {
        _captures.add(CameraCaptureResult(path: file.path, isVideo: true));
        _isRecording = false;
        _isBusy = false;
      });
    } catch (error) {
      debugPrint('[CAMERA RECORD STOP ERROR] $error');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isBusy = false;
        });
      }
    }
  }

  /// Ends the session and hands every capture back to [openCustomCameraCapture].
  void _finishSession() {
    Navigator.of(context).pop(List<CameraCaptureResult>.of(_captures));
  }

  /// The X button: cancels outright when nothing's been captured yet: with
  /// captures already sitting in this session, discarding them needs a
  /// deliberate confirmation first — the same "are you sure" pattern the
  /// crop screen's own Cancel already uses for unsaved changes.
  Future<void> _handleClose() async {
    if (_captures.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard captures?'),
        content: Text(
          _captures.length == 1
              ? 'The photo or video you just took will be lost.'
              : 'The ${_captures.length} photos/videos you just took will '
                    'be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  String _formatElapsed(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(
      2,
      '0',
    );
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _initError != null
            ? _buildError(_initError!)
            : Stack(
                children: [
                  Positioned.fill(child: _buildPreview()),
                  _buildTopBar(),
                  if (_zoomPresets.length > 1) _buildZoomPresetRow(),
                  _buildBottomBar(),
                  if (_isRecording) _buildRecordingBadge(),
                ],
              ),
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: Colors.white70,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not open the camera.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return GestureDetector(
      onScaleUpdate: (details) {
        if (details.scale == 1.0) return;
        unawaited(_setZoom(_currentZoom * details.scale));
      },
      child: Center(child: CameraPreview(controller)),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleIconButton(
            icon: Icons.close,
            semanticLabel: 'Close',
            onTap: _isRecording ? null : _handleClose,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CircleIconButton(
                icon: switch (_flashMode) {
                  FlashMode.off => Icons.flash_off,
                  FlashMode.auto => Icons.flash_auto,
                  FlashMode.always => Icons.flash_on,
                  FlashMode.torch => Icons.flashlight_on,
                },
                semanticLabel: 'Flash: ${_flashMode.name}',
                onTap: _cycleFlash,
              ),
              if (_captures.isNotEmpty) ...[
                const SizedBox(width: 8),
                _CircleIconButton(
                  icon: Icons.check,
                  semanticLabel: 'Done — attach ${_captures.length} capture'
                      '${_captures.length == 1 ? '' : 's'}',
                  onTap: _isRecording ? null : _finishSession,
                  filled: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoomPresetRow() {
    return Positioned(
      bottom: 132,
      left: 0,
      right: 0,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final zoom in _zoomPresets) _buildZoomPresetPill(zoom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomPresetPill(double zoom) {
    final isSelected = (zoom - _currentZoom).abs() < 0.05;
    final label = zoom == zoom.roundToDouble()
        ? '${zoom.toInt()}×'
        : '${zoom.toStringAsFixed(1)}×';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _setZoom(zoom),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Colors.amber : Colors.transparent,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeToggle(),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildThumbnail(),
              _buildShutterButton(),
              _CircleIconButton(
                icon: Icons.flip_camera_ios_outlined,
                semanticLabel: 'Switch camera',
                onTap: _flipCamera,
                enabled: _cameras.length > 1 && !_isRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeTab('Photo', _CaptureMode.photo),
            _buildModeTab('Video', _CaptureMode.video),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, _CaptureMode mode) {
    final isSelected = _mode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isRecording ? null : () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final last = _captures.isEmpty ? null : _captures.last;
    return Semantics(
      button: last != null,
      label: last == null
          ? 'No captures yet'
          : 'Done — attach ${_captures.length} capture'
                '${_captures.length == 1 ? '' : 's'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: last == null ? null : _finishSession,
        child: SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: Colors.white24,
              child: last == null
                  ? null
                  : last.isVideo
                  ? const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 22,
                    )
                  : Image.file(File(last.path), fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    final isVideoMode = _mode == _CaptureMode.video;
    return GestureDetector(
      onTap: _isBusy ? null : _handleShutterTap,
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white24,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            shape: isVideoMode && _isRecording
                ? BoxShape.rectangle
                : BoxShape.circle,
            borderRadius: isVideoMode && _isRecording
                ? BorderRadius.circular(8)
                : null,
            color: isVideoMode && _isRecording ? Colors.red : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingBadge() {
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
                const SizedBox(width: 6),
                Text(
                  _formatElapsed(_recordingElapsed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool enabled;
  final bool filled;

  const _CircleIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.enabled = true,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onTap != null;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? Colors.amber
                : Colors.black.withValues(alpha: 0.35),
          ),
          child: Icon(
            icon,
            color: !isEnabled
                ? Colors.white30
                : filled
                ? Colors.black
                : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
