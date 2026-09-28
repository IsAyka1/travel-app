import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/travel_controller.dart';
import '../places/place.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.controller,
    required this.focus,
    required this.onAddAt,
  });

  final TravelController controller;
  final Place? focus;
  final ValueChanged<LatLng> onAddAt;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final mapController = MapController();
  bool mapReady = false;

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
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explore the map',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${places.length} saved places · Long-press to add one',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
