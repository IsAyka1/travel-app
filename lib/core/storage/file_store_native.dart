import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/files/stored_file.dart';

class FileStore {
  bool get isAvailable => true;

  Future<Directory> _root() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}travel_app',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> _index() async {
    final root = await _root();
    return File('${root.path}${Platform.pathSeparator}files.json');
  }

  Future<File> _storedFile(StoredFile file) async {
    final root = await _root();
    final files = Directory('${root.path}${Platform.pathSeparator}files');
    await files.create(recursive: true);
    return File('${files.path}${Platform.pathSeparator}${file.id}');
  }

  Future<List<StoredFile>> loadFiles() async {
    final index = await _index();
    if (!await index.exists()) return [];
    final decoded = jsonDecode(await index.readAsString()) as List<dynamic>;
    return decoded
        .map((entry) => StoredFile.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFiles(List<StoredFile> files) async {
    final index = await _index();
    await index.writeAsString(
      jsonEncode(files.map((file) => file.toJson()).toList()),
      flush: true,
    );
  }

  Future<StoredFile> importFile(PlatformFile picked) async {
    final cleanName = picked.name.split(RegExp(r'[/\\]')).last.trim();
    if (cleanName.isEmpty || cleanName == '.' || cleanName == '..') {
      throw const FormatException('The selected file has no valid name.');
    }

    final file = StoredFile(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
      name: cleanName,
      size: 0,
      importedAt: DateTime.now(),
    );
    final destination = await _storedFile(file);
    final sink = destination.openWrite();
    try {
      await sink.addStream(picked.readAsByteStream());
      await sink.close();
      final length = await destination.length();
      return StoredFile(
        id: file.id,
        name: cleanName,
        size: length,
        importedAt: file.importedAt,
      );
    } catch (_) {
      await sink.close();
      if (await destination.exists()) await destination.delete();
      rethrow;
    }
  }

  Future<Uri?> exportFile(StoredFile file) async {
    final source = await _storedFile(file);
    return FilePicker.saveFile(
      dialogTitle: 'Save ${file.name} to your device',
      fileName: file.name,
      bytes: await source.readAsBytes(),
    );
  }

  Future<void> deleteFile(StoredFile file) async {
    final stored = await _storedFile(file);
    if (await stored.exists()) await stored.delete();
  }
}
