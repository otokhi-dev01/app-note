import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/core/utils/share_helper.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_media_context_menu.dart';
import 'package:Note/features/note/presentation/widgets/note_media_cursor_edges.dart';
import 'package:Note/features/note/presentation/widgets/note_media_title.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

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
  final int blockIndex;
  final NoteDetailController controller;
  final bool isReadOnly;
  final VoidCallback onDelete;

  const NoteVideoAttachment({
    super.key,
    required this.block,
    required this.blockIndex,
    required this.controller,
    required this.isReadOnly,
    required this.onDelete,
  });

  @override
  State<NoteVideoAttachment> createState() => _NoteVideoAttachmentState();
}

class _NoteVideoAttachmentState extends State<NoteVideoAttachment> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  NoteMediaCursorSide? _cursorSide;

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
    if (_cursorSide != null && mounted) setState(() => _cursorSide = null);
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
        builder: (_) => _VideoPreviewPage(
          block: widget.block,
          onShare: () => _shareVideo(),
        ),
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

  void _showContextMenu() {
    if (_cursorSide != null) setState(() => _cursorSide = null);
    final controller = _controller;
    final isReady = controller?.value.isInitialized ?? false;
    NoteMediaContextMenu.show(
      context: context,
      preview: ColoredBox(
        color: Colors.black,
        child: _buildVideoSurface(controller, isReady),
      ),
      previewHeight: 300,
      actions: [
        NoteMediaMenuAction(
          title: 'note_editor_copy'.tr,
          icon: CupertinoIcons.doc_on_doc,
          onTap: () => unawaited(
            widget.controller.copyAttachmentBlock(widget.blockIndex),
          ),
        ),
        if (!widget.isReadOnly)
          NoteMediaMenuAction(
            title: 'note_editor_paste'.tr,
            icon: Icons.content_paste_rounded,
            onTap: () => unawaited(
              widget.controller.pasteClipboardContent(
                afterIndex: widget.blockIndex,
              ),
            ),
          ),
        if (!widget.isReadOnly)
          NoteMediaMenuAction(
            title: 'note_editor_cut'.tr,
            icon: Icons.content_cut_rounded,
            onTap: () => unawaited(
              widget.controller.cutAttachmentBlock(widget.blockIndex),
            ),
          ),
        if (!widget.isReadOnly)
          NoteMediaMenuAction(
            title: 'note_editor_delete'.tr,
            icon: CupertinoIcons.trash,
            isDestructive: true,
            onTap: widget.onDelete,
          ),
        NoteMediaMenuAction(
          title: 'note_editor_share'.tr,
          icon: CupertinoIcons.share,
          onTap: () => unawaited(_shareVideo()),
        ),
        NoteMediaMenuAction(
          title: 'note_editor_play_video'.tr,
          icon: CupertinoIcons.play_fill,
          onTap: () => unawaited(_openPlayer()),
        ),
      ],
    );
  }

  void _focusVideoEdge(NoteMediaCursorSide side) {
    setState(() => _cursorSide = side);
    widget.controller.focusTextBesideAttachment(
      widget.blockIndex,
      after: side == NoteMediaCursorSide.after,
    );
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

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: _showContextMenu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NoteMediaTitle(
            displayName: widget.block.displayName,
            fallbackTitle: 'note_editor_video_fallback_name'.tr,
            fixedTitle: 'note_editor_video_fallback_name'.tr,
            isReadOnly: widget.isReadOnly,
            onChanged: (title) => widget.controller.updateAttachmentTitle(
              widget.blockIndex,
              title,
            ),
          ),
          Semantics(
            button: true,
            label: 'note_editor_video_semantic_label'.trParams({'name': name}),
            hint: 'note_editor_tap_to_play'.tr,
            child: GestureDetector(
              key: ValueKey('video-inline-preview-${widget.block.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: _openPlayer,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: _cursorSide != null
                        ? AppTheme.folderYellow
                        : isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    width: _cursorSide != null ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.06,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: isReady ? _safeAspectRatio(controller!) : 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildVideoSurface(controller, isReady),
                      if (!widget.isReadOnly)
                        NoteMediaCursorEdges(
                          keyPrefix: 'video',
                          focusedSide: _cursorSide,
                          beforeSemanticLabel:
                              'note_editor_write_before_video'.tr,
                          afterSemanticLabel:
                              'note_editor_write_after_video'.tr,
                          onFocusBefore: () =>
                              _focusVideoEdge(NoteMediaCursorSide.before),
                          onFocusAfter: () =>
                              _focusVideoEdge(NoteMediaCursorSide.after),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSurface(VideoPlayerController? controller, bool isReady) {
    return Stack(
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
          const Center(child: CupertinoActivityIndicator(color: Colors.white)),
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
    );
  }
}

class _VideoPreviewPage extends StatefulWidget {
  final AttachmentBlock block;
  final VoidCallback onShare;

  const _VideoPreviewPage({required this.block, required this.onShare});

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
    final theme = Theme.of(context);
    final controller = _controller;
    final isReady = controller?.value.isInitialized ?? false;
    final title = 'note_editor_video_fallback_name'.tr;

    return Scaffold(
      key: const ValueKey('video-preview-page'),
      backgroundColor: Colors.black,
      appBar: CustomGlassAppBar(
        key: const ValueKey('video-preview-app-bar'),
        toolbarHeight: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: CustomGlassButton(
          key: const ValueKey('video-preview-close'),
          semanticLabel: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
          width: 44,
          height: 44,
          shape: GlassShape.circle,
          blur: 10,
          opacity: 0.15,
          thickness: 8,
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.xmark,
            color: theme.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          CustomGlassButton(
            key: const ValueKey('video-preview-share'),
            semanticLabel: 'note_editor_share'.tr,
            onPressed: widget.onShare,
            width: 44,
            height: 44,
            shape: GlassShape.circle,
            blur: 10,
            opacity: 0.15,
            thickness: 8,
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.share,
              color: theme.primaryColor,
              size: 22,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isReady)
                GestureDetector(
                  key: const ValueKey('video-preview-content'),
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
