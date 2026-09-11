import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:Note/features/daily_note/data/daily_note_store.dart';

class DailyNoteEditor extends StatefulWidget {
  final DailyNoteStore store;
  final DateTime date;
  final DailyNote? note;
  final int initialMinute;
  final ImagePicker? imagePicker;

  const DailyNoteEditor({
    super.key,
    required this.store,
    required this.date,
    this.note,
    required this.initialMinute,
    this.imagePicker,
  });

  @override
  State<DailyNoteEditor> createState() => _DailyNoteEditorState();
}

class _DailyNoteEditorState extends State<DailyNoteEditor> {
  static const _colors = [
    0xFFBA83B4,
    0xFF49B8AB,
    0xFFB38C65,
    0xFF778DCC,
    0xFFDC7894,
    0xFF9271E8,
  ];
  late final TextEditingController _title;
  late final TextEditingController _body;
  late int _start;
  late int _end;
  late int _color;
  late final List<String> _photos;
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  bool _capturing = false;
  bool get _busy => _saving || _capturing;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title);
    _body = TextEditingController(text: widget.note?.body);
    _start = widget.note?.startMinute ?? widget.initialMinute;
    _end = widget.note?.endMinute ?? math.min(_start + 60, 1439);
    _color = widget.note?.color ?? _colors.first;
    _photos = [...?widget.note?.photoPaths];
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final minute = start ? _start : math.min(_end, 1439);
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (time == null || !mounted) return;
    setState(() {
      if (start) {
        _start = time.hour * 60 + time.minute;
      } else {
        _end = time.hour * 60 + time.minute;
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_end <= _start) {
      setState(() => _error = 'daily_invalid_time'.tr);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.store.save(
        DailyNote(
          id: widget.note?.id ?? const Uuid().v4(),
          date: widget.date,
          title: _title.text.trim(),
          body: _body.text.trim(),
          startMinute: _start,
          endMinute: _end,
          color: _color,
          photoPaths: List.of(_photos),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'daily_save_error'.tr;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _capturing = true;
      _error = null;
    });
    try {
      final photo = await (widget.imagePicker ?? ImagePicker()).pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null && mounted) setState(() => _photos.add(photo.path));
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _error =
              (error.code == 'camera_access_denied' ||
                          error.code == 'camera_access_denied_without_prompt' ||
                          error.code == 'camera_access_restricted'
                      ? 'daily_camera_permission'
                      : 'daily_camera_error')
                  .tr,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'daily_camera_error'.tr);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _previewPhoto(String path) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'daily_cancel'.tr,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ),
          Flexible(
            child: InteractiveViewer(
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('daily_photo_unavailable'.tr),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _photoAttachments() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OutlinedButton.icon(
        onPressed: _busy ? null : _takePhoto,
        icon: _capturing
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.camera_alt_outlined),
        label: Text('daily_take_photo'.tr),
      ),
      if (_photos.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < _photos.length; index++)
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Semantics(
                        label: 'daily_view_photo'.trParams({
                          'number': '${index + 1}',
                        }),
                        button: true,
                        child: GestureDetector(
                          onTap: () => _previewPhoto(_photos[index]),
                          child: Image.file(
                            File(_photos[index]),
                            fit: BoxFit.cover,
                            cacheWidth: 300,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton.filled(
                        tooltip: 'daily_remove_photo'.tr,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _busy
                            ? null
                            : () => setState(() => _photos.removeAt(index)),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ],
  );

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('daily_delete_confirm'.tr),
        content: Text(widget.note!.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('daily_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('daily_delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.store.delete(widget.note!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'daily_save_error'.tr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String time(int minute) =>
        '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (widget.note == null ? 'daily_add' : 'daily_edit').tr,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'daily_cancel'.tr,
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                MaterialLocalizations.of(context).formatFullDate(widget.date),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('daily-note-title'),
                controller: _title,
                enabled: !_busy,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'daily_title_field'.tr,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'daily_title_required'.tr
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickTime(true),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(
                        '${'daily_start'.tr}\n${time(_start)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickTime(false),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(
                        '${'daily_end'.tr}\n${time(_end)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _body,
                enabled: !_busy,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'daily_body'.tr,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _photoAttachments(),
              const SizedBox(height: 16),
              Text('daily_color'.tr, style: theme.textTheme.labelLarge),
              Wrap(
                spacing: 6,
                children: [
                  for (var index = 0; index < _colors.length; index++)
                    Semantics(
                      selected: _color == _colors[index],
                      child: IconButton(
                        tooltip: 'daily_color_number'.trParams({
                          'number': '${index + 1}',
                        }),
                        onPressed: _busy
                            ? null
                            : () => setState(() => _color = _colors[index]),
                        icon: CircleAvatar(
                          radius: 15,
                          backgroundColor: Color(_colors[index]),
                          child: _color == _colors[index]
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.note != null) ...[
                    TextButton(
                      onPressed: _busy ? null : _delete,
                      child: Text(
                        'daily_delete'.tr,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('daily_save'.tr),
                    ),
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
