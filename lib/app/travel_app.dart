import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../features/files/files_page.dart';
import '../features/map/map_page.dart';
import '../features/map/place_search_service.dart';
import '../features/places/place.dart';
import '../features/places/place_editor.dart';
import '../features/places/places_page.dart';
import 'travel_controller.dart';

class TravelApp extends StatefulWidget {
  const TravelApp({super.key});

  @override
  State<TravelApp> createState() => _TravelAppState();
}

class _TravelAppState extends State<TravelApp> {
  late final TravelController controller = TravelController()..initialize();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF176C68),
      surface: const Color(0xFFFCFBF8),
    );
    return MaterialApp(
      title: 'Travel Atlas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        scaffoldBackgroundColor: const Color(0xFFF6F5F1),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      home: TravelShell(controller: controller),
    );
  }
}

class TravelShell extends StatefulWidget {
  const TravelShell({super.key, required this.controller});

  final TravelController controller;

  @override
  State<TravelShell> createState() => _TravelShellState();
}

class _TravelShellState extends State<TravelShell> {
  int selectedPage = 0;
  Place? mapFocus;

  static const titles = ['Overview', 'Map', 'Places to visit', 'Files'];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.map_outlined,
    Icons.place_outlined,
    Icons.folder_outlined,
  ];
  static const selectedIcons = [
    Icons.dashboard,
    Icons.map,
    Icons.place,
    Icons.folder,
  ];

  void _navigate(int index, {Place? place}) {
    setState(() {
      selectedPage = index;
      if (place != null) mapFocus = place;
    });
  }

  Future<void> _addPlace({LatLng? location, String? name}) async {
    final place = await showPlaceEditor(
      context,
      location: location,
      initialName: name,
    );
    if (place == null || !mounted) return;
    try {
      await widget.controller.addPlace(place);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${place.name} added to your places')),
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Could not save: $error')));
  }

  Widget _page() {
    switch (selectedPage) {
      case 1:
        return MapPage(
          controller: widget.controller,
          focus: mapFocus,
          onAddAt: (point) => _addPlace(location: point),
          onSaveFoundPlace: (FoundPlace found) =>
              _addPlace(location: found.point, name: found.name),
        );
      case 2:
        return PlacesPage(
          controller: widget.controller,
          onAdd: () => _addPlace(),
          onShowOnMap: (place) => _navigate(1, place: place),
        );
      case 3:
        return FilesPage(controller: widget.controller);
      default:
        return _OverviewPage(
          controller: widget.controller,
          onAddPlace: () => _addPlace(),
          onOpenMap: () => _navigate(1),
          onOpenPlaces: () => _navigate(2),
          onOpenFiles: () => _navigate(3),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final wide = MediaQuery.sizeOf(context).width >= 760;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Travel Atlas'),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            actions: [
              if (selectedPage != 2)
                IconButton(
                  tooltip: 'Add a place',
                  onPressed: () => _addPlace(),
                  icon: const Icon(Icons.add_location_alt_outlined),
                ),
              const SizedBox(width: 12),
            ],
          ),
          drawer: wide
              ? null
              : Drawer(
                  child: SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Explore your world',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        for (var i = 0; i < titles.length; i++)
                          ListTile(
                            leading: Icon(icons[i]),
                            title: Text(titles[i]),
                            selected: selectedPage == i,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _navigate(i);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
          body: widget.controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    if (wide) ...[
                      NavigationRail(
                        selectedIndex: selectedPage,
                        onDestinationSelected: _navigate,
                        extended: MediaQuery.sizeOf(context).width >= 1100,
                        minExtendedWidth: 220,
                        backgroundColor: Colors.white,
                        destinations: [
                          for (var i = 0; i < titles.length; i++)
                            NavigationRailDestination(
                              icon: Icon(icons[i]),
                              selectedIcon: Icon(selectedIcons[i]),
                              label: Text(titles[i]),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                    ],
                    Expanded(child: _page()),
                  ],
                ),
        );
      },
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({
    required this.controller,
    required this.onAddPlace,
    required this.onOpenMap,
    required this.onOpenPlaces,
    required this.onOpenFiles,
  });

  final TravelController controller;
  final VoidCallback onAddPlace;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenPlaces;
  final VoidCallback onOpenFiles;

  @override
  Widget build(BuildContext context) {
    final upcoming = controller.places.where((place) => !place.visited).take(3);
    final visited = controller.places.where((place) => place.visited).length;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (controller.loadError != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(controller.loadError!),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF125E5B), Color(0xFF348D7F)],
            ),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR TRAVEL SPACE',
                      style: TextStyle(
                        color: Color(0xFFC8E6DF),
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Keep your next adventure close.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Save places, see them on the map, and keep trip files on this device.',
                      style: TextStyle(color: Color(0xFFE2F2ED), fontSize: 16),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onAddPlace,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Add a place'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF125E5B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              icon: Icons.place,
              label: 'Saved places',
              value: '${controller.places.length}',
            ),
            _StatCard(
              icon: Icons.check_circle,
              label: 'Visited',
              value: '$visited',
            ),
            _StatCard(
              icon: Icons.folder,
              label: 'Trip files',
              value: '${controller.files.length}',
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          'Where to next?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Text(
                'No places yet. Add a destination to start your list.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        else
          for (final place in upcoming)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.place_outlined)),
                title: Text(place.name),
                subtitle: Text(
                  place.notes.isEmpty
                      ? '${place.latitude.toStringAsFixed(3)}, ${place.longitude.toStringAsFixed(3)}'
                      : place.notes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenPlaces,
              ),
            ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: onOpenMap,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open map'),
            ),
            OutlinedButton.icon(
              onPressed: onOpenPlaces,
              icon: const Icon(Icons.place_outlined),
              label: const Text('All places'),
            ),
            OutlinedButton.icon(
              onPressed: onOpenFiles,
              icon: const Icon(Icons.folder_outlined),
              label: const Text('My files'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    ),
  );
}
