import 'dart:math';

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.notes,
    required this.latitude,
    required this.longitude,
    required this.visited,
    required this.createdAt,
    this.plannedFor,
  });

  final String id;
  final String name;
  final String notes;
  final double latitude;
  final double longitude;
  final bool visited;
  final DateTime createdAt;
  final DateTime? plannedFor;

  factory Place.create({
    required String name,
    required String notes,
    required double latitude,
    required double longitude,
    DateTime? plannedFor,
  }) {
    return Place(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
      name: name,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
      visited: false,
      createdAt: DateTime.now(),
      plannedFor: plannedFor,
    );
  }

  Place copyWith({
    String? name,
    String? notes,
    double? latitude,
    double? longitude,
    bool? visited,
    DateTime? plannedFor,
    bool clearPlannedFor = false,
  }) {
    return Place(
      id: id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      visited: visited ?? this.visited,
      createdAt: createdAt,
      plannedFor: clearPlannedFor ? null : plannedFor ?? this.plannedFor,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
    'latitude': latitude,
    'longitude': longitude,
    'visited': visited,
    'createdAt': createdAt.toIso8601String(),
    'plannedFor': plannedFor == null
        ? null
        : '${plannedFor!.year.toString().padLeft(4, '0')}-${plannedFor!.month.toString().padLeft(2, '0')}-${plannedFor!.day.toString().padLeft(2, '0')}',
  };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['id'] as String,
    name: json['name'] as String,
    notes: json['notes'] as String? ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    visited: json['visited'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    plannedFor: json['plannedFor'] is String
        ? DateTime.parse(json['plannedFor'] as String)
        : null,
  );
}
