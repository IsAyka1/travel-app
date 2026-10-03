import 'package:flutter/material.dart';

import '../../app/travel_controller.dart';
import 'trip_action.dart';

Future<TripAction?> showTripActionEditor(
  BuildContext context, {
  required TravelController controller,
  required DateTime day,
  TripAction? action,
}) => showDialog<TripAction>(
  context: context,
  builder: (_) =>
      _TripActionEditorDialog(controller: controller, day: day, action: action),
);

class _TripActionEditorDialog extends StatefulWidget {
  const _TripActionEditorDialog({
    required this.controller,
    required this.day,
    this.action,
  });

  final TravelController controller;
  final DateTime day;
  final TripAction? action;

  @override
  State<_TripActionEditorDialog> createState() =>
      _TripActionEditorDialogState();
}

class _TripActionEditorDialogState extends State<_TripActionEditorDialog> {
  final formKey = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.action?.title ?? '');
  late final notes = TextEditingController(text: widget.action?.notes ?? '');
  late DateTime day = widget.action?.day ?? widget.day;
  late TimeOfDay? time = widget.action?.minutesFromMidnight == null
      ? null
      : TimeOfDay(
          hour: widget.action!.minutesFromMidnight! ~/ 60,
          minute: widget.action!.minutesFromMidnight! % 60,
        );
  late bool done = widget.action?.done ?? false;
  late ReservationStatus reservation =
      widget.action?.reservation ?? ReservationStatus.none;
  late String? placeId = widget.action?.placeId;
  late String? attachmentId = widget.action?.attachmentId;
  bool importing = false;
  String? importError;

  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(day.year - 100),
      lastDate: DateTime(day.year + 100),
    );
    if (picked != null) setState(() => day = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => time = picked);
  }

  Future<void> _importAttachment() async {
    setState(() {
      importing = true;
      importError = null;
    });
    try {
      final file = await widget.controller.importAttachment();
      if (mounted && file != null) setState(() => attachmentId = file.id);
    } catch (error) {
      if (mounted) {
        setState(() => importError = 'Could not attach file: $error');
      }
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final minutes = time == null ? null : time!.hour * 60 + time!.minute;
    final selectedPlaceId =
        widget.controller.places.any((place) => place.id == placeId)
        ? placeId
        : null;
    final selectedAttachmentId =
        widget.controller.files.any((file) => file.id == attachmentId)
        ? attachmentId
        : null;
    final result = widget.action == null
        ? TripAction.create(
            title: title.text.trim(),
            notes: notes.text.trim(),
            day: day,
            minutesFromMidnight: minutes,
            reservation: reservation,
            placeId: selectedPlaceId,
            attachmentId: selectedAttachmentId,
          ).copyWith(done: done)
        : widget.action!.copyWith(
            title: title.text.trim(),
            notes: notes.text.trim(),
            day: day,
            minutesFromMidnight: minutes,
            clearTime: minutes == null,
            done: done,
            reservation: reservation,
            placeId: selectedPlaceId,
            clearPlace: selectedPlaceId == null,
            attachmentId: selectedAttachmentId,
            clearAttachment: selectedAttachmentId == null,
          );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final places = widget.controller.places;
    final files = widget.controller.files;
    final selectedPlaceId = places.any((place) => place.id == placeId)
        ? placeId
        : null;
    final selectedAttachmentId = files.any((file) => file.id == attachmentId)
        ? attachmentId
        : null;
    return AlertDialog(
      title: Text(
        widget.action == null ? 'Add trip action' : 'Edit trip action',
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Action'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter an action'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDay,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        MaterialLocalizations.of(context).formatMediumDate(day),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        time == null
                            ? 'Set time (optional)'
                            : time!.format(context),
                      ),
                    ),
                    if (time != null)
                      IconButton(
                        tooltip: 'Remove time',
                        onPressed: () => setState(() => time = null),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<ReservationStatus>(
                  initialValue: reservation,
                  decoration: const InputDecoration(
                    labelText: 'Reservation / booking',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ReservationStatus.none,
                      child: Text('No reservation'),
                    ),
                    DropdownMenuItem(
                      value: ReservationStatus.need,
                      child: Text('Need reservation'),
                    ),
                    DropdownMenuItem(
                      value: ReservationStatus.has,
                      child: Text('Reservation confirmed'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => reservation = value);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedPlaceId ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Place (optional)',
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('No place')),
                    for (final place in places)
                      DropdownMenuItem(
                        value: place.id,
                        child: Text(place.name),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    placeId = value == null || value.isEmpty ? null : value;
                  }),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: ValueKey(selectedAttachmentId),
                  initialValue: selectedAttachmentId ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Attachment (optional)',
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('No attachment'),
                    ),
                    for (final file in files)
                      DropdownMenuItem(value: file.id, child: Text(file.name)),
                  ],
                  onChanged: (value) => setState(() {
                    attachmentId = value == null || value.isEmpty
                        ? null
                        : value;
                  }),
                ),
                if (widget.controller.supportsFiles) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: importing ? null : _importAttachment,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Import attachment from device'),
                  ),
                  if (importing) const LinearProgressIndicator(),
                ],
                if (importError != null) Text(importError!),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Done'),
                  value: done,
                  onChanged: (value) => setState(() => done = value ?? false),
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
        FilledButton(
          onPressed: importing ? null : _save,
          child: const Text('Save action'),
        ),
      ],
    );
  }
}
