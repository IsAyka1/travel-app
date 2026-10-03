import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../map/place_search_service.dart';
import 'place.dart';

Future<Place?> showPlaceEditor(
  BuildContext context, {
  Place? place,
  LatLng? location,
  String? initialName,
  DateTime? plannedFor,
  PlaceSearchService? searchService,
}) {
  return showDialog<Place>(
    context: context,
    builder: (_) => _PlaceEditorDialog(
      place: place,
      location: location,
      initialName: initialName,
      plannedFor: plannedFor,
      searchService: searchService ?? const PlaceSearchService(),
    ),
  );
}

class _PlaceEditorDialog extends StatefulWidget {
  const _PlaceEditorDialog({
    this.place,
    this.location,
    this.initialName,
    this.plannedFor,
    required this.searchService,
  });

  final Place? place;
  final LatLng? location;
  final String? initialName;
  final DateTime? plannedFor;
  final PlaceSearchService searchService;

  @override
  State<_PlaceEditorDialog> createState() => _PlaceEditorDialogState();
}

class _PlaceEditorDialogState extends State<_PlaceEditorDialog> {
  final formKey = GlobalKey<FormState>();
  final searchQuery = TextEditingController();
  bool searching = false;
  List<FoundPlace> searchResults = const [];
  String? searchMessage;
  FoundPlace? selectedResult;
  int searchVersion = 0;
  late DateTime? plannedFor = widget.place?.plannedFor ?? widget.plannedFor;
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
    searchVersion++;
    searchQuery.dispose();
    name.dispose();
    notes.dispose();
    latitude.dispose();
    longitude.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = searchQuery.text.trim();
    if (query.isEmpty) return;
    final version = ++searchVersion;
    setState(() {
      searching = true;
      searchResults = const [];
      searchMessage = null;
    });
    try {
      final found = await widget.searchService.search(query);
      if (!mounted || version != searchVersion) return;
      setState(() {
        searchResults = found;
        searchMessage = found.isEmpty
            ? 'No places found. Try another name or address.'
            : null;
      });
    } catch (_) {
      if (!mounted || version != searchVersion) return;
      setState(() {
        searchMessage = 'Search failed. Check your connection and try again.';
      });
    } finally {
      if (mounted && version == searchVersion) {
        setState(() => searching = false);
      }
    }
  }

  void _selectResult(FoundPlace result) {
    FocusScope.of(context).unfocus();
    name.text = result.name;
    latitude.text = result.point.latitude.toString();
    longitude.text = result.point.longitude.toString();
    setState(() {
      selectedResult = result;
      searchResults = const [];
      searchMessage = null;
    });
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

  Future<void> _pickDate() async {
    final initialDate = plannedFor ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(initialDate.year - 100),
      lastDate: DateTime(initialDate.year + 100),
    );
    if (picked != null) setState(() => plannedFor = picked);
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final result = widget.place == null
        ? Place.create(
            name: name.text.trim(),
            notes: notes.text.trim(),
            latitude: _number(latitude.text)!,
            longitude: _number(longitude.text)!,
            plannedFor: plannedFor,
          )
        : widget.place!.copyWith(
            name: name.text.trim(),
            notes: notes.text.trim(),
            latitude: _number(latitude.text)!,
            longitude: _number(longitude.text)!,
            plannedFor: plannedFor,
            clearPlannedFor: plannedFor == null,
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
              TextField(
                controller: searchQuery,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                onChanged: (_) {
                  searchVersion++;
                  if (searchResults.isNotEmpty ||
                      searchMessage != null ||
                      searching) {
                    setState(() {
                      searchResults = const [];
                      searchMessage = null;
                      searching = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Find on map',
                  hintText: 'City, address, or landmark',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Search map',
                    onPressed: searching ? null : _search,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
              if (searching) const LinearProgressIndicator(),
              if (searchMessage != null) ...[
                const SizedBox(height: 8),
                Text(searchMessage!),
              ],
              for (final result in searchResults)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(result.name),
                  subtitle: result.details.isEmpty
                      ? null
                      : Text(
                          result.details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () => _selectResult(result),
                ),
              if (selectedResult != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selected on map: ${selectedResult!.name}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 170,
                    child: IgnorePointer(
                      child: FlutterMap(
                        key: ValueKey(selectedResult!.point),
                        options: MapOptions(
                          initialCenter: selectedResult!.point,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.isayka1.travelatlas',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: selectedResult!.point,
                                width: 42,
                                height: 42,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.deepOrange,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: name,
                autofocus: widget.place != null || widget.location != null,
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
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        plannedFor == null
                            ? 'Set visit date (optional)'
                            : MaterialLocalizations.of(context)
                                  .formatMediumDate(plannedFor!),
                      ),
                    ),
                  ),
                  if (plannedFor != null)
                    IconButton(
                      tooltip: 'Remove visit date',
                      onPressed: () => setState(() => plannedFor = null),
                      icon: const Icon(Icons.close),
                    ),
                ],
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
                      onChanged: (_) {
                        if (selectedResult != null) {
                          setState(() => selectedResult = null);
                        }
                      },
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
                      onChanged: (_) {
                        if (selectedResult != null) {
                          setState(() => selectedResult = null);
                        }
                      },
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
