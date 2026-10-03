import 'package:file_picker/file_picker.dart';

import '../../features/files/stored_file.dart';

class FileStore {
  bool get isAvailable => false;

  Future<List<StoredFile>> loadFiles() async => const [];

  Future<void> saveFiles(List<StoredFile> files) async {}

  Future<StoredFile> importFile(PlatformFile file) async =>
      throw UnsupportedError(
        'Local file storage is available in the device app.',
      );

  Future<Uri?> exportFile(StoredFile file) async => throw UnsupportedError(
    'Local file storage is available in the device app.',
  );

  Future<String> pathFor(StoredFile file) async => throw UnsupportedError(
    'Local file storage is available in the device app.',
  );

  Future<List<int>> readFile(StoredFile file) async => throw UnsupportedError(
    'Local file storage is available in the device app.',
  );

  Future<void> deleteFile(StoredFile file) async => throw UnsupportedError(
    'Local file storage is available in the device app.',
  );
}
