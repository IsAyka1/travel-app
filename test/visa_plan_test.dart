import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_test/app/travel_controller.dart';
import 'package:my_test/core/storage/file_store.dart';
import 'package:my_test/features/files/stored_file.dart';
import 'package:my_test/features/visa/visa_page.dart';
import 'package:my_test/features/visa/visa_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MemoryFileStore extends FileStore {
  @override
  Future<List<StoredFile>> loadFiles() async => [];
}

void main() {
  test(
    'visa details and checklist persist across controller reloads',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final preferences = SharedPreferencesAsync();
      final first = TravelController(
        fileStore: _MemoryFileStore(),
        preferences: preferences,
      );
      await first.initialize();
      final plan = VisaPlan.create(
        destination: 'Japan',
        visaRequired: true,
        applicationRequired: false,
        allowedStayDays: 90,
      ).withChecklist([VisaChecklistItem.create('Check passport')]);
      await first.addVisaPlan(plan);

      final second = TravelController(
        fileStore: _MemoryFileStore(),
        preferences: preferences,
      );
      await second.initialize();
      expect(second.visaPlans.single.destination, 'Japan');
      expect(second.visaPlans.single.visaRequired, isTrue);
      expect(second.visaPlans.single.applicationRequired, isFalse);
      expect(second.visaPlans.single.allowedStayDays, 90);
      expect(second.visaPlans.single.checklist.single.title, 'Check passport');

      await second.updateVisaPlan(
        second.visaPlans.single
            .withDetails(
              destination: 'Japan',
              visaRequired: null,
              applicationRequired: null,
              allowedStayDays: null,
            )
            .withChecklist([
              second.visaPlans.single.checklist.single.copyWith(done: true),
            ]),
      );
      final third = TravelController(
        fileStore: _MemoryFileStore(),
        preferences: preferences,
      );
      await third.initialize();
      expect(third.visaPlans.single.visaRequired, isNull);
      expect(third.visaPlans.single.applicationRequired, isNull);
      expect(third.visaPlans.single.allowedStayDays, isNull);
      expect(third.visaPlans.single.checklist.single.done, isTrue);
    },
  );

  testWidgets('adds a visa block and checks off a checklist task', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final controller = TravelController(fileStore: _MemoryFileStore());
    await controller.initialize();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => VisaPage(controller: controller),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add visa block'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Japan');
    await tester.enterText(find.byType(TextFormField).last, '90');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(controller.visaPlans.single.destination, 'Japan');
    expect(find.text('Can stay 90 days'), findsOneWidget);
    await tester.tap(find.text('Add checklist item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Check passport');
    await tester.pump();
    expect(find.text('Check passport'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Save'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      controller.visaPlans.single.checklist.single.title,
      'Check passport',
    );
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(controller.visaPlans.single.checklist.single.done, isTrue);
    expect(find.text('1/1 checklist tasks done'), findsOneWidget);
  });
}
