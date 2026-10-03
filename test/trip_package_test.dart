import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_test/app/travel_controller.dart';
import 'package:my_test/core/storage/file_store.dart';
import 'package:my_test/features/files/stored_file.dart';
import 'package:my_test/features/places/place.dart';
import 'package:my_test/features/places/trip_action.dart';
import 'package:my_test/features/sharing/trip_package.dart';
import 'package:my_test/features/visa/visa_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MemoryFileStore extends FileStore {
  final contents = <String, List<int>>{};
  List<StoredFile> index = [];
  int nextId = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<List<StoredFile>> loadFiles() async => [...index];

  @override
  Future<void> saveFiles(List<StoredFile> files) async => index = [...files];

  @override
  Future<StoredFile> importBytes(String name, List<int> bytes) async {
    final file = StoredFile(
      id: 'imported_${nextId++}',
      name: name,
      size: bytes.length,
      importedAt: DateTime(2026, 10, 3),
    );
    contents[file.id] = [...bytes];
    return file;
  }

  @override
  Future<List<int>> readFile(StoredFile file) async => contents[file.id]!;

  @override
  Future<void> deleteFile(StoredFile file) async {
    contents.remove(file.id);
  }
}

void main() {
  test(
    'trip package imports linked data and attachments without replacing plans',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final sourceFiles = _MemoryFileStore();
      final ticket = await sourceFiles.importBytes('ticket.pdf', [1, 2, 3, 4]);
      await sourceFiles.saveFiles([ticket]);
      final source = TravelController(
        fileStore: sourceFiles,
        preferences: SharedPreferencesAsync(),
      );
      await source.initialize();
      final place = Place(
        id: 'kyoto',
        name: 'Kyoto',
        notes: 'Temple visit',
        latitude: 35.01,
        longitude: 135.77,
        visited: false,
        createdAt: DateTime(2026, 10, 3),
        plannedFor: DateTime(2026, 10, 15),
      );
      await source.addPlace(place);
      await source.addAction(
        TripAction(
          id: 'train',
          title: 'Train to Kyoto',
          notes: '',
          day: DateTime(2026, 10, 15),
          minutesFromMidnight: 540,
          done: false,
          reservation: ReservationStatus.has,
          placeId: place.id,
          attachmentId: ticket.id,
          createdAt: DateTime(2026, 10, 3),
        ),
      );
      await source.addVisaPlan(
        VisaPlan(
          id: 'visa',
          destination: 'Japan',
          visaRequired: null,
          applicationRequired: true,
          allowedStayDays: 90,
          checklist: const [
            VisaChecklistItem(
              id: 'passport',
              title: 'Check passport',
              done: true,
            ),
          ],
        ),
      );

      final bytes = await source.createTripPackage();
      final decoded = await source.readTripPackage(bytes);
      expect(decoded.places.single.name, 'Kyoto');
      expect(decoded.actions.single.attachmentId, ticket.id);
      expect(decoded.fileBytes[ticket.id], [1, 2, 3, 4]);

      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final receiverFiles = _MemoryFileStore();
      final receiver = TravelController(
        fileStore: receiverFiles,
        preferences: SharedPreferencesAsync(),
      );
      await receiver.initialize();
      await receiver.addPlace(
        Place(
          id: 'existing',
          name: 'Home',
          notes: '',
          latitude: 0,
          longitude: 0,
          visited: false,
          createdAt: DateTime(2026, 10, 3),
        ),
      );
      await receiver.importTripPackage(decoded);
      expect(receiver.places.length, 2);
      expect(receiver.places.first.name, 'Home');
      final copiedPlace = receiver.places.last;
      final copiedAction = receiver.actions.single;
      final copiedFile = receiver.files.single;
      expect(copiedPlace.id, isNot(place.id));
      expect(copiedAction.placeId, copiedPlace.id);
      expect(copiedAction.attachmentId, copiedFile.id);
      expect(await receiverFiles.readFile(copiedFile), [1, 2, 3, 4]);
      expect(receiver.visaPlans.single.checklist.single.done, isTrue);

      await receiver.importTripPackage(decoded);
      expect(receiver.places.length, 3);
      expect(receiver.actions.length, 2);
      expect(receiver.files.length, 2);
      expect(receiver.actions.last.attachmentId, receiver.files.last.id);
    },
  );

  test('rejects files that are not Travel Atlas packages', () {
    expect(
      () => TripPackageCodec.decode(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
}
