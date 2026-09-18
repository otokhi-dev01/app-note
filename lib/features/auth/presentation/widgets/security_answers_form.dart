import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/features/auth/domain/entities/security_question.dart';

/// Answers only live in this form and are disposed when recovery leaves it.
class SecurityAnswersForm extends StatefulWidget {
  final List<SecurityQuestion> questions;
  final bool enabled;
  final ValueChanged<List<SecurityAnswer>> onChanged;

  const SecurityAnswersForm({
    super.key,
    required this.questions,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<SecurityAnswersForm> createState() => _SecurityAnswersFormState();
}

class _SecurityAnswersFormState extends State<SecurityAnswersForm> {
  final _rows = [_AnswerRow()];

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  void _notify() => widget.onChanged([
    for (final row in _rows)
      SecurityAnswer(
        questionId: row.questionId ?? '',
        answer: row.controller.text,
      ),
  ]);

  @override
  Widget build(BuildContext context) {
    final selected = _rows.map((row) => row.questionId).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, row) in _rows.indexed)
          Padding(
            key: ObjectKey(row),
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: row.questionId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'recovery_question_number'.trParams({
                      'number': '${index + 1}',
                    }),
                  ),
                  items: [
                    for (final question in widget.questions)
                      if (question.id == row.questionId ||
                          !selected.contains(question.id))
                        DropdownMenuItem(
                          value: question.id,
                          child: Text(
                            question.question,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                  onChanged: !widget.enabled
                      ? null
                      : (id) {
                          setState(() {
                            row.questionId = id;
                            row.controller.clear();
                          });
                          _notify();
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: row.controller,
                  enabled: widget.enabled && row.questionId != null,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'recovery_security_answer'.tr,
                  ),
                  onChanged: (_) => _notify(),
                ),
                if (_rows.length > 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: !widget.enabled
                          ? null
                          : () {
                              setState(() => _rows.remove(row));
                              // The field still owns this controller until this frame ends.
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => row.controller.dispose(),
                              );
                              _notify();
                            },
                      child: Text('recovery_remove_question'.tr),
                    ),
                  ),
              ],
            ),
          ),
        if (_rows.length < widget.questions.length)
          TextButton.icon(
            onPressed: !widget.enabled
                ? null
                : () {
                    setState(() => _rows.add(_AnswerRow()));
                    _notify();
                  },
            icon: const Icon(Icons.add),
            label: Text('recovery_add_question'.tr),
          ),
      ],
    );
  }
}

class _AnswerRow {
  String? questionId;
  final controller = TextEditingController();
}
