import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/file_store.dart';
import '../features/files/stored_file.dart';
import '../features/places/place.dart';
import '../features/places/trip_action.dart';
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
