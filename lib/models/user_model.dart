class UserModel {
  final String id;
  final String email;
  final String nickname;
  final String? profileImageUrl;
  final DateTime createdAt;
  final List<String> friendIds;

  UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
    required this.createdAt,
    List<String>? friendIds,
  }) : friendIds = friendIds ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'profileImageUrl': profileImageUrl,
        'createdAt': createdAt.toIso8601String(),
        'friendIds': friendIds,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        email: json['email'],
        nickname: json['nickname'],
        profileImageUrl: json['profileImageUrl'],
        createdAt: DateTime.parse(json['createdAt']),
        friendIds: List<String>.from(json['friendIds'] ?? []),
      );

  UserModel copyWith({
    String? id,
    String? email,
    String? nickname,
    String? profileImageUrl,
    DateTime? createdAt,
    List<String>? friendIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      friendIds: friendIds ?? this.friendIds,
    );
  }
}

