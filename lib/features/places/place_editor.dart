import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'place.dart';

Future<Place?> showPlaceEditor(
  BuildContext context, {
  Place? place,
  LatLng? location,
  String? initialName,
}) {
  return showDialog<Place>(
    context: context,
    builder: (_) => _PlaceEditorDialog(
      place: place,
      location: location,
      initialName: initialName,
    ),
  );
}

class _PlaceEditorDialog extends StatefulWidget {
  const _PlaceEditorDialog({this.place, this.location, this.initialName});

  final Place? place;
  final LatLng? location;
  final String? initialName;

  @override
  State<_PlaceEditorDialog> createState() => _PlaceEditorDialogState();
}

class _PlaceEditorDialogState extends State<_PlaceEditorDialog> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: widget.place?.name ?? widget.initialName ?? '',
  );
  late final notes = TextEditingController(text: widget.place?.notes ?? '');
  late final latitude = TextEditingController(
    text:
        widget.place?.latitude.toString() ??
        widget.location?.latitude.toString() ??
        '',
  );
  late final longitude = TextEditingController(
    text:
        widget.place?.longitude.toString() ??
        widget.location?.longitude.toString() ??
        '',
  );

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    latitude.dispose();
    longitude.dispose();
    super.dispose();
  }

  double? _number(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  String? _coordinateError(String? text, double min, double max) {
    final value = _number(text ?? '');
    if (value == null || !value.isFinite || value < min || value > max) {
      return 'Enter a number from $min to $max';
    }
    return null;
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final result = widget.place == null
        ? Place.create(
            name: name.text.trim(),
            notes: notes.text.trim(),
            latitude: _number(latitude.text)!,
            longitude: _number(longitude.text)!,
          )
        : widget.place!.copyWith(
            name: name.text.trim(),
            notes: notes.text.trim(),
            latitude: _number(latitude.text)!,
            longitude: _number(longitude.text)!,
          );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.place == null ? 'Add a place' : 'Edit place'),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Place name'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a place name'
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: latitude,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: '48.8584',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) => _coordinateError(value, -90, 90),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: longitude,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: '2.2945',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) => _coordinateError(value, -180, 180),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tip: long-press the map to fill coordinates automatically.',
                ),
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
      FilledButton(onPressed: _save, child: const Text('Save place')),
    ],
  );
}
