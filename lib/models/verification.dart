import '../utils/text_encoding.dart';

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
        id: TextEncoding.safeStringFromJson(json, 'id'),
        memberId: TextEncoding.safeStringFromJson(json, 'memberId'),
        dateTime: DateTime.parse(TextEncoding.safeStringFromJson(json, 'dateTime')),
        imagePath: json['imagePath'] != null 
            ? TextEncoding.normalizeString(json['imagePath'])
            : null,
        note: json['note'] != null 
            ? TextEncoding.normalizeString(json['note'])
            : null,
      );
}

