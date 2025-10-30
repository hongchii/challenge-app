class Verification {
  final String id;
  final String memberId;
  final DateTime dateTime;
  final String? imagePath;
  final String? note;

  Verification({
    required this.id,
    required this.memberId,
    required this.dateTime,
    this.imagePath,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'dateTime': dateTime.toIso8601String(),
        'imagePath': imagePath,
        'note': note,
      };

  factory Verification.fromJson(Map<String, dynamic> json) => Verification(
        id: json['id'],
        memberId: json['memberId'],
        dateTime: DateTime.parse(json['dateTime']),
        imagePath: json['imagePath'],
        note: json['note'],
      );
}

