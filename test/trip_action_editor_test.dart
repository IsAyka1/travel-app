import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test/app/travel_controller.dart';
import 'package:my_test/features/files/stored_file.dart';
import 'package:my_test/features/places/place.dart';
import 'package:my_test/features/places/trip_action.dart';
import 'package:my_test/features/places/trip_action_editor.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _EditorController extends TravelController {
  _EditorController(this.savedPlaces, this.savedFiles);

  final List<Place> savedPlaces;
  final List<StoredFile> savedFiles;

  @override
  List<Place> get places => savedPlaces;

  @override
  List<StoredFile> get files => savedFiles;

  @override
  bool get supportsFiles => false;
}

void main() {
  testWidgets('trip action can link a place, booking, and attachment', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final controller = _EditorController(
      [
        Place(
          id: 'louvre',
          name: 'Louvre',
          notes: '',
          latitude: 48.86,
          longitude: 2.33,
          visited: false,
          createdAt: DateTime(2026, 10, 1),
        ),
      ],
      [
        StoredFile(
          id: 'ticket',
          name: 'ticket.pdf',
          size: 100,
          importedAt: DateTime(2026, 10, 1),
        ),
      ],
    );
    TripAction? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => saved = await showTripActionEditor(
                context,
                controller: controller,
                day: DateTime(2026, 10, 15),
              ),
              child: const Text('Add action'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add action'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Action'),
      'Visit museum',
    );

    await tester.tap(find.text('No reservation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Need reservation').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<String>).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Louvre').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<String>).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ticket.pdf').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Set time (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set time (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save action'));
    await tester.pumpAndSettle();
    expect(saved?.title, 'Visit museum');
    expect(saved?.day, DateTime(2026, 10, 15));
    expect(saved?.minutesFromMidnight, inInclusiveRange(0, 1439));
    expect(saved?.reservation, ReservationStatus.need);
    expect(saved?.placeId, 'louvre');
    expect(saved?.attachmentId, 'ticket');
    expect(saved?.done, isFalse);
  });
}
