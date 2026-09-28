import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/file_store.dart';
import '../features/files/stored_file.dart';
import '../features/places/place.dart';

class TravelController extends ChangeNotifier {
  TravelController({FileStore? fileStore, SharedPreferencesAsync? preferences})
    : _fileStore = fileStore ?? FileStore(),
      _preferences = preferences ?? SharedPreferencesAsync();

  static const _placesKey = 'travel_app_places_v1';

  final FileStore _fileStore;
  final SharedPreferencesAsync _preferences;

  List<Place> _places = [];
  List<StoredFile> _files = [];
  bool _isLoading = true;
  String? _loadError;

  List<Place> get places => List.unmodifiable(_places);
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

  Future<int> importFiles() async {
    if (!supportsFiles) return 0;
    final picked = await FilePicker.pickFiles();
    for (final source in picked) {
      final imported = await _fileStore.importFile(source);
      try {
        final next = [..._files, imported];
        await _fileStore.saveFiles(next);
        _files = next;
        notifyListeners();
      } catch (_) {
        await _fileStore.deleteFile(imported);
        rethrow;
      }
    }
    return picked.length;
  }

  Future<Uri?> exportFile(StoredFile file) => _fileStore.exportFile(file);

  Future<void> deleteFile(StoredFile file) async {
    final next = _files.where((current) => current.id != file.id).toList();
    await _fileStore.saveFiles(next);
    _files = next;
    notifyListeners();
    await _fileStore.deleteFile(file);
  }
}
