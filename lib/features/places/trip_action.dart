import 'dart:math';

enum ReservationStatus { none, need, has }

class TripAction {
  const TripAction({
    required this.id,
    required this.title,
    required this.notes,
    required this.day,
    required this.minutesFromMidnight,
    required this.done,
    required this.reservation,
    required this.placeId,
    required this.attachmentId,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String notes;
  final DateTime day;
  final int? minutesFromMidnight;
  final bool done;
  final ReservationStatus reservation;
  final String? placeId;
  final String? attachmentId;
  final DateTime createdAt;

  factory TripAction.create({
    required String title,
    required String notes,
    required DateTime day,
    int? minutesFromMidnight,
    ReservationStatus reservation = ReservationStatus.none,
    String? placeId,
    String? attachmentId,
  }) => TripAction(
    id: '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
    title: title,
    notes: notes,
    day: DateTime(day.year, day.month, day.day),
    minutesFromMidnight: minutesFromMidnight,
    done: false,
    reservation: reservation,
    placeId: placeId,
    attachmentId: attachmentId,
    createdAt: DateTime.now(),
  );

  TripAction copyWith({
    String? title,
    String? notes,
    DateTime? day,
    int? minutesFromMidnight,
    bool clearTime = false,
    bool? done,
    ReservationStatus? reservation,
    String? placeId,
    bool clearPlace = false,
    String? attachmentId,
    bool clearAttachment = false,
  }) => TripAction(
    id: id,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    day: day == null ? this.day : DateTime(day.year, day.month, day.day),
    minutesFromMidnight: clearTime
        ? null
        : minutesFromMidnight ?? this.minutesFromMidnight,
    done: done ?? this.done,
    reservation: reservation ?? this.reservation,
    placeId: clearPlace ? null : placeId ?? this.placeId,
    attachmentId: clearAttachment ? null : attachmentId ?? this.attachmentId,
    createdAt: createdAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'day':
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
    'minutesFromMidnight': minutesFromMidnight,
    'done': done,
    'reservation': reservation.name,
    'placeId': placeId,
    'attachmentId': attachmentId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TripAction.fromJson(Map<String, dynamic> json) {
    final minutes = json['minutesFromMidnight'];
    final reservationName = json['reservation'];
    return TripAction(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      day: DateTime.parse(json['day'] as String),
      minutesFromMidnight: minutes is int && minutes >= 0 && minutes < 1440
          ? minutes
          : null,
      done: json['done'] as bool? ?? false,
      reservation: ReservationStatus.values.firstWhere(
        (status) => status.name == reservationName,
        orElse: () => ReservationStatus.none,
      ),
      placeId: json['placeId'] as String?,
      attachmentId: json['attachmentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
