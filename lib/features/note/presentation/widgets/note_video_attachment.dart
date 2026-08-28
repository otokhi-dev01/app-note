import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/core/utils/share_helper.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';

const _videoExtensions = {
  'mp4',
  'mov',
  'm4v',
  'avi',
  'mkv',
  'webm',
  '3gp',
  '3g2',
  'mpeg',
  'mpg',
  'ts',
};

/// Whether an attachment should render as a playable video instead of a
/// generic file. The backend does not currently return a media type, so the
/// original name, persisted path, and remote URL are all valid signals.
bool looksLikeVideoAttachment(AttachmentBlock block) {
  for (final candidate in [block.displayName, block.localPath, block.url]) {
    final value = candidate?.trim() ?? '';
    if (value.isEmpty) continue;

    final path = Uri.tryParse(value)?.path ?? value;
    final dot = path.lastIndexOf('.');
    if (dot == -1) continue;

    final extension = path.substring(dot + 1).toLowerCase();
    if (_videoExtensions.contains(extension)) return true;
  }
  return false;
}

/// Inline video attachment used by both the create-note and note-detail
/// editors. It stays paused in the note and opens a dedicated player on tap.
class NoteVideoAttachment extends StatefulWidget {
  final AttachmentBlock block;
  final bool isReadOnly;
  final VoidCallback onDelete;

  const NoteVideoAttachment({
    super.key,
    required this.block,
    required this.isReadOnly,
    required this.onDelete,
  });

  @override
  State<NoteVideoAttachment> createState() => _NoteVideoAttachmentState();
}

class _NoteVideoAttachmentState extends State<NoteVideoAttachment> {
  final _menuController = lg.GlassMenuController();
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializePreview());
  }

  @override
  void didUpdateWidget(covariant NoteVideoAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.localPath != widget.block.localPath ||
        oldWidget.block.url != widget.block.url) {
      unawaited(_initializePreview());
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _initializePreview() async {
    final previous = _controller;
    _controller = null;
    if (previous != null) await previous.dispose();

    final controller = _videoControllerFor(widget.block);
    if (controller == null) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    _controller = controller;
    if (mounted) setState(() => _hasError = false);

    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (mounted && identical(_controller, controller)) setState(() {});
    } catch (error) {
      debugPrint('[VIDEO PREVIEW ERROR] $error');
      if (mounted && identical(_controller, controller)) {
        setState(() => _hasError = true);
      }
    }
  }

  Future<void> _openPlayer() async {
    if (!_hasVideoSource(widget.block)) {
      AppSnackbar.info(
        'note_editor_not_available_title'.tr,
        'note_editor_video_not_available'.tr,
      );
      return;
    }

    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _VideoPreviewPage(block: widget.block),
      ),
    );
  }

  Future<void> _shareVideo() async {
    final path = normalizeLocalPath(widget.block.localPath);
    if (path == null || !File(path).existsSync()) {
      AppSnackbar.info(
        'note_editor_not_available_title'.tr,
        'note_editor_video_not_on_device'.tr,
      );
      return;
    }

    try {
      await shareXFilesSafely(context, [XFile(path)]);
    } catch (error) {
      debugPrint('[VIDEO SHARE ERROR] $error');
      AppSnackbar.error(
        'note_editor_error_title'.tr,
        'note_editor_could_not_share_video'.tr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rawName = widget.block.displayName.trim();
    final name = rawName.isEmpty
        ? 'note_editor_video_fallback_name'.tr
        : rawName;
    final controller = _controller;
    final isReady = controller?.value.isInitialized ?? false;

    return Semantics(
      button: true,
      label: 'note_editor_video_semantic_label'.trParams({'name': name}),
      hint: 'note_editor_tap_to_play'.tr,
      child: lg.GlassMenu(
        controller: _menuController,
        menuWidth: 250,
        autoAdjustToScreen: true,
        menuPadding: const EdgeInsets.all(12),
        morphFromZero: true,
        triggerBuilder: (context, _) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openPlayer,
          onLongPress: _menuController.open,
          child: Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isReady)
                  Center(
                    child: AspectRatio(
                      aspectRatio: _safeAspectRatio(controller!),
                      child: VideoPlayer(controller),
                    ),
                  )
                else if (_hasError)
                  const _VideoUnavailable()
                else
                  const Center(
                    child: CupertinoActivityIndicator(color: Colors.white),
                  ),
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        items: [
          lg.GlassMenuItem(
            title: 'note_editor_play_video'.tr,
            icon: const Icon(
              CupertinoIcons.play_fill,
              color: IosSemanticColors.blue,
            ),
            onTap: _openPlayer,
          ),
          lg.GlassMenuItem(
            title: 'note_editor_share'.tr,
            icon: const Icon(
              CupertinoIcons.share,
              color: IosSemanticColors.blue,
            ),
            onTap: _shareVideo,
          ),
          if (!widget.isReadOnly) ...[
            const lg.GlassMenuDivider(),
            lg.GlassMenuItem(
              title: 'note_editor_delete'.tr,
              icon: const Icon(
                CupertinoIcons.trash,
                color: IosSemanticColors.red,
              ),
              isDestructive: true,
              onTap: widget.onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _VideoPreviewPage extends StatefulWidget {
  final AttachmentBlock block;

  const _VideoPreviewPage({required this.block});

  @override
  State<_VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<_VideoPreviewPage> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _initialize() async {
    final controller = _videoControllerFor(widget.block);
    if (controller == null) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('[VIDEO PLAY ERROR] $error');
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      if (controller.value.isCompleted) await controller.seekTo(Duration.zero);
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller?.value.isInitialized ?? false;
    final name = widget.block.displayName.trim();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isReady)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayback,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _safeAspectRatio(controller!),
                    child: VideoPlayer(controller),
                  ),
                ),
              )
            else if (_hasError)
              const _VideoUnavailable()
            else
              const Center(
                child: CupertinoActivityIndicator(
                  radius: 15,
                  color: Colors.white,
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  _OverlayButton(
                    icon: CupertinoIcons.xmark,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name.isEmpty
                          ? 'note_editor_video_fallback_name'.tr
                          : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isReady)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: AnimatedBuilder(
                  animation: controller!,
                  builder: (context, _) => _VideoControls(
                    controller: controller,
                    onTogglePlayback: _togglePlayback,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onTogglePlayback;

  const _VideoControls({
    required this.controller,
    required this.onTogglePlayback,
  });

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            colors: const VideoProgressColors(
              playedColor: Colors.white,
              bufferedColor: Colors.white38,
              backgroundColor: Colors.white24,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTogglePlayback,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    value.isPlaying
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_formatDuration(value.position)} / '
                '${_formatDuration(value.duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _VideoUnavailable extends StatelessWidget {
  const _VideoUnavailable();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.video_camera, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              'note_editor_video_not_available'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

VideoPlayerController? _videoControllerFor(AttachmentBlock block) {
  final localPath = normalizeLocalPath(block.localPath);
  if (localPath != null && File(localPath).existsSync()) {
    return VideoPlayerController.file(File(localPath));
  }

  final networkUrl = normalizeAttachmentUrl(block.url);
  final uri = networkUrl == null ? null : Uri.tryParse(networkUrl);
  if (uri == null) return null;

  return VideoPlayerController.networkUrl(
    uri,
    httpHeaders: attachmentAuthHeaders() ?? const {},
  );
}

bool _hasVideoSource(AttachmentBlock block) {
  final localPath = normalizeLocalPath(block.localPath);
  if (localPath != null && File(localPath).existsSync()) return true;

  final networkUrl = normalizeAttachmentUrl(block.url);
  return networkUrl != null && Uri.tryParse(networkUrl) != null;
}

double _safeAspectRatio(VideoPlayerController controller) {
  final ratio = controller.value.aspectRatio;
  return ratio.isFinite && ratio > 0 ? ratio : 16 / 9;
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
