import 'package:flutter/material.dart';

import '../../app/travel_controller.dart';
import '../files/file_preview_page.dart';
import 'place.dart';
import 'place_editor.dart';
import 'trip_action.dart';
import 'trip_action_editor.dart';

enum _NewDayItem { action, place }

enum _ActionOperation { edit, postpone, delete }

class PlacesPage extends StatefulWidget {
  const PlacesPage({
    super.key,
    required this.controller,
    required this.onAdd,
    required this.onShowOnMap,
  });

  final TravelController controller;
  final ValueChanged<DateTime?> onAdd;
  final ValueChanged<Place> onShowOnMap;

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  String query = '';
  int filter = 0;
  DateTime shownMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? selectedDay;

  void _changeMonth(int offset) {
    setState(() {
      shownMonth = DateTime(shownMonth.year, shownMonth.month + offset);
      selectedDay = null;
    });
  }

  Widget _calendar(List<Place> allPlaces) {
    final colors = Theme.of(context).colorScheme;
    final monthStart = DateTime(shownMonth.year, shownMonth.month);
    final daysInMonth = DateUtils.getDaysInMonth(
      shownMonth.year,
      shownMonth.month,
    );
    final leadingDays = monthStart.weekday - DateTime.monday;
    final counts = <int, int>{};
    final reservationWarnings = <int>{};
    for (final place in allPlaces) {
      final date = place.plannedFor;
      if (date != null &&
          date.year == shownMonth.year &&
          date.month == shownMonth.month) {
        counts.update(date.day, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    for (final action in widget.controller.actions) {
      final date = action.day;
      if (date.year == shownMonth.year && date.month == shownMonth.month) {
        counts.update(date.day, (count) => count + 1, ifAbsent: () => 1);
        if (action.reservation == ReservationStatus.need) {
          reservationWarnings.add(date.day);
        }
      }
    }
    final dayPlaces =
        selectedDay == null
              ? <Place>[]
              : allPlaces
                    .where(
                      (place) =>
                          DateUtils.isSameDay(place.plannedFor, selectedDay),
                    )
                    .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final dayActions =
        selectedDay == null
              ? <TripAction>[]
              : widget.controller.actions
                    .where(
                      (action) => DateUtils.isSameDay(action.day, selectedDay),
                    )
                    .toList()
          ..sort((a, b) {
            final timeComparison = (a.minutesFromMidnight ?? 1440).compareTo(
              b.minutesFromMidnight ?? 1440,
            );
            return timeComparison != 0
                ? timeComparison
                : a.createdAt.compareTo(b.createdAt);
          });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip calendar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text('Choose a day to see its timetable and places.'),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous month',
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          MaterialLocalizations.of(context)
                              .formatMonthYear(shownMonth),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next month',
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          final today = DateTime.now();
                          shownMonth = DateTime(today.year, today.month);
                          selectedDay = DateTime(
                            today.year,
                            today.month,
                            today.day,
                          );
                        }),
                        child: const Text('Today'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      for (final day in [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ])
                        Expanded(child: Center(child: Text(day))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: leadingDays + daysInMonth,
                    itemBuilder: (context, index) {
                      if (index < leadingDays) return const SizedBox.shrink();
                      final day = index - leadingDays + 1;
                      final date = DateTime(
                        shownMonth.year,
                        shownMonth.month,
                        day,
                      );
                      final count = counts[day] ?? 0;
                      final selected = DateUtils.isSameDay(selectedDay, date);
                      final today = DateUtils.isSameDay(DateTime.now(), date);
                      return Semantics(
                        label:
                            '$day ${MaterialLocalizations.of(context).formatMonthYear(date)}, $count planned ${count == 1 ? 'item' : 'items'}${reservationWarnings.contains(day) ? ', reservation needed' : ''}',
                        button: true,
                        selected: selected,
                        child: InkWell(
                          key: ValueKey(
                            'calendar-day-${date.year}-${date.month}-${date.day}',
                          ),
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() {
                            selectedDay = selected ? null : date;
                          }),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: selected ? colors.primaryContainer : null,
                              borderRadius: BorderRadius.circular(10),
                              border: today
                                  ? Border.all(color: colors.primary)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$day'),
                                if (count > 0 ||
                                    reservationWarnings.contains(day))
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (count > 0)
                                        CircleAvatar(
                                          radius: 9,
                                          backgroundColor: colors.primary,
                                          child: Text(
                                            count > 9 ? '9+' : '$count',
                                            style: TextStyle(
                                              color: colors.onPrimary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      if (reservationWarnings.contains(day))
                                        Icon(
                                          Icons.priority_high,
                                          key: ValueKey(
                                            'calendar-reservation-warning-${date.year}-${date.month}-${date.day}',
                                          ),
                                          color: const Color(0xFFF4B400),
                                          size: 18,
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (selectedDay != null) ...[
              const Divider(height: 28),
              Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(selectedDay!),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text('Timetable', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (dayActions.isEmpty)
                const Text('No actions planned for this day.')
              else
                for (final action in dayActions) _actionCard(action),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _showAddMenu(selectedDay!),
                icon: const Icon(Icons.add_task),
                label: const Text('Add action'),
              ),
              const Divider(height: 28),
              Text(
                'Places to visit',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (dayPlaces.isEmpty)
                const Text('No places planned for this day.')
              else
                for (final place in dayPlaces) _calendarPlaceCard(place),
            ],
          ],
        ),
      ),
    );
  }

  Widget _calendarPlaceCard(Place place) => Card.outlined(
    key: ValueKey('calendar-place-${place.id}'),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: place.visited,
                semanticLabel: place.visited
                    ? 'Mark ${place.name} not visited'
                    : 'Mark ${place.name} visited',
                onChanged: (value) => _run(
                  () => widget.controller.updatePlace(
                    place.copyWith(visited: value ?? false),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  place.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: place.visited
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ],
          ),
          Text(place.visited ? 'Visited' : 'Want to visit'),
          if (place.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(place.notes),
          ],
          Text(
            '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _edit(place),
                child: const Text('Edit'),
              ),
              OutlinedButton(
                onPressed: () => widget.onShowOnMap(place),
                child: const Text('Show on map'),
              ),
              TextButton(
                onPressed: () => _delete(place),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _actionCard(TripAction action) {
    final place = widget.controller.places
        .where((item) => item.id == action.placeId)
        .firstOrNull;
    final attachment = widget.controller.files
        .where((file) => file.id == action.attachmentId)
        .firstOrNull;
    final time = action.minutesFromMidnight == null
        ? null
        : TimeOfDay(
            hour: action.minutesFromMidnight! ~/ 60,
            minute: action.minutesFromMidnight! % 60,
          );
    final reservationLabel = switch (action.reservation) {
      ReservationStatus.none => 'No reservation',
      ReservationStatus.need => 'Need reservation',
      ReservationStatus.has => 'Reservation confirmed',
    };
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      key: ValueKey('trip-action-${action.id}'),
      margin: const EdgeInsets.only(bottom: 6),
      color: colors.primaryContainer.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: action.done
              ? colors.outlineVariant
              : colors.primary.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: action.done,
                  visualDensity: VisualDensity.compact,
                  semanticLabel: action.done
                      ? 'Mark ${action.title} not done'
                      : 'Mark ${action.title} done',
                  onChanged: (value) => _run(
                    () => widget.controller.updateAction(
                      action.copyWith(done: value ?? false),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      decoration: action.done
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                if (action.reservation == ReservationStatus.need)
                  Tooltip(
                    message: 'Need reservation',
                    child: Icon(
                      Icons.priority_high,
                      key: ValueKey('reservation-warning-${action.id}'),
                      color: const Color(0xFFF4B400),
                      size: 20,
                    ),
                  ),
                if (time != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    time.format(context),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                PopupMenuButton<_ActionOperation>(
                  tooltip: 'Options for ${action.title}',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (operation) {
                    switch (operation) {
                      case _ActionOperation.edit:
                        _editAction(action);
                      case _ActionOperation.postpone:
                        _postponeAction(action);
                      case _ActionOperation.delete:
                        _deleteAction(action);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _ActionOperation.edit,
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: _ActionOperation.postpone,
                      child: Text('Postpone'),
                    ),
                    PopupMenuItem(
                      value: _ActionOperation.delete,
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            if (action.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 44, right: 8),
                child: Text(
                  action.notes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (action.reservation != ReservationStatus.none ||
                place != null ||
                action.placeId != null ||
                attachment != null ||
                action.attachmentId != null)
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    if (action.reservation != ReservationStatus.none)
                      Text(
                        reservationLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (place != null)
                      TextButton.icon(
                        onPressed: () => widget.onShowOnMap(place),
                        icon: const Icon(Icons.place_outlined, size: 16),
                        label: Text(place.name),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      )
                    else if (action.placeId != null)
                      const Text('Linked place is no longer available'),
                    if (attachment != null)
                      TextButton.icon(
                        onPressed: () => openFilePreview(
                          context,
                          controller: widget.controller,
                          file: attachment,
                        ),
                        icon: const Icon(Icons.attach_file, size: 16),
                        label: Text('View ${attachment.name}'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      )
                    else if (action.attachmentId != null)
                      const Text('Attachment is no longer available'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $error')));
      }
      return false;
    }
  }

  Future<void> _showAddMenu(DateTime day) async {
    final choice = await showModalBottomSheet<_NewDayItem>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_task),
              title: const Text('Trip action'),
              onTap: () => Navigator.pop(sheetContext, _NewDayItem.action),
            ),
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: const Text('Place to visit'),
              onTap: () => Navigator.pop(sheetContext, _NewDayItem.place),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _NewDayItem.action:
        await _addAction(day);
      case _NewDayItem.place:
        widget.onAdd(day);
      case null:
        break;
    }
  }

  Future<void> _addAction(DateTime day) async {
    final action = await showTripActionEditor(
      context,
      controller: widget.controller,
      day: day,
    );
    if (action != null) await _run(() => widget.controller.addAction(action));
  }

  Future<void> _editAction(TripAction action) async {
    final edited = await showTripActionEditor(
      context,
      controller: widget.controller,
      day: action.day,
      action: action,
    );
    if (edited != null) {
      await _run(() => widget.controller.updateAction(edited));
    }
  }

  Future<void> _postponeAction(TripAction action) async {
    final firstDay = DateTime(
      action.day.year,
      action.day.month,
      action.day.day + 1,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: firstDay,
      firstDate: firstDay,
      lastDate: DateTime(firstDay.year + 100),
    );
    if (picked == null) return;
    final saved = await _run(
      () => widget.controller.updateAction(action.copyWith(day: picked)),
    );
    if (saved && mounted) {
      setState(() {
        shownMonth = DateTime(picked.year, picked.month);
        selectedDay = picked;
      });
    }
  }

  Future<void> _deleteAction(TripAction action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete action?'),
        content: Text('Remove ${action.title} from your trip plan?'),
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
      await _run(() => widget.controller.deleteAction(action.id));
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
                  'Calendar',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Keep a list of the destinations that matter to you.',
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: () => widget.onAdd(null),
              icon: const Icon(Icons.add),
              label: const Text('Add place'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _calendar(widget.controller.places),
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
                  title: Text(
                    place.name,
                    style: place.visited
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                          )
                        : null,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (place.notes.isNotEmpty)
                        Text(
                          place.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (place.plannedFor != null)
                        Text(
                          'Planned: ${MaterialLocalizations.of(context).formatMediumDate(place.plannedFor!)}',
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
