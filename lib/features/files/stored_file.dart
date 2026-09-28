class StoredFile {
  const StoredFile({
    required this.id,
    required this.name,
    required this.size,
    required this.importedAt,
  });

  final String id;
  final String name;
  final int size;
  final DateTime importedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'importedAt': importedAt.toIso8601String(),
  };

  factory StoredFile.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      throw const FormatException('Invalid stored file identifier');
    }
    return StoredFile(
      id: id,
      name: json['name'] as String,
      size: json['size'] as int,
      importedAt: DateTime.parse(json['importedAt'] as String),
    );
  }
}
