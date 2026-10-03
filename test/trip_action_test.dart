import 'package:flutter_test/flutter_test.dart';
import 'package:my_test/app/travel_controller.dart';
import 'package:my_test/core/storage/file_store.dart';
import 'package:my_test/features/files/stored_file.dart';
import 'package:my_test/features/places/trip_action.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MemoryFileStore extends FileStore {
  @override
  Future<List<StoredFile>> loadFiles() async => [];
}

void main() {
  test(
    'trip actions keep optional schedule, booking, place, and attachment',
    () {
      final action = TripAction.create(
        title: 'Train to Paris',
        notes: 'Platform 4',
        day: DateTime(2026, 10, 15),
        minutesFromMidnight: 9 * 60 + 30,
        reservation: ReservationStatus.has,
        placeId: 'station',
        attachmentId: 'ticket',
      );
      final restored = TripAction.fromJson(action.toJson());

      expect(restored.title, 'Train to Paris');
      expect(restored.minutesFromMidnight, 570);
      expect(restored.reservation, ReservationStatus.has);
      expect(restored.placeId, 'station');
      expect(restored.attachmentId, 'ticket');
      expect(restored.copyWith(done: true).done, isTrue);
      expect(restored.copyWith(clearTime: true).minutesFromMidnight, isNull);
      expect(restored.copyWith(clearAttachment: true).attachmentId, isNull);
    },
  );

  test(
    'trip actions persist across controller reloads and can be postponed',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final preferences = SharedPreferencesAsync();
      final first = TravelController(
        fileStore: _MemoryFileStore(),
        preferences: preferences,
      );
      await first.initialize();
      final action = TripAction.create(
        title: 'Museum visit',
        notes: '',
        day: DateTime(2026, 10, 15),
        reservation: ReservationStatus.need,
      );
      await first.addAction(action);

      final second = TravelController(
        fileStore: _MemoryFileStore(),
        preferences: preferences,
      );
      await second.initialize();
      expect(second.actions.single.title, 'Museum visit');
      expect(second.actions.single.reservation, ReservationStatus.need);

      await second.updateAction(
        second.actions.single.copyWith(day: DateTime(2026, 10, 16), done: true),
      );
      final third = TravelController(
        fileStore: _MemoryFileStore(),
        preferences: preferences,
      );
      await third.initialize();
      expect(third.actions.single.day, DateTime(2026, 10, 16));
      expect(third.actions.single.done, isTrue);
      await third.deleteAction(action.id);
      expect(third.actions, isEmpty);
    },
  );
}
