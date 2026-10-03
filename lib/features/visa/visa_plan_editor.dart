import 'package:flutter/material.dart';

import 'visa_plan.dart';

Future<VisaPlan?> showVisaPlanEditor(BuildContext context, {VisaPlan? plan}) =>
    showDialog<VisaPlan>(
      context: context,
      builder: (_) => _VisaPlanEditorDialog(plan: plan),
    );

enum _Answer { notSet, yes, no }

_Answer _answerFor(bool? value) => switch (value) {
  true => _Answer.yes,
  false => _Answer.no,
  null => _Answer.notSet,
};

bool? _valueFor(_Answer answer) => switch (answer) {
  _Answer.yes => true,
  _Answer.no => false,
  _Answer.notSet => null,
};

class _VisaPlanEditorDialog extends StatefulWidget {
  const _VisaPlanEditorDialog({this.plan});

  final VisaPlan? plan;

  @override
  State<_VisaPlanEditorDialog> createState() => _VisaPlanEditorDialogState();
}

class _VisaPlanEditorDialogState extends State<_VisaPlanEditorDialog> {
  final formKey = GlobalKey<FormState>();
  late final destination = TextEditingController(
    text: widget.plan?.destination ?? '',
  );
  late final stayDays = TextEditingController(
    text: widget.plan?.allowedStayDays?.toString() ?? '',
  );
  late _Answer visa = _answerFor(widget.plan?.visaRequired);
  late _Answer application = _answerFor(widget.plan?.applicationRequired);

  @override
  void dispose() {
    destination.dispose();
    stayDays.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final days = stayDays.text.trim().isEmpty
        ? null
        : int.parse(stayDays.text.trim());
    final result = widget.plan == null
        ? VisaPlan.create(
            destination: destination.text.trim(),
            visaRequired: _valueFor(visa),
            applicationRequired: _valueFor(application),
            allowedStayDays: days,
          )
        : widget.plan!.withDetails(
            destination: destination.text.trim(),
            visaRequired: _valueFor(visa),
            applicationRequired: _valueFor(application),
            allowedStayDays: days,
          );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.plan == null ? 'Add visa block' : 'Edit visa block'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: destination,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Destination or country',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a destination'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<_Answer>(
                initialValue: visa,
                decoration: const InputDecoration(labelText: 'Need visa?'),
                items: const [
                  DropdownMenuItem(
                    value: _Answer.notSet,
                    child: Text('Not set'),
                  ),
                  DropdownMenuItem(value: _Answer.yes, child: Text('Yes')),
                  DropdownMenuItem(value: _Answer.no, child: Text('No')),
                ],
                onChanged: (value) => setState(() => visa = value!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<_Answer>(
                initialValue: application,
                decoration: const InputDecoration(
                  labelText: 'Need application?',
                ),
                items: const [
                  DropdownMenuItem(
                    value: _Answer.notSet,
                    child: Text('Not set'),
                  ),
                  DropdownMenuItem(value: _Answer.yes, child: Text('Yes')),
                  DropdownMenuItem(value: _Answer.no, child: Text('No')),
                ],
                onChanged: (value) => setState(() => application = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: stayDays,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Can stay (days, optional)',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final days = int.tryParse(text);
                  return days == null || days <= 0
                      ? 'Enter a positive number of days'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
