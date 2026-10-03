import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/travel_controller.dart';
import '../places/place.dart';
import 'place_search_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.controller,
    required this.focus,
    required this.onAddAt,
    required this.onSaveFoundPlace,
  });

  final TravelController controller;
  final Place? focus;
  final ValueChanged<LatLng> onAddAt;
  final ValueChanged<FoundPlace> onSaveFoundPlace;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final mapController = MapController();
  final searchController = TextEditingController();
  final searchService = const PlaceSearchService();
  bool mapReady = false;
  bool searching = false;
  List<FoundPlace> results = const [];
  FoundPlace? selectedResult;
  String? searchMessage;
  int searchVersion = 0;

  Future<void> _search() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;
    final version = ++searchVersion;
    setState(() {
      searching = true;
      results = const [];
      selectedResult = null;
      searchMessage = null;
    });
    try {
      final found = await searchService.search(query);
      if (!mounted || version != searchVersion) return;
      setState(() {
        results = found;
        searchMessage = found.isEmpty
            ? 'No places found. Try another name or address.'
            : null;
      });
    } catch (_) {
      if (!mounted || version != searchVersion) return;
      setState(
        () => searchMessage =
            'Search failed. Check your connection and try again.',
      );
    } finally {
      if (mounted && version == searchVersion) {
        setState(() => searching = false);
      }
    }
  }

  void _selectResult(FoundPlace place) {
    FocusScope.of(context).unfocus();
    setState(() {
      selectedResult = place;
      results = const [];
      searchMessage = null;
    });
    if (mapReady) mapController.move(place.point, 14);
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (mapReady &&
        widget.focus != null &&
        widget.focus?.id != oldWidget.focus?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        mapController.move(
          LatLng(widget.focus!.latitude, widget.focus!.longitude),
          12,
        );
      });
    }
  }

  @override
  void dispose() {
    searchVersion++;
    searchController.dispose();
    mapController.dispose();
    super.dispose();
  }

  void _showPlace(Place place) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(place.visited ? 'Visited' : 'Want to visit'),
            if (place.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(place.notes),
            ],
            const SizedBox(height: 12),
            Text(
              '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = widget.controller.places;
    final initial = widget.focus ?? (places.isEmpty ? null : places.first);
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: initial == null
                ? const LatLng(20, 0)
                : LatLng(initial.latitude, initial.longitude),
            initialZoom: initial == null ? 2.5 : 10,
            minZoom: 2,
            maxZoom: 18,
            onMapReady: () => mapReady = true,
            onLongPress: (_, point) => widget.onAddAt(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.isayka1.travelatlas',
            ),
            MarkerLayer(
              markers: [
                if (selectedResult != null)
                  Marker(
                    point: selectedResult!.point,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.deepOrange,
                      size: 44,
                    ),
                  ),
                for (final place in places)
                  Marker(
                    point: LatLng(place.latitude, place.longitude),
                    width: 46,
                    height: 46,
                    child: IconButton.filled(
                      tooltip: place.name,
                      icon: Icon(place.visited ? Icons.check : Icons.place),
                      onPressed: () => _showPlace(place),
                    ),
                  ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        Positioned(
          left: 16,
          top: 16,
          right: 16,
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                maxHeight:
                    (MediaQuery.sizeOf(context).height -
                            MediaQuery.viewInsetsOf(context).bottom -
                            120)
                        .clamp(180, 400),
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _search(),
                          decoration: InputDecoration(
                            hintText: 'Search cities, addresses, landmarks',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              tooltip: 'Search places',
                              onPressed: searching ? null : _search,
                              icon: const Icon(Icons.arrow_forward),
                            ),
                          ),
                        ),
                        if (searching) const LinearProgressIndicator(),
                        if (searchMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(searchMessage!),
                          ),
                        for (final result in results)
                          ListTile(
                            dense: true,
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
                          const SizedBox(height: 12),
                          Text(
                            selectedResult!.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (selectedResult!.details.isNotEmpty)
                            Text(selectedResult!.details),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () =>
                                widget.onSaveFoundPlace(selectedResult!),
                            icon: const Icon(Icons.bookmark_add_outlined),
                            label: const Text('Save to places to visit'),
                          ),
                        ],
                        if (results.isEmpty &&
                            selectedResult == null &&
                            searchMessage == null &&
                            !searching)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              '${places.length} saved places · Long-press the map to add one',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
