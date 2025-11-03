import '../utils/text_encoding.dart';

/// 읽지 않은 인증 알림을 Firestore에 저장하기 위한 모델
class VerificationNotification {
  final String id;
  final String challengeId;
  final String challengeTitle;
  final String verificationId;
  final String memberId; // 인증을 올린 멤버 ID
  final String memberNickname; // 인증을 올린 멤버 닉네임
  final String toUserId; // 알림을 받을 사용자 ID
  final DateTime createdAt;
  final bool isRead; // 읽음 여부

  VerificationNotification({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    required this.verificationId,
    required this.memberId,
    required this.memberNickname,
    required this.toUserId,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'challengeId': challengeId,
        'challengeTitle': challengeTitle,
        'verificationId': verificationId,
        'memberId': memberId,
        'memberNickname': memberNickname,
        'toUserId': toUserId,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory VerificationNotification.fromJson(Map<String, dynamic> json) =>
      VerificationNotification(
        id: TextEncoding.safeStringFromJson(json, 'id'),
        challengeId: TextEncoding.safeStringFromJson(json, 'challengeId'),
        challengeTitle: TextEncoding.safeStringFromJson(json, 'challengeTitle'),
        verificationId: TextEncoding.safeStringFromJson(json, 'verificationId'),
        memberId: TextEncoding.safeStringFromJson(json, 'memberId'),
        memberNickname: TextEncoding.safeStringFromJson(json, 'memberNickname'),
        toUserId: TextEncoding.safeStringFromJson(json, 'toUserId'),
        createdAt: DateTime.parse(
          TextEncoding.safeStringFromJson(json, 'createdAt'),
        ),
        isRead: json['isRead'] ?? false,
      );
}

