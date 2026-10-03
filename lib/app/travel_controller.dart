import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/file_store.dart';
import '../features/files/stored_file.dart';
import '../features/places/place.dart';
import '../features/places/trip_action.dart';
import '../features/sharing/trip_package.dart';
import '../features/visa/visa_plan.dart';

class TravelController extends ChangeNotifier {
  TravelController({FileStore? fileStore, SharedPreferencesAsync? preferences})
    : _fileStore = fileStore ?? FileStore(),
      _preferences = preferences ?? SharedPreferencesAsync();

  static const _placesKey = 'travel_app_places_v1';
  static const _actionsKey = 'travel_app_actions_v1';
  static const _visaPlansKey = 'travel_app_visa_plans_v1';

  final FileStore _fileStore;
  final SharedPreferencesAsync _preferences;

  List<Place> _places = [];
  List<TripAction> _actions = [];
  List<VisaPlan> _visaPlans = [];
  List<StoredFile> _files = [];
  bool _isLoading = true;
  String? _loadError;

  List<Place> get places => List.unmodifiable(_places);
  List<TripAction> get actions => List.unmodifiable(_actions);
  List<VisaPlan> get visaPlans => List.unmodifiable(_visaPlans);
  List<StoredFile> get files => List.unmodifiable(_files);
  bool get isLoading => _isLoading;
  bool get supportsFiles => _fileStore.isAvailable;
  String? get loadError => _loadError;

  Future<void> initialize() async {
    try {
      final raw = await _preferences.getString(_placesKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _places = decoded
            .map((entry) => Place.fromJson(entry as Map<String, dynamic>))
            .toList();
      }
      final rawActions = await _preferences.getString(_actionsKey);
      if (rawActions != null) {
        final decoded = jsonDecode(rawActions) as List<dynamic>;
        _actions = decoded
            .map((entry) => TripAction.fromJson(entry as Map<String, dynamic>))
            .toList();
      }
      final rawVisaPlans = await _preferences.getString(_visaPlansKey);
      if (rawVisaPlans != null) {
        final decoded = jsonDecode(rawVisaPlans) as List<dynamic>;
        _visaPlans = decoded
            .map((entry) => VisaPlan.fromJson(entry as Map<String, dynamic>))
            .toList();
      }
      _files = await _fileStore.loadFiles();
    } catch (error) {
      _loadError = 'Some saved data could not be loaded: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _savePlaces(List<Place> next) async {
    await _preferences.setString(
      _placesKey,
      jsonEncode(next.map((place) => place.toJson()).toList()),
    );
    _places = next;
    notifyListeners();
  }

  Future<void> addPlace(Place place) => _savePlaces([..._places, place]);

  Future<void> updatePlace(Place place) => _savePlaces([
    for (final current in _places)
      if (current.id == place.id) place else current,
  ]);

  Future<void> deletePlace(String id) =>
      _savePlaces(_places.where((place) => place.id != id).toList());

  Future<void> _saveActions(List<TripAction> next) async {
    await _preferences.setString(
      _actionsKey,
      jsonEncode(next.map((action) => action.toJson()).toList()),
    );
    _actions = next;
    notifyListeners();
  }

  Future<void> addAction(TripAction action) =>
      _saveActions([..._actions, action]);

  Future<void> updateAction(TripAction action) => _saveActions([
    for (final current in _actions)
      if (current.id == action.id) action else current,
  ]);

  Future<void> deleteAction(String id) =>
      _saveActions(_actions.where((action) => action.id != id).toList());

  Future<void> _saveVisaPlans(List<VisaPlan> next) async {
    await _preferences.setString(
      _visaPlansKey,
      jsonEncode(next.map((plan) => plan.toJson()).toList()),
    );
    _visaPlans = next;
    notifyListeners();
  }

  Future<void> addVisaPlan(VisaPlan plan) =>
      _saveVisaPlans([..._visaPlans, plan]);

  Future<void> updateVisaPlan(VisaPlan plan) => _saveVisaPlans([
    for (final current in _visaPlans)
      if (current.id == plan.id) plan else current,
  ]);

  Future<void> deleteVisaPlan(String id) =>
      _saveVisaPlans(_visaPlans.where((plan) => plan.id != id).toList());

  Future<Uint8List> createTripPackage() async {
    final contents = <String, Uint8List>{};
    var totalBytes = 0;
    for (final file in _files) {
      totalBytes += file.size;
      if (totalBytes > TripPackageCodec.maxPackageBytes) {
        throw const FormatException('Trip attachments are too large to share.');
      }
      contents[file.id] = Uint8List.fromList(await _fileStore.readFile(file));
    }
    return compute(
      TripPackageCodec.encode,
      TripPackage(
        places: _places,
        actions: _actions,
        visaPlans: _visaPlans,
        files: _files,
        fileBytes: contents,
      ),
    );
  }

  Future<TripPackage> readTripPackage(List<int> bytes) =>
      compute(TripPackageCodec.decode, Uint8List.fromList(bytes));

  Future<void> importTripPackage(TripPackage package) async {
    if (package.files.isNotEmpty && !supportsFiles) {
      throw UnsupportedError('Attachments cannot be imported on this device.');
    }
    final placeIds = {
      for (final place in package.places) place.id: _newImportedId(),
    };
    final importedFiles = <StoredFile>[];
    var startedPersisting = false;
    try {
      final fileIds = <String, String>{};
      for (final file in package.files) {
        final imported = await _fileStore.importBytes(
          file.name,
          package.fileBytes[file.id]!,
        );
        importedFiles.add(imported);
        fileIds[file.id] = imported.id;
      }
      final nextPlaces = [
        ..._places,
        for (final place in package.places)
          Place(
            id: placeIds[place.id]!,
            name: place.name,
            notes: place.notes,
            latitude: place.latitude,
            longitude: place.longitude,
            visited: place.visited,
            createdAt: place.createdAt,
            plannedFor: place.plannedFor,
          ),
      ];
      final nextActions = [
        ..._actions,
        for (final action in package.actions)
          TripAction(
            id: _newImportedId(),
            title: action.title,
            notes: action.notes,
            day: action.day,
            minutesFromMidnight: action.minutesFromMidnight,
            done: action.done,
            reservation: action.reservation,
            placeId: placeIds[action.placeId],
            attachmentId: fileIds[action.attachmentId],
            createdAt: action.createdAt,
          ),
      ];
      final nextVisaPlans = [
        ..._visaPlans,
        for (final plan in package.visaPlans)
          VisaPlan(
            id: _newImportedId(),
            destination: plan.destination,
            visaRequired: plan.visaRequired,
            applicationRequired: plan.applicationRequired,
            allowedStayDays: plan.allowedStayDays,
            checklist: [
              for (final item in plan.checklist)
                VisaChecklistItem(
                  id: _newImportedId(),
                  title: item.title,
                  done: item.done,
                ),
            ],
          ),
      ];
      final nextFiles = [..._files, ...importedFiles];
      startedPersisting = true;
      await _fileStore.saveFiles(nextFiles);
      await _preferences.setString(_placesKey, _encodePlaces(nextPlaces));
      await _preferences.setString(_actionsKey, _encodeActions(nextActions));
      await _preferences.setString(
        _visaPlansKey,
        _encodeVisaPlans(nextVisaPlans),
      );
      _places = nextPlaces;
      _actions = nextActions;
      _visaPlans = nextVisaPlans;
      _files = nextFiles;
      notifyListeners();
    } catch (_) {
      if (startedPersisting) {
        try {
          await _fileStore.saveFiles(_files);
          await _preferences.setString(_placesKey, _encodePlaces(_places));
          await _preferences.setString(_actionsKey, _encodeActions(_actions));
          await _preferences.setString(
            _visaPlansKey,
            _encodeVisaPlans(_visaPlans),
          );
        } catch (_) {}
      }
      for (final file in importedFiles) {
        try {
          await _fileStore.deleteFile(file);
        } catch (_) {}
      }
      rethrow;
    }
  }

  static String _newImportedId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';

  static String _encodePlaces(List<Place> places) =>
      jsonEncode(places.map((place) => place.toJson()).toList());

  static String _encodeActions(List<TripAction> actions) =>
      jsonEncode(actions.map((action) => action.toJson()).toList());

  static String _encodeVisaPlans(List<VisaPlan> plans) =>
      jsonEncode(plans.map((plan) => plan.toJson()).toList());

  Future<StoredFile> _importPickedFile(PlatformFile source) async {
    final imported = await _fileStore.importFile(source);
    try {
      final next = [..._files, imported];
      await _fileStore.saveFiles(next);
      _files = next;
      notifyListeners();
      return imported;
    } catch (_) {
      await _fileStore.deleteFile(imported);
      rethrow;
    }
  }

  Future<int> importFiles() async {
    if (!supportsFiles) return 0;
    final picked = await FilePicker.pickFiles();
    for (final source in picked) {
      await _importPickedFile(source);
    }
    return picked.length;
  }

  Future<StoredFile?> importAttachment() async {
    if (!supportsFiles) return null;
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return null;
    return _importPickedFile(picked.first);
  }

  Future<Uri?> exportFile(StoredFile file) => _fileStore.exportFile(file);

  Future<String> filePath(StoredFile file) => _fileStore.pathFor(file);

  Future<List<int>> readFile(StoredFile file) => _fileStore.readFile(file);

  Future<void> deleteFile(StoredFile file) async {
    final next = _files.where((current) => current.id != file.id).toList();
    await _fileStore.saveFiles(next);
    _files = next;
    notifyListeners();
    await _fileStore.deleteFile(file);
  }
}
