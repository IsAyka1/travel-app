import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test/features/places/place.dart';
import 'package:my_test/features/places/place_editor.dart';

void main() {
  testWidgets('place editor validates coordinates before saving', (
    tester,
  ) async {
    Place? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => saved = await showPlaceEditor(context),
              child: const Text('Add place'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add place'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Place name'),
      'Kyoto',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Latitude'),
      '100',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Longitude'),
      '135.7681',
    );
    await tester.tap(find.text('Save place'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number from -90.0 to 90.0'), findsOneWidget);
    expect(saved, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Latitude'),
      '35.0116',
    );
    await tester.tap(find.text('Save place'));
    await tester.pumpAndSettle();
    expect(saved?.name, 'Kyoto');
    expect(saved?.latitude, 35.0116);
    expect(saved?.longitude, 135.7681);
  });
}
