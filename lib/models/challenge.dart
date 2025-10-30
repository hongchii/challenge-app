import 'member.dart';
import 'verification.dart';
import 'penalty.dart';

enum ChallengeFrequency {
  daily,       // 매일
  weekly,      // 주 n회
  monthly,     // 월 n회
}

enum PenaltyType {
  none,        // 없음
  percentage,  // 이자율 (%)
  fixedAmount, // 고정 금액 (+원)
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final String rules;
  final DateTime startDate;
  final DateTime? endDate; // null이면 미정
  final ChallengeFrequency frequency;
  final int frequencyCount; // 주 3회, 월 5회 등의 횟수
  final double penaltyAmount; // 1회 실패당 벌금
  final PenaltyType penaltyType; // 벌금 타입
  final double penaltyValue; // 이자율(%) 또는 추가 금액(원)
  final bool isPrivate; // 비밀 챌린지 여부
  final int? maxParticipants; // 최대 정원 (null이면 무제한)
  final String creatorId; // 생성자(그룹장) ID
  final List<String> participantIds; // 참가자 ID 목록
  final List<String> pendingParticipantIds; // 승인 대기 중인 참가자 ID
  final List<Member> members;
  final List<Verification> verifications;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.rules,
    required this.startDate,
    this.endDate, // nullable
    required this.frequency,
    this.frequencyCount = 1,
    required this.penaltyAmount,
    this.penaltyType = PenaltyType.none,
    this.penaltyValue = 0.0,
    this.isPrivate = false,
    this.maxParticipants,
    required this.creatorId,
    List<String>? participantIds,
    List<String>? pendingParticipantIds,
    List<Member>? members,
    List<Verification>? verifications,
  })  : participantIds = participantIds ?? [],
        pendingParticipantIds = pendingParticipantIds ?? [],
        members = members ?? [],
        verifications = verifications ?? [];

  // 특정 멤버의 인증 횟수 계산
  int getVerificationCount(String memberId) {
    return verifications.where((v) => v.memberId == memberId).length;
  }

  // 특정 멤버의 실패 횟수 계산
  int getFailedCount(String memberId) {
    final now = DateTime.now();
    final daysPassed = now.difference(startDate).inDays + 1;
    
    int requiredCount = 0;
    switch (frequency) {
      case ChallengeFrequency.daily:
        requiredCount = daysPassed;
        break;
      case ChallengeFrequency.weekly:
        final weeksPassed = (daysPassed / 7).floor();
        requiredCount = weeksPassed * frequencyCount;
        break;
      case ChallengeFrequency.monthly:
        final monthsPassed = _getMonthsDifference(startDate, now);
        requiredCount = monthsPassed * frequencyCount;
        break;
    }

    final actualCount = getVerificationCount(memberId);
    return (requiredCount - actualCount).clamp(0, double.infinity).toInt();
  }

  // 월 차이 계산
  int _getMonthsDifference(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month;
  }

  // 벌금 계산
  Penalty calculatePenalty(String memberId) {
    final failedCount = getFailedCount(memberId);
    final basePenalty = failedCount * penaltyAmount;
    
    double totalAmount = basePenalty;
    
    switch (penaltyType) {
      case PenaltyType.none:
        totalAmount = basePenalty;
        break;
      case PenaltyType.percentage:
        // 이자율 (%)
        final interest = basePenalty * (penaltyValue / 100);
        totalAmount = basePenalty + interest;
        break;
      case PenaltyType.fixedAmount:
        // 고정 금액 추가
        totalAmount = basePenalty + (failedCount * penaltyValue);
        break;
    }

    return Penalty(
      memberId: memberId,
      failedCount: failedCount,
      amount: totalAmount,
    );
  }

  // 챌린지 복사 (불변성 유지)
  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    String? rules,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    ChallengeFrequency? frequency,
    int? frequencyCount,
    double? penaltyAmount,
    PenaltyType? penaltyType,
    double? penaltyValue,
    bool? isPrivate,
    int? maxParticipants,
    String? creatorId,
    List<String>? participantIds,
    List<String>? pendingParticipantIds,
    List<Member>? members,
    List<Verification>? verifications,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      frequency: frequency ?? this.frequency,
      frequencyCount: frequencyCount ?? this.frequencyCount,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      penaltyType: penaltyType ?? this.penaltyType,
      penaltyValue: penaltyValue ?? this.penaltyValue,
      isPrivate: isPrivate ?? this.isPrivate,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      creatorId: creatorId ?? this.creatorId,
      participantIds: participantIds ?? this.participantIds,
      pendingParticipantIds: pendingParticipantIds ?? this.pendingParticipantIds,
      members: members ?? this.members,
      verifications: verifications ?? this.verifications,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'rules': rules,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'frequency': frequency.name,
        'frequencyCount': frequencyCount,
        'penaltyAmount': penaltyAmount,
        'penaltyType': penaltyType.name,
        'penaltyValue': penaltyValue,
        'isPrivate': isPrivate,
        'maxParticipants': maxParticipants,
        'creatorId': creatorId,
        'participantIds': participantIds,
        'pendingParticipantIds': pendingParticipantIds,
        'members': members.map((m) => m.toJson()).toList(),
        'verifications': verifications.map((v) => v.toJson()).toList(),
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        rules: json['rules'],
        startDate: DateTime.parse(json['startDate']),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        frequency: ChallengeFrequency.values.firstWhere(
          (e) => e.name == json['frequency'],
        ),
        frequencyCount: json['frequencyCount'],
        penaltyAmount: json['penaltyAmount'],
        penaltyType: json['penaltyType'] != null
            ? PenaltyType.values.firstWhere((e) => e.name == json['penaltyType'])
            : PenaltyType.none,
        penaltyValue: json['penaltyValue'] ?? 0.0,
        isPrivate: json['isPrivate'] ?? false,
        maxParticipants: json['maxParticipants'],
        creatorId: json['creatorId'] ?? '',
        participantIds: List<String>.from(json['participantIds'] ?? []),
        pendingParticipantIds: List<String>.from(json['pendingParticipantIds'] ?? []),
        members: (json['members'] as List?)
            ?.map((m) => Member.fromJson(m))
            .toList() ?? [],
        verifications: (json['verifications'] as List?)
            ?.map((v) => Verification.fromJson(v))
            .toList() ?? [],
      );
}

