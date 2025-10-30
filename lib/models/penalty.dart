class Penalty {
  final String memberId;
  final int failedCount;
  final double amount;

  Penalty({
    required this.memberId,
    required this.failedCount,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'failedCount': failedCount,
        'amount': amount,
      };

  factory Penalty.fromJson(Map<String, dynamic> json) => Penalty(
        memberId: json['memberId'],
        failedCount: json['failedCount'],
        amount: json['amount'],
      );
}

