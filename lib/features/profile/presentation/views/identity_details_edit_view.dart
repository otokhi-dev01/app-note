import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';

class IdentityDetailsEditView extends StatefulWidget {
  const IdentityDetailsEditView({
    super.key,
    required this.card,
    required this.onSave,
  });
  final NationalIdCard card;
  final Future<bool> Function(NationalIdCard) onSave;

  @override
  State<IdentityDetailsEditView> createState() =>
      _IdentityDetailsEditViewState();
}

class _IdentityDetailsEditViewState extends State<IdentityDetailsEditView> {
  late final _fields = [
    TextEditingController(text: widget.card.nameKhmer),
    TextEditingController(text: widget.card.placeOfBirthKhmer),
    TextEditingController(text: widget.card.placeOfBirthEnglish),
    TextEditingController(text: widget.card.currentAddressKhmer),
    TextEditingController(text: widget.card.currentAddressEnglish),
  ];
  bool _saving = false;

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      final saved = await widget.onSave(
        widget.card.copyWith(
          nameKhmer: _fields[0].text.trim(),
          placeOfBirthKhmer: _fields[1].text.trim(),
          placeOfBirthEnglish: _fields[2].text.trim(),
          currentAddressKhmer: _fields[3].text.trim(),
          currentAddressEnglish: _fields[4].text.trim(),
        ),
      );
      if (mounted && saved) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      'identity_name_khmer_label',
      'identity_birth_place_khmer',
      'identity_birth_place_english',
      'identity_address_khmer',
      'identity_address_english',
    ];
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text('identity_edit_details'.tr)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('identity_missing_fields_hint'.tr),
              const SizedBox(height: 20),
              for (var i = 0; i < _fields.length; i++) ...[
                TextField(
                  key: ValueKey(labels[i]),
                  controller: _fields[i],
                  enabled: !_saving,
                  minLines: 1,
                  maxLines: i == 0 ? 1 : 3,
                  maxLength: i == 0 ? 100 : 240,
                  decoration: InputDecoration(
                    labelText: labels[i].tr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('identity_save_details'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
