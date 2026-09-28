import 'package:flutter/material.dart';

import '../../app/travel_controller.dart';
import 'place.dart';
import 'place_editor.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({
    super.key,
    required this.controller,
    required this.onAdd,
    required this.onShowOnMap,
  });

  final TravelController controller;
  final VoidCallback onAdd;
  final ValueChanged<Place> onShowOnMap;

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  String query = '';
  int filter = 0;

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save place: $error')));
      }
    }
  }

  Future<void> _edit(Place place) async {
    final edited = await showPlaceEditor(context, place: place);
    if (edited != null) await _run(() => widget.controller.updatePlace(edited));
  }

  Future<void> _delete(Place place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete place?'),
        content: Text('Remove ${place.name} from your saved places?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => widget.controller.deletePlace(place.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = widget.controller.places.where((place) {
      final matchesQuery =
          place.name.toLowerCase().contains(query.toLowerCase()) ||
          place.notes.toLowerCase().contains(query.toLowerCase());
      final matchesFilter =
          filter == 0 ||
          (filter == 1 && !place.visited) ||
          (filter == 2 && place.visited);
      return matchesQuery && matchesFilter;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Places to visit',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Keep a list of the destinations that matter to you.',
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add place'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search places and notes',
            filled: true,
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            for (final (index, label) in [
              (0, 'All'),
              (1, 'Want to visit'),
              (2, 'Visited'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: filter == index,
                onSelected: (_) => setState(() => filter = index),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (places.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.controller.places.isEmpty
                        ? 'Your list is ready for its first place.'
                        : 'No places match this search.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          )
        else
          for (final place in places)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      place.visited ? Icons.check : Icons.place_outlined,
                    ),
                  ),
                  title: Text(place.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (place.notes.isNotEmpty)
                        Text(
                          place.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                      ),
                    ],
                  ),
                  isThreeLine: place.notes.isNotEmpty,
                  onTap: () => widget.onShowOnMap(place),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Actions for ${place.name}',
                    onSelected: (action) {
                      switch (action) {
                        case 'map':
                          widget.onShowOnMap(place);
                        case 'visited':
                          _run(
                            () => widget.controller.updatePlace(
                              place.copyWith(visited: !place.visited),
                            ),
                          );
                        case 'edit':
                          _edit(place);
                        case 'delete':
                          _delete(place);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'map',
                        child: Text('Show on map'),
                      ),
                      PopupMenuItem(
                        value: 'visited',
                        child: Text(
                          place.visited
                              ? 'Mark as not visited'
                              : 'Mark as visited',
                        ),
                      ),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
