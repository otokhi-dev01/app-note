import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/features/profile/domain/entities/identity_document.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/usecases/identity_usecases.dart';

class DocumentUploadView extends StatefulWidget {
  final NationalIdCard? initialCard;
  final Future<String?> Function()? pickImage;

  const DocumentUploadView({super.key, this.initialCard, this.pickImage});

  @override
  State<DocumentUploadView> createState() => _DocumentUploadViewState();
}

class _DocumentUploadViewState extends State<DocumentUploadView> {
  final _formKey = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  String? _frontPath;
  String? _backPath;
  String? _error;
  bool _busy = false;

  static const _labels = {
    'DocumentType': 'document_type',
    'DocumentNumber': 'document_number',
    'FullName': 'document_full_name',
    'DateOfBirth': 'date_of_birth_label',
    'Gender': 'document_gender',
    'Nationality': 'document_nationality',
    'IssuingCountry': 'document_issuing_country',
    'IssuedDate': 'document_issued_date',
    'ExpiryDate': 'id_expiry_date_label',
    'IssuingAuthority': 'document_issuing_authority',
  };
  static const _dates = {'DateOfBirth', 'IssuedDate', 'ExpiryDate'};

  @override
  void initState() {
    super.initState();
    final card = widget.initialCard;
    String date(DateTime? value) =>
        value == null ? '' : DateFormat('yyyy-MM-dd').format(value);
    final initial = {
      'DocumentType': card == null
          ? ''
          : (card.documentType.isEmpty ? 'National ID' : card.documentType),
      'DocumentNumber': card?.idNumber ?? '',
      'FullName': card == null
          ? ''
          : (card.nameLatin.isEmpty ? card.nameKhmer : card.nameLatin),
      'DateOfBirth': date(card?.dateOfBirthAsDate),
      'ExpiryDate': date(card?.expiryDateAsDate),
      'Gender': card?.gender ?? '',
      'Nationality': card?.nationality ?? '',
      'IssuingCountry': card?.issuingCountry ?? '',
      'IssuedDate': date(card?.issuedDateAsDate),
      'IssuingAuthority': card?.issuingAuthority ?? '',
    };
    for (final key in _labels.keys) {
      _fields[key] = TextEditingController(text: initial[key] ?? '');
    }
    _frontPath = card?.frontImagePath;
    _backPath = card?.backImagePath;
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _text(String key) => _fields[key]!.text.trim();
  DateTime? _date(String key) => _text(key).isEmpty
      ? null
      : DateFormat('yyyy-MM-dd').parseStrict(_text(key));

  Future<void> _pick(bool front) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final path = widget.pickImage != null
          ? await widget.pickImage!()
          : (await ImagePicker().pickImage(source: ImageSource.gallery))?.path;
      if (!mounted || path == null) return;
      setState(() {
        if (front) {
          _frontPath = path;
        } else {
          _backPath = path;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'document_image_failed'.tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final document = IdentityDocument(
      documentType: _text('DocumentType'),
      documentNumber: _text('DocumentNumber'),
      fullName: _text('FullName'),
      dateOfBirth: _date('DateOfBirth'),
      gender: _text('Gender'),
      nationality: _text('Nationality'),
      issuingCountry: _text('IssuingCountry'),
      issuedDate: _date('IssuedDate'),
      expiryDate: _date('ExpiryDate'),
      issuingAuthority: _text('IssuingAuthority'),
      frontImagePath: _frontPath,
      backImagePath: _backPath,
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await Get.find<UploadIdentityDocument>()(document);
      if (!mounted) return;
      switch (result) {
        case Ok():
          Navigator.of(context).pop(document);
        case Err(:final failure):
          setState(() => _error = failure.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'document_upload_failed'.tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text('document_upload_title'.tr),
        leading: BackButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('document_upload_description'.tr),
                  const SizedBox(height: 20),
                  for (final key in _labels.keys)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        key: ValueKey(key),
                        controller: _fields[key],
                        enabled: !_busy,
                        keyboardType: _dates.contains(key)
                            ? TextInputType.datetime
                            : TextInputType.text,
                        decoration: InputDecoration(
                          labelText:
                              '${_labels[key]!.tr}${key == 'DocumentType' || key == 'DocumentNumber' ? ' *' : ''}',
                          hintText: _dates.contains(key) ? 'YYYY-MM-DD' : null,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if ((key == 'DocumentType' ||
                                  key == 'DocumentNumber') &&
                              text.isEmpty) {
                            return 'document_required'.tr;
                          }
                          if (_dates.contains(key) && text.isNotEmpty) {
                            try {
                              DateFormat('yyyy-MM-dd').parseStrict(text);
                            } on FormatException {
                              return 'document_invalid_date'.tr;
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  _image(true),
                  const SizedBox(height: 12),
                  _image(false),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('document_upload_action'.tr),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _image(bool front) {
    final path = front ? _frontPath : _backPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (path != null) ...[
          Image.file(
            File(path),
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Text('document_image_failed'.tr),
          ),
          Text(
            Uri.file(path).pathSegments.last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    if (front) {
                      _frontPath = null;
                    } else {
                      _backPath = null;
                    }
                  }),
            child: Text('document_remove_image'.tr),
          ),
        ],
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _pick(front),
          icon: const Icon(Icons.image_outlined),
          label: Text(
            (front ? 'document_choose_front' : 'document_choose_back').tr,
          ),
        ),
      ],
    );
  }
}
