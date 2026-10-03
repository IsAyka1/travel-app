import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test/app/travel_app.dart';
import 'package:my_test/app/travel_controller.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _OverviewController extends TravelController {
  @override
  bool get isLoading => false;
}

void main() {
  for (final (label, destinationText) in [
    ('Saved places', 'Trip calendar'),
    ('Visited', 'Trip calendar'),
    (
      'Trip files',
      'Keep tickets, itineraries, and documents with your travel plans.',
    ),
    ('Visa plans', 'Keep entry details and preparation tasks by destination.'),
  ]) {
    testWidgets('$label summary opens its section', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final controller = _OverviewController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: TravelShell(controller: controller)),
      );
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(destinationText), findsOneWidget);
    });
  }
}
