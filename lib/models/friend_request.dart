enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        id: json['id'],
        fromUserId: json['fromUserId'],
        toUserId: json['toUserId'],
        status: FriendRequestStatus.values
            .firstWhere((e) => e.name == json['status']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

