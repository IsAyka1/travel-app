import 'dart:math';

String _newId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';

class VisaChecklistItem {
  const VisaChecklistItem({
    required this.id,
    required this.title,
    required this.done,
  });

  final String id;
  final String title;
  final bool done;

  factory VisaChecklistItem.create(String title) =>
      VisaChecklistItem(id: _newId(), title: title, done: false);

  VisaChecklistItem copyWith({String? title, bool? done}) => VisaChecklistItem(
    id: id,
    title: title ?? this.title,
    done: done ?? this.done,
  );

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'done': done};

  factory VisaChecklistItem.fromJson(Map<String, dynamic> json) =>
      VisaChecklistItem(
        id: json['id'] as String,
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
      );
}

class VisaPlan {
  const VisaPlan({
    required this.id,
    required this.destination,
    required this.visaRequired,
    required this.applicationRequired,
    required this.allowedStayDays,
    required this.checklist,
  });

  final String id;
  final String destination;
  final bool? visaRequired;
  final bool? applicationRequired;
  final int? allowedStayDays;
  final List<VisaChecklistItem> checklist;

  factory VisaPlan.create({
    required String destination,
    bool? visaRequired,
    bool? applicationRequired,
    int? allowedStayDays,
  }) => VisaPlan(
    id: _newId(),
    destination: destination,
    visaRequired: visaRequired,
    applicationRequired: applicationRequired,
    allowedStayDays: allowedStayDays,
    checklist: const [],
  );

  VisaPlan withDetails({
    required String destination,
    required bool? visaRequired,
    required bool? applicationRequired,
    required int? allowedStayDays,
  }) => VisaPlan(
    id: id,
    destination: destination,
    visaRequired: visaRequired,
    applicationRequired: applicationRequired,
    allowedStayDays: allowedStayDays,
    checklist: checklist,
  );

  VisaPlan withChecklist(List<VisaChecklistItem> items) => VisaPlan(
    id: id,
    destination: destination,
    visaRequired: visaRequired,
    applicationRequired: applicationRequired,
    allowedStayDays: allowedStayDays,
    checklist: List.unmodifiable(items),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'destination': destination,
    'visaRequired': visaRequired,
    'applicationRequired': applicationRequired,
    'allowedStayDays': allowedStayDays,
    'checklist': checklist.map((item) => item.toJson()).toList(),
  };

  factory VisaPlan.fromJson(Map<String, dynamic> json) => VisaPlan(
    id: json['id'] as String,
    destination: json['destination'] as String,
    visaRequired: json['visaRequired'] as bool?,
    applicationRequired: json['applicationRequired'] as bool?,
    allowedStayDays: (json['allowedStayDays'] as num?)?.toInt(),
    checklist: (json['checklist'] as List<dynamic>? ?? const [])
        .map((item) => VisaChecklistItem.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
