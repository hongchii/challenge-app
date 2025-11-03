import '../utils/text_encoding.dart';

class ChallengeInvitation {
  final String id;
  final String challengeId;
  final String challengeTitle;
  final String fromUserId; // 초대를 보낸 사람 (그룹장)
  final String fromUserNickname;
  final String toUserId; // 초대를 받은 사람
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  ChallengeInvitation({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    required this.fromUserId,
    required this.fromUserNickname,
    required this.toUserId,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'fromUserId': fromUserId,
      'fromUserNickname': fromUserNickname,
      'toUserId': toUserId,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory ChallengeInvitation.fromJson(Map<String, dynamic> json) {
    return ChallengeInvitation(
      id: TextEncoding.safeStringFromJson(json, 'id'),
      challengeId: TextEncoding.safeStringFromJson(json, 'challengeId'),
      challengeTitle: TextEncoding.safeStringFromJson(json, 'challengeTitle'),
      fromUserId: TextEncoding.safeStringFromJson(json, 'fromUserId'),
      fromUserNickname: TextEncoding.safeStringFromJson(json, 'fromUserNickname'),
      toUserId: TextEncoding.safeStringFromJson(json, 'toUserId'),
      createdAt: DateTime.parse(TextEncoding.safeStringFromJson(json, 'createdAt')),
      status: TextEncoding.safeStringFromJson(json, 'status', defaultValue: 'pending'),
    );
  }

  ChallengeInvitation copyWith({
    String? id,
    String? challengeId,
    String? challengeTitle,
    String? fromUserId,
    String? fromUserNickname,
    String? toUserId,
    DateTime? createdAt,
    String? status,
  }) {
    return ChallengeInvitation(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserNickname: fromUserNickname ?? this.fromUserNickname,
      toUserId: toUserId ?? this.toUserId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}


