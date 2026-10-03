import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../files/stored_file.dart';
import '../places/place.dart';
import '../places/trip_action.dart';
import '../visa/visa_plan.dart';

class TripPackage {
  const TripPackage({
    required this.places,
    required this.actions,
    required this.visaPlans,
    required this.files,
    required this.fileBytes,
  });

  final List<Place> places;
  final List<TripAction> actions;
  final List<VisaPlan> visaPlans;
  final List<StoredFile> files;
  final Map<String, Uint8List> fileBytes;
}

class TripPackageCodec {
  static const maxPackageBytes = 100 * 1024 * 1024;
  static const maxManifestBytes = 2 * 1024 * 1024;
  static const maxFiles = 200;
  static const maxRecords = 5000;
  static const _version = 1;

  static Uint8List encode(TripPackage package) {
    _validate(package);
    final manifest = jsonEncode({
      'format': 'travel-atlas-trip',
      'version': _version,
      'places': package.places.map((place) => place.toJson()).toList(),
      'actions': package.actions.map((action) => action.toJson()).toList(),
      'visaPlans': package.visaPlans.map((plan) => plan.toJson()).toList(),
      'files': package.files.map((file) => file.toJson()).toList(),
    });
    if (utf8.encode(manifest).length > maxManifestBytes) {
      throw const FormatException('Trip details are too large to share.');
    }
    final archive = Archive()
      ..add(ArchiveFile.string('manifest.json', manifest));
    for (final file in package.files) {
      archive.add(
        ArchiveFile.bytes('files/${file.id}', package.fileBytes[file.id]!),
      );
    }
    final bytes = ZipEncoder().encodeBytes(archive);
    if (bytes.length > maxPackageBytes) {
      throw const FormatException('Trip package is too large to share.');
    }
    return bytes;
  }

  static TripPackage decode(Uint8List bytes) {
    if (bytes.length > maxPackageBytes) {
      throw const FormatException('Trip package is too large to import.');
    }
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final manifestEntry = archive.findFile('manifest.json');
      if (manifestEntry == null ||
          !manifestEntry.isFile ||
          manifestEntry.size > maxManifestBytes) {
        throw const FormatException('This is not a Travel Atlas trip package.');
      }
      final manifestBytes = manifestEntry.readBytes();
      if (manifestBytes == null || manifestBytes.length > maxManifestBytes) {
        throw const FormatException('Trip package details could not be read.');
      }
      final manifest =
          jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>;
      if (manifest['format'] != 'travel-atlas-trip' ||
          manifest['version'] != _version) {
        throw const FormatException(
          'Unsupported trip package format or version.',
        );
      }
      final placesJson = manifest['places'] as List<dynamic>;
      final actionsJson = manifest['actions'] as List<dynamic>;
      final visaJson = manifest['visaPlans'] as List<dynamic>;
      final filesJson = manifest['files'] as List<dynamic>;
      if (placesJson.length + actionsJson.length + visaJson.length >
              maxRecords ||
          filesJson.length > maxFiles ||
          archive.files.length != filesJson.length + 1) {
        throw const FormatException('Trip package contains too many items.');
      }
      final places = placesJson
          .map((entry) => Place.fromJson(entry as Map<String, dynamic>))
          .toList();
      final actions = actionsJson
          .map((entry) => TripAction.fromJson(entry as Map<String, dynamic>))
          .toList();
      final visaPlans = visaJson
          .map((entry) => VisaPlan.fromJson(entry as Map<String, dynamic>))
          .toList();
      final files = filesJson
          .map((entry) => StoredFile.fromJson(entry as Map<String, dynamic>))
          .toList();
      final contents = <String, Uint8List>{};
      var totalBytes = 0;
      for (final file in files) {
        final entry = archive.findFile('files/${file.id}');
        if (entry == null || !entry.isFile || entry.size != file.size) {
          throw FormatException(
            'Attachment ${file.name} is missing or damaged.',
          );
        }
        totalBytes += entry.size;
        if (totalBytes > maxPackageBytes) {
          throw const FormatException(
            'Trip attachments are too large to import.',
          );
        }
        final data = entry.readBytes();
        if (data == null || data.length != file.size) {
          throw FormatException('Attachment ${file.name} could not be read.');
        }
        contents[file.id] = data;
      }
      final package = TripPackage(
        places: places,
        actions: actions,
        visaPlans: visaPlans,
        files: files,
        fileBytes: contents,
      );
      _validate(package);
      return package;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('This file is not a valid trip package.');
    }
  }

  static void _validate(TripPackage package) {
    if (package.files.length > maxFiles ||
        package.places.length +
                package.actions.length +
                package.visaPlans.length >
            maxRecords) {
      throw const FormatException('Trip package contains too many items.');
    }
    _uniqueIds(package.places.map((place) => place.id));
    _uniqueIds(package.actions.map((action) => action.id));
    _uniqueIds(package.visaPlans.map((plan) => plan.id));
    _uniqueIds(package.files.map((file) => file.id));
    var totalBytes = 0;
    for (final file in package.files) {
      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(file.id) ||
          file.name.trim().isEmpty ||
          file.name.contains('/') ||
          file.name.contains('\\')) {
        throw const FormatException('Trip package has an invalid attachment.');
      }
      final bytes = package.fileBytes[file.id];
      if (bytes == null || bytes.length != file.size) {
        throw FormatException('Attachment ${file.name} is missing or damaged.');
      }
      totalBytes += bytes.length;
      if (totalBytes > maxPackageBytes) {
        throw const FormatException('Trip attachments are too large to share.');
      }
    }
    if (package.fileBytes.length != package.files.length) {
      throw const FormatException('Trip package has unexpected attachments.');
    }
  }

  static void _uniqueIds(Iterable<String> ids) {
    final seen = <String>{};
    for (final id in ids) {
      if (id.isEmpty || !seen.add(id)) {
        throw const FormatException('Trip package has duplicate or empty IDs.');
      }
    }
  }
}
