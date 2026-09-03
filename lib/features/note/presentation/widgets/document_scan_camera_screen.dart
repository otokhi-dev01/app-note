// import 'dart:async';
// import 'dart:io';
// // import 'package:camera/camera.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:Note/core/feedback/app_snackbar.dart';
// import 'package:Note/core/theme/ios_semantic_colors.dart';
// import 'package:Note/features/note/presentation/widgets/scanned_document_review_page.dart'
//     show ScanPageSource;
// import 'package:Note/shared/utils/scan_color_matrices.dart';
// import 'package:Note/shared/widgets/glass_widgets.dart';
// enum DocumentScanCameraMode { capture, ocr }
// enum DocumentScanCameraFilterPreset {
//   original,
//   grey,
//   blackAndWhite,
//   darken,
//   lighten,
// }
// class DocumentScanCameraResult {
//   final DocumentScanCameraMode mode;
//   final List<String> pages;
//   const DocumentScanCameraResult({required this.mode, required this.pages});
// }
// typedef DocumentScanCapture =
//     Future<String?> Function(
//       String rawStillPath,
//       DocumentScanCameraFilterPreset preset,
//     );
// class DocumentScanCameraScreen extends StatefulWidget {
//   final DocumentScanCameraMode initialMode;
//   final bool allowModeToggle;
//   final DocumentScanCapture onCapturePage;
//   final ScanPageSource onPickFromGallery;
//   final Future<String?> Function()? onPickSingleFromGallery;
//   final Future<void> Function(Iterable<String> paths)? onDiscardPages;
//   const DocumentScanCameraScreen({
//     super.key,
//     required this.initialMode,
//     this.allowModeToggle = true,
//     required this.onCapturePage,
//     required this.onPickFromGallery,
//     this.onPickSingleFromGallery,
//     this.onDiscardPages,
//   });
//   @override
//   State<DocumentScanCameraScreen> createState() =>
//       _DocumentScanCameraScreenState();
// }
// enum _CameraStage {
//   requestingPermission,
//   permissionDenied,
//   starting,
//   ready,
//   unavailable,
// }
// class _DocumentScanCameraScreenState extends State<DocumentScanCameraScreen>
//     with WidgetsBindingObserver {
//   CameraController? _controller;
//   var _stage = _CameraStage.requestingPermission;
//   String? _errorMessage;
//   var _isPermanentlyDenied = false;
//   var _flashMode = FlashMode.off;
//   var _preset = DocumentScanCameraFilterPreset.original;
//   late var _mode = widget.initialMode;
//   final List<String> _pages = [];
//   var _isCapturing = false;
//   var _isPicking = false;
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     unawaited(_ensurePermissionThenStart());
//   }
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     final controller = _controller;
//     if (controller == null) return;
//     if (state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.paused) {
//       controller.dispose();
//       _controller = null;
//       if (mounted) setState(() => _stage = _CameraStage.starting);
//     } else if (state == AppLifecycleState.resumed) {
//       unawaited(_ensurePermissionThenStart());
//     }
//   }
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _controller?.dispose();
//     super.dispose();
//   }
//   Future<void> _ensurePermissionThenStart() async {
//     if (mounted) setState(() => _stage = _CameraStage.requestingPermission);
//     var status = await Permission.camera.status;
//     if (!status.isGranted && !status.isLimited) {
//       try {
//         status = await Permission.camera.request();
//       } catch (_) {
//         status = PermissionStatus.denied;
//       }
//     }
//     if (!mounted) return;
//     if (status.isGranted || status.isLimited) {
//       await _startCamera();
//       return;
//     }
//     setState(() {
//       _stage = _CameraStage.permissionDenied;
//       _isPermanentlyDenied = status.isPermanentlyDenied;
//     });
//   }
//   Future<void> _openSettings() async {
//     try {
//       if (!await openAppSettings()) _showUnavailable();
//     } catch (_) {
//       _showUnavailable();
//     }
//   }
//   void _showUnavailable() {
//     AppSnackbar.warning(
//       'action_unavailable_title'.tr,
//       'action_unavailable_message'.tr,
//     );
//   }
//   Future<void> _startCamera() async {
//     setState(() => _stage = _CameraStage.starting);
//     try {
//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         _fail('note_editor_scan_camera_unavailable'.tr);
//         return;
//       }
//       final camera = cameras.firstWhere(
//         (c) => c.lensDirection == CameraLensDirection.back,
//         orElse: () => cameras.first,
//       );
//       final controller = CameraController(
//         camera,
//         ResolutionPreset.high,
//         enableAudio: false,
//       );
//       _controller = controller;
//       await controller.initialize();
//       if (!mounted) {
//         await controller.dispose();
//         return;
//       }
//       setState(() => _stage = _CameraStage.ready);
//     } on CameraException catch (e) {
//       _fail(e.description ?? 'note_editor_scan_camera_unavailable'.tr);
//     } catch (_) {
//       _fail('note_editor_scan_camera_unavailable'.tr);
//     }
//   }
//   void _fail(String message) {
//     if (!mounted) return;
//     setState(() {
//       _stage = _CameraStage.unavailable;
//       _errorMessage = message;
//     });
//   }
//   void _cycleFlash() {
//     final controller = _controller;
//     if (controller == null) return;
//     final next = switch (_flashMode) {
//       FlashMode.off => FlashMode.auto,
//       FlashMode.auto => FlashMode.torch,
//       _ => FlashMode.off,
//     };
//     unawaited(
//       controller.setFlashMode(next).then((_) {
//         if (mounted) setState(() => _flashMode = next);
//       }),
//     );
//   }
//   IconData get _flashIcon => switch (_flashMode) {
//     FlashMode.off => CupertinoIcons.bolt_slash,
//     FlashMode.auto => CupertinoIcons.bolt_badge_a_fill,
//     _ => CupertinoIcons.bolt_fill,
//   };
//   Color get _accentColor => _mode == DocumentScanCameraMode.capture
//       ? IosSemanticColors.purple
//       : IosSemanticColors.indigo;
//   Future<void> _onShutterTap() async {
//     final controller = _controller;
//     if (controller == null || !controller.value.isInitialized) return;
//     if (_isCapturing) return;
//     setState(() => _isCapturing = true);
//     String? rawPath;
//     try {
//       final photo = await controller.takePicture();
//       rawPath = photo.path;
//       final page = await widget.onCapturePage(rawPath, _preset);
//       if (!mounted) return;
//       if (page == null) {
//         AppSnackbar.warning(
//           'note_editor_scan_no_document_title'.tr,
//           'note_editor_scan_no_document_message'.tr,
//         );
//         return;
//       }
//       _handleCapturedPage(page);
//     } catch (e) {
//       debugPrint('[SCAN CAMERA CAPTURE ERROR] $e');
//       if (mounted) {
//         AppSnackbar.error(
//           'note_editor_error_title'.tr,
//           'note_editor_scan_save_failed'.tr,
//         );
//       }
//     } finally {
//       if (rawPath != null) {
//         try {
//           final rawFile = File(rawPath);
//           if (rawFile.existsSync()) rawFile.deleteSync();
//         } catch (_) {
//           // Native camera scratch file; cleanup is best effort.
//         }
//       }
//       if (mounted) setState(() => _isCapturing = false);
//     }
//   }
//   void _handleCapturedPage(String page) {
//     if (_mode == DocumentScanCameraMode.ocr) {
//       Navigator.of(
//         context,
//       ).pop(DocumentScanCameraResult(mode: _mode, pages: [page]));
//       return;
//     }
//     setState(() => _pages.add(page));
//   }
//   Future<void> _onGalleryTap() async {
//     if (_isPicking || _isCapturing) return;
//     setState(() => _isPicking = true);
//     try {
//       if (_mode == DocumentScanCameraMode.ocr) {
//         final page = await widget.onPickSingleFromGallery?.call();
//         if (!mounted || page == null) return;
//         Navigator.of(
//           context,
//         ).pop(DocumentScanCameraResult(mode: _mode, pages: [page]));
//         return;
//       }
//       final added = await widget.onPickFromGallery();
//       if (!mounted || added.isEmpty) return;
//       setState(() => _pages.addAll(added));
//     } catch (e) {
//       debugPrint('[SCAN CAMERA GALLERY ERROR] $e');
//       if (mounted) {
//         AppSnackbar.error(
//           'note_editor_error_title'.tr,
//           'note_editor_scan_add_failed'.tr,
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isPicking = false);
//     }
//   }
//   Future<void> _onClose() async {
//     if (_pages.isEmpty) {
//       Navigator.of(context).pop();
//       return;
//     }
//     final shouldDiscard = await showCupertinoDialog<bool>(
//       context: context,
//       builder: (context) => CupertinoAlertDialog(
//         title: Text(
//           'note_editor_scan_discard_pages_title'.trParams({
//             'count': '${_pages.length}',
//           }),
//         ),
//         content: Text('note_editor_scan_discard_pages_message'.tr),
//         actions: [
//           CupertinoDialogAction(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: Text('note_editor_cancel'.tr),
//           ),
//           CupertinoDialogAction(
//             isDestructiveAction: true,
//             onPressed: () => Navigator.of(context).pop(true),
//             child: Text('note_editor_delete'.tr),
//           ),
//         ],
//       ),
//     );
//     if (shouldDiscard != true || !mounted) return;
//     await widget.onDiscardPages?.call(_pages);
//     if (mounted) Navigator.of(context).pop();
//   }
//   void _finish() {
//     if (_pages.isEmpty) return;
//     Navigator.of(
//       context,
//     ).pop(DocumentScanCameraResult(mode: _mode, pages: _pages));
//   }
//   void _setMode(DocumentScanCameraMode mode) {
//     if (!widget.allowModeToggle || mode == _mode) return;
//     setState(() => _mode = mode);
//   }
//   void _selectPreset(DocumentScanCameraFilterPreset preset) {
//     setState(() => _preset = preset);
//   }
//   String _presetLabel(DocumentScanCameraFilterPreset preset) => switch (preset) {
//     DocumentScanCameraFilterPreset.original =>
//       'note_editor_scan_filter_original'.tr,
//     DocumentScanCameraFilterPreset.grey => 'note_editor_scan_filter_gray'.tr,
//     DocumentScanCameraFilterPreset.blackAndWhite =>
//       'note_editor_scan_filter_bw'.tr,
//     DocumentScanCameraFilterPreset.darken =>
//       'note_editor_scan_filter_darken'.tr,
//     DocumentScanCameraFilterPreset.lighten =>
//       'note_editor_scan_filter_lighten'.tr,
//   };
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, _) {
//         if (!didPop) unawaited(_onClose());
//       },
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         body: Stack(
//           fit: StackFit.expand,
//           children: [
//             _buildCameraLayer(),
//             SafeArea(
//               child: Column(
//                 children: [
//                   _buildTopBar(),
//                   const Spacer(),
//                   if (_stage == _CameraStage.ready) ...[
//                     _buildFilterRow(),
//                     const SizedBox(height: 14),
//                     if (widget.allowModeToggle) ...[
//                       _ScanModeSegmentedControl(
//                         mode: _mode,
//                         onChanged: _setMode,
//                       ),
//                       const SizedBox(height: 14),
//                     ],
//                     _buildBottomBar(),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   Widget _buildCameraLayer() {
//     final controller = _controller;
//     if (_stage != _CameraStage.ready ||
//         controller == null ||
//         !controller.value.isInitialized) {
//       return ColoredBox(
//         color: Colors.black,
//         child: _buildStatusLayer(),
//       );
//     }
//     Widget preview = _CameraPreviewFill(controller: controller);
//     final colorFilter = switch (_preset) {
//       DocumentScanCameraFilterPreset.grey => grayscaleColorFilter,
//       DocumentScanCameraFilterPreset.blackAndWhite =>
//         highContrastGrayscaleColorFilter,
//       _ => null,
//     };
//     if (colorFilter != null) {
//       preview = ColorFiltered(colorFilter: colorFilter, child: preview);
//     }
//     final scrim = switch (_preset) {
//       DocumentScanCameraFilterPreset.darken => Colors.black.withValues(
//         alpha: 0.18,
//       ),
//       DocumentScanCameraFilterPreset.lighten => Colors.white.withValues(
//         alpha: 0.18,
//       ),
//       _ => null,
//     };
//     if (scrim != null) {
//       preview = Stack(
//         fit: StackFit.expand,
//         children: [preview, ColoredBox(color: scrim)],
//       );
//     }
//     return preview;
//   }
//   Widget _buildStatusLayer() {
//     switch (_stage) {
//       case _CameraStage.requestingPermission:
//       case _CameraStage.starting:
//         return const Center(
//           child: CupertinoActivityIndicator(color: Colors.white, radius: 14),
//         );
//       case _CameraStage.permissionDenied:
//         return _buildMessageState(
//           icon: CupertinoIcons.camera,
//           message: 'note_editor_scan_camera_permission_message'.tr,
//           actionLabel: _isPermanentlyDenied
//               ? 'note_editor_scan_open_settings'.tr
//               : 'note_list_retry'.tr,
//           onAction: _isPermanentlyDenied
//               ? _openSettings
//               : _ensurePermissionThenStart,
//         );
//       case _CameraStage.unavailable:
//         return _buildMessageState(
//           icon: CupertinoIcons.exclamationmark_triangle,
//           message: _errorMessage ?? 'note_editor_scan_camera_unavailable'.tr,
//           actionLabel: 'note_list_retry'.tr,
//           onAction: _ensurePermissionThenStart,
//         );
//       case _CameraStage.ready:
//         return const SizedBox.shrink();
//     }
//   }
//   Widget _buildMessageState({
//     required IconData icon,
//     required String message,
//     required String actionLabel,
//     required Future<void> Function() onAction,
//   }) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 48, color: Colors.white70),
//             const SizedBox(height: 16),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.white, fontSize: 15),
//             ),
//             const SizedBox(height: 20),
//             CustomGlassButton(
//               onPressed: () => unawaited(onAction()),
//               shape: GlassShape.oval,
//               opacity: 0.9,
//               glassColor: IosSemanticColors.purple,
//               foregroundColor: Colors.white,
//               child: Text(actionLabel),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   Widget _buildTopBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           _glassIconButton(icon: CupertinoIcons.xmark, onTap: _onClose),
//           if (_stage == _CameraStage.ready)
//             _glassIconButton(icon: _flashIcon, onTap: _cycleFlash)
//           else
//             const SizedBox(width: 44, height: 44),
//         ],
//       ),
//     );
//   }
//   Widget _glassIconButton({
//     required IconData icon,
//     required FutureOr<void> Function() onTap,
//   }) {
//     return CustomGlassButton(
//       onPressed: () => unawaited(Future.sync(onTap)),
//       width: 44,
//       height: 44,
//       padding: EdgeInsets.zero,
//       shape: GlassShape.circle,
//       foregroundColor: Colors.white,
//       blur: 10,
//       opacity: 0.15,
//       thickness: 8,
//       child: Icon(icon, size: 22),
//     );
//   }
//   Widget _buildFilterRow() {
//     final presets = DocumentScanCameraFilterPreset.values;
//     return SizedBox(
//       height: 40,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         itemCount: presets.length,
//         separatorBuilder: (_, _) => const SizedBox(width: 8),
//         itemBuilder: (context, index) {
//           final preset = presets[index];
//           return _FilterPresetChip(
//             label: _presetLabel(preset),
//             selected: preset == _preset,
//             accent: _accentColor,
//             onTap: () => _selectPreset(preset),
//           );
//         },
//       ),
//     );
//   }
//   Widget _buildBottomBar() {
//     final hasPages = _pages.isNotEmpty;
//     return Container(
//       padding: const EdgeInsets.only(bottom: 30),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (hasPages && _mode == DocumentScanCameraMode.capture)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 20),
//               child: CustomGlassButton(
//                 onPressed: _finish,
//                 shape: GlassShape.oval,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                 blur: 10,
//                 opacity: 0.9,
//                 glassColor: IosSemanticColors.purple,
//                 foregroundColor: Colors.white,
//                 child: Text(
//                   'note_editor_scan_pages_count'.trParams({
//                     'count': '${_pages.length}',
//                   }),
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 30),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _CameraBottomAction(
//                   icon: _flashIcon,
//                   label: 'Flash',
//                   onTap: _cycleFlash,
//                 ),
//                 _CameraBottomAction(
//                   icon: CupertinoIcons.circle_grid_3x3_fill,
//                   label: 'Filters',
//                   onTap: () {
//                     // This could toggle the filter row visibility if desired
//                   },
//                 ),
//                 _CameraBottomAction(
//                   icon: CupertinoIcons.viewfinder,
//                   label: 'Shutter',
//                   onTap: _onShutterTap,
//                 ),
//                 _CameraBottomAction(
//                   icon: CupertinoIcons.photo_on_rectangle,
//                   label: 'Gallery',
//                   onTap: _isPicking ? null : _onGalleryTap,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),
//           _ShutterButton(
//             isBusy: _isCapturing,
//             onTap: _isCapturing ? null : _onShutterTap,
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _CameraBottomAction extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;
//
//   const _CameraBottomAction({
//     required this.icon,
//     required this.label,
//     this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       behavior: HitTestBehavior.opaque,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha: 0.15),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: Colors.white, size: 22),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// class _CameraPreviewFill extends StatelessWidget {
//   final CameraController controller;
//   const _CameraPreviewFill({required this.controller});
//   @override
//   Widget build(BuildContext context) {
//     final previewSize = controller.value.previewSize;
//     if (previewSize == null) return CameraPreview(controller);
//     return ClipRect(
//       child: FittedBox(
//         fit: BoxFit.cover,
//         child: SizedBox(
//           width: previewSize.height,
//           height: previewSize.width,
//           child: CameraPreview(controller),
//         ),
//       ),
//     );
//   }
// }
// class _FilterPresetChip extends StatelessWidget {
//   final String label;
//   final bool selected;
//   final Color accent;
//   final VoidCallback onTap;
//   const _FilterPresetChip({
//     required this.label,
//     required this.selected,
//     required this.accent,
//     required this.onTap,
//   });
//   @override
//   Widget build(BuildContext context) {
//     return CustomGlassButton(
//       onPressed: onTap,
//       shape: GlassShape.oval,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       minHeight: 36,
//       blur: 10,
//       opacity: selected ? 0.9 : 0.15,
//       glassColor: selected ? accent : null,
//       foregroundColor: selected ? Colors.white : Colors.white70,
//       textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
//       child: Text(label),
//     );
//   }
// }
// class _ScanModeSegmentedControl extends StatelessWidget {
//   static const _segmentWidth = 96.0;
//   static const _height = 36.0;
//   final DocumentScanCameraMode mode;
//   final ValueChanged<DocumentScanCameraMode> onChanged;
//   const _ScanModeSegmentedControl({
//     required this.mode,
//     required this.onChanged,
//   });
//   @override
//   Widget build(BuildContext context) {
//     return CustomGlassContainer(
//       width: _segmentWidth * 2,
//       height: _height,
//       shape: GlassShape.oval,
//       blur: 10,
//       opacity: 0.2,
//       thickness: 8,
//       child: Stack(
//         children: [
//           AnimatedAlign(
//             duration: const Duration(milliseconds: 200),
//             curve: Curves.easeOut,
//             alignment: mode == DocumentScanCameraMode.capture
//                 ? Alignment.centerLeft
//                 : Alignment.centerRight,
//             child: Padding(
//               padding: const EdgeInsets.all(3),
//               child: Container(
//                 width: _segmentWidth - 6,
//                 height: _height - 6,
//                 decoration: BoxDecoration(
//                   color: mode == DocumentScanCameraMode.capture
//                       ? IosSemanticColors.purple
//                       : IosSemanticColors.indigo,
//                   borderRadius: BorderRadius.circular((_height - 6) / 2),
//                 ),
//               ),
//             ),
//           ),
//           Row(
//             children: [
//               _segment(DocumentScanCameraMode.capture, 'note_editor_scan_mode_capture'.tr),
//               _segment(DocumentScanCameraMode.ocr, 'note_editor_scan_mode_ocr'.tr),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//   Widget _segment(DocumentScanCameraMode value, String label) {
//     final selected = value == mode;
//     return SizedBox(
//       width: _segmentWidth,
//       height: _height,
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: () => onChanged(value),
//         child: Center(
//           child: Text(
//             label,
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
//               fontSize: 13,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
// class _ShutterButton extends StatelessWidget {
//   final bool isBusy;
//   final VoidCallback? onTap;
//   const _ShutterButton({required this.isBusy, required this.onTap});
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 74,
//         height: 74,
//         padding: const EdgeInsets.all(4),
//         decoration: const BoxDecoration(
//           shape: BoxShape.circle,
//           border: Border.fromBorderSide(
//             BorderSide(color: Colors.white, width: 3),
//           ),
//         ),
//         child: DecoratedBox(
//           decoration: const BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.white,
//           ),
//           child: isBusy
//               ? const Padding(
//                   padding: EdgeInsets.all(20),
//                   child: CupertinoActivityIndicator(),
//                 )
//               : null,
//         ),
//       ),
//     );
//   }
// }
