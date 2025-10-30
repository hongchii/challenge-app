enum PaymentStatus {
  pending,    // 입금 대기
  completed,  // 입금 완료 (확인됨)
}

class PaymentRecord {
  final String id;
  final String challengeId;
  final String memberId;
  final double amount;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  PaymentRecord({
    required this.id,
    required this.challengeId,
    required this.memberId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'challengeId': challengeId,
        'memberId': memberId,
        'amount': amount,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'confirmedAt': confirmedAt?.toIso8601String(),
      };

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        id: json['id'],
        challengeId: json['challengeId'],
        memberId: json['memberId'],
        amount: json['amount'],
        status: PaymentStatus.values.firstWhere((e) => e.name == json['status']),
        createdAt: DateTime.parse(json['createdAt']),
        confirmedAt: json['confirmedAt'] != null
            ? DateTime.parse(json['confirmedAt'])
            : null,
      );
}

