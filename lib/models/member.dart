class Member {
  final String id;
  final String name;
  final bool isLeader;

  Member({
    required this.id,
    required this.name,
    this.isLeader = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isLeader': isLeader,
      };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'],
        name: json['name'],
        isLeader: json['isLeader'] ?? false,
      );
}

