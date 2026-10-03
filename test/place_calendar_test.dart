import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test/app/travel_controller.dart';
import 'package:my_test/features/places/place.dart';
import 'package:my_test/features/places/places_page.dart';
import 'package:my_test/features/places/trip_action.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _PlacesController extends TravelController {
  _PlacesController(this.savedPlaces, [List<TripAction>? actions])
    : savedActions = actions ?? [];

  final List<Place> savedPlaces;
  final List<TripAction> savedActions;

  @override
  List<Place> get places => savedPlaces;

  @override
  List<TripAction> get actions => savedActions;

  @override
  Future<void> updateAction(TripAction action) async {
    final index = savedActions.indexWhere((item) => item.id == action.id);
    savedActions[index] = action;
    notifyListeners();
  }

  @override
  Future<void> deleteAction(String id) async {
    savedActions.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}

void main() {
  test('planned visit date persists and older places still load', () {
    final oldJson = {
      'id': 'old',
      'name': 'Kyoto',
      'notes': '',
      'latitude': 35.0116,
      'longitude': 135.7681,
      'visited': false,
      'createdAt': '2026-10-01T12:00:00.000',
    };
    final oldPlace = Place.fromJson(oldJson);
    expect(oldPlace.plannedFor, isNull);

    final planned = oldPlace.copyWith(plannedFor: DateTime(2026, 10, 15));
    expect(planned.toJson()['plannedFor'], '2026-10-15');
    expect(Place.fromJson(planned.toJson()).plannedFor, DateTime(2026, 10, 15));
    expect(planned.copyWith(clearPlannedFor: true).plannedFor, isNull);
  });

  testWidgets('tapping a calendar day expands its planned place actions', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final date = DateTime(DateTime.now().year, DateTime.now().month, 15);
    final place = Place(
      id: 'kyoto',
      name: 'Kyoto',
      notes: 'Visit the gardens',
      latitude: 35.0116,
      longitude: 135.7681,
      visited: false,
      createdAt: DateTime(2026, 10, 1),
      plannedFor: date,
    );
    final controller = _PlacesController([place]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlacesPage(
            controller: controller,
            onAdd: (_) {},
            onShowOnMap: (_) {},
          ),
        ),
      ),
    );

    final day = find.byKey(
      ValueKey('calendar-day-${date.year}-${date.month}-${date.day}'),
    );
    expect(find.byKey(const ValueKey('calendar-place-kyoto')), findsNothing);
    await tester.tap(day);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendar-place-kyoto')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Checkbox && widget.semanticLabel == 'Mark Kyoto visited',
      ),
      findsOneWidget,
    );
    expect(find.text('Add place for this day'), findsOneWidget);

    await tester.tap(day);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('calendar-place-kyoto')), findsNothing);
  });

  testWidgets('calendar timetable shows booking and can mark an action done', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final date = DateTime(DateTime.now().year, DateTime.now().month, 15);
    final action = TripAction(
      id: 'train',
      title: 'Train to Paris',
      notes: 'Platform 4',
      day: date,
      minutesFromMidnight: 9 * 60 + 30,
      done: false,
      reservation: ReservationStatus.need,
      placeId: null,
      attachmentId: null,
      createdAt: DateTime(2026, 10, 1),
    );
    final controller = _PlacesController([], [action]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => PlacesPage(
              controller: controller,
              onAdd: (_) {},
              onShowOnMap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        ValueKey('calendar-day-${date.year}-${date.month}-${date.day}'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trip-action-train')), findsOneWidget);
    expect(find.text('Need reservation'), findsOneWidget);
    expect(find.text('9:30 AM'), findsOneWidget);

    await tester.ensureVisible(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(controller.actions.single.done, isTrue);
    expect(
      tester.widget<Text>(find.text('Train to Paris')).style?.decoration,
      TextDecoration.lineThrough,
    );

    await tester.ensureVisible(find.text('Postpone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Postpone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(controller.actions.single.day, DateTime(date.year, date.month, 16));

    await tester.ensureVisible(find.text('Delete').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(controller.actions, isEmpty);
  });
}
