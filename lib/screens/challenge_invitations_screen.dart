import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/challenge_invitation.dart';
import '../models/friend_request.dart';
import '../models/challenge.dart';

enum NotificationType {
  challengeInvitation,
  friendRequest,
  participantRequest,
}

class NotificationItem {
  final NotificationType type;
  final dynamic data; // ChallengeInvitation, FriendRequest, or Map with challenge and userId
  final DateTime createdAt;

  NotificationItem({
    required this.type,
    required this.data,
    required this.createdAt,
  });
}

class ChallengeInvitationsScreen extends StatefulWidget {
  const ChallengeInvitationsScreen({super.key});

  @override
  State<ChallengeInvitationsScreen> createState() => _ChallengeInvitationsScreenState();
}

class _ChallengeInvitationsScreenState extends State<ChallengeInvitationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  List<ChallengeInvitation> _invitations = [];
  List<FriendRequest> _friendRequests = [];
  List<Challenge> _pendingChallenges = [];

  void _loadNotifications(String currentUserId) {
    final firestoreService = FirestoreService();

    // 각 Stream을 개별적으로 구독하고 업데이트
    firestoreService.challengeInvitationsStream(currentUserId).listen(
      (invitations) {
        setState(() {
          _invitations = invitations;
        });
        _updateNotifications(currentUserId);
      },
    );

    firestoreService.receivedFriendRequests(currentUserId).listen(
      (friendRequests) {
        setState(() {
          _friendRequests = friendRequests;
        });
        _updateNotifications(currentUserId);
      },
    );

    firestoreService.pendingParticipantRequests(currentUserId).listen(
      (pendingChallenges) {
        setState(() {
          _pendingChallenges = pendingChallenges;
        });
        _updateNotifications(currentUserId);
      },
    );
  }

  Future<void> _updateNotifications(String currentUserId) async {
    final firestoreService = FirestoreService();
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

    final List<NotificationItem> notifications = [];

    // 챌린지 초대 추가
    for (final invitation in _invitations) {
      if (invitation.createdAt.isAfter(threeDaysAgo)) {
        notifications.add(NotificationItem(
          type: NotificationType.challengeInvitation,
          data: invitation,
          createdAt: invitation.createdAt,
        ));
      }
    }

    // 친구 요청 추가
    for (final request in _friendRequests) {
      if (request.createdAt.isAfter(threeDaysAgo)) {
        notifications.add(NotificationItem(
          type: NotificationType.friendRequest,
          data: request,
          createdAt: request.createdAt,
        ));
      }
    }

    // 참가 신청 추가
    for (final challenge in _pendingChallenges) {
      for (final userId in challenge.pendingParticipantIds) {
        final requestDate = challenge.createdAt ?? challenge.startDate;
        if (requestDate.isAfter(threeDaysAgo)) {
          final user = await firestoreService.getUser(userId);
          notifications.add(NotificationItem(
            type: NotificationType.participantRequest,
            data: {
              'challenge': challenge,
              'userId': userId,
              'userNickname': user?.nickname ?? '사용자',
            },
            createdAt: requestDate,
          ));
        }
      }
    }

    // 생성일 기준으로 정렬 (최신순)
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptInvitation(
    BuildContext context,
    ChallengeInvitation invitation,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userModel?.id;

      if (currentUserId == null) {
        throw Exception('로그인이 필요합니다');
      }

      final firestoreService = FirestoreService();
      await firestoreService.acceptChallengeInvitation(
        invitation.id,
        invitation.challengeId,
        currentUserId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('챌린지에 참가했습니다!'),
            backgroundColor: Color(0xFF17C964),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('참가 실패: $e'),
            backgroundColor: const Color(0xFFFF5247),
          ),
        );
      }
    }
  }

  Future<void> _rejectInvitation(
    BuildContext context,
    ChallengeInvitation invitation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '초대 거절',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('이 초대를 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B95A1),
            ),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF5247),
            ),
            child: const Text(
              '거절',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final firestoreService = FirestoreService();
        await firestoreService.rejectChallengeInvitation(invitation.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('초대를 거절했습니다'),
              backgroundColor: Color(0xFF8B95A1),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('거절 실패: $e'),
              backgroundColor: const Color(0xFFFF5247),
            ),
          );
        }
      }
    }
  }

  Future<void> _acceptFriendRequest(
    BuildContext context,
    FriendRequest request,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userModel?.id;

      if (currentUserId == null) {
        throw Exception('로그인이 필요합니다');
      }

      final firestoreService = FirestoreService();
      await firestoreService.acceptFriendRequest(
        request.id,
        request.fromUserId,
        request.toUserId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 요청을 수락했습니다'),
            backgroundColor: Color(0xFF17C964),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수락 실패: $e'),
            backgroundColor: const Color(0xFFFF5247),
          ),
        );
      }
    }
  }

  Future<void> _rejectFriendRequest(
    BuildContext context,
    FriendRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '친구 요청 거절',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('이 친구 요청을 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B95A1),
            ),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF5247),
            ),
            child: const Text(
              '거절',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final firestoreService = FirestoreService();
        await firestoreService.rejectFriendRequest(request.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('친구 요청을 거절했습니다'),
              backgroundColor: Color(0xFF8B95A1),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('거절 실패: $e'),
              backgroundColor: const Color(0xFFFF5247),
            ),
          );
        }
      }
    }
  }

  Future<void> _approveParticipant(
    BuildContext context,
    String challengeId,
    String userId,
  ) async {
    try {
      final firestoreService = FirestoreService();
      await firestoreService.approveParticipant(challengeId, userId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('참가 신청을 수락했습니다'),
            backgroundColor: Color(0xFF17C964),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수락 실패: $e'),
            backgroundColor: const Color(0xFFFF5247),
          ),
        );
      }
    }
  }

  Future<void> _rejectParticipant(
    BuildContext context,
    String challengeId,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '참가 신청 거절',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('이 참가 신청을 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B95A1),
            ),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF5247),
            ),
            child: const Text(
              '거절',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final firestoreService = FirestoreService();
        await firestoreService.rejectParticipant(challengeId, userId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('참가 신청을 거절했습니다'),
              backgroundColor: Color(0xFF8B95A1),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('거절 실패: $e'),
              backgroundColor: const Color(0xFFFF5247),
            ),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userModel?.id;
      if (currentUserId != null) {
        _loadNotifications(currentUserId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userModel?.id;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('알림'),
          backgroundColor: const Color(0xFFF9FAFB),
        ),
        body: const Center(
          child: Text('로그인이 필요합니다'),
        ),
      );
    }

    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('알림'),
        backgroundColor: const Color(0xFFF9FAFB),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                        Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                        '알림이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];

                    switch (notification.type) {
                      case NotificationType.challengeInvitation:
                        return _buildChallengeInvitationItem(
                          context,
                          notification.data as ChallengeInvitation,
                          dateFormat,
                        );
                      case NotificationType.friendRequest:
                        return _buildFriendRequestItem(
                          context,
                          notification.data as FriendRequest,
                          dateFormat,
                        );
                      case NotificationType.participantRequest:
                        final data = notification.data as Map<String, dynamic>;
                        return _buildParticipantRequestItem(
                          context,
                          data['challenge'] as Challenge,
                          data['userId'] as String,
                          data['userNickname'] as String,
                          dateFormat,
                        );
                    }
                  },
              ),
            );
          }

  Widget _buildChallengeInvitationItem(
    BuildContext context,
    ChallengeInvitation invitation,
    DateFormat dateFormat,
  ) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3182F6), Color(0xFF1B64DA)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                      const Text(
                        '챌린지 초대',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B95A1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                                Text(
                                  invitation.challengeTitle,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF191F28),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Color(0xFF8B95A1),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${invitation.fromUserNickname}님의 초대',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF8B95A1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dateFormat.format(invitation.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B95A1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _rejectInvitation(context, invitation),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF8B95A1),
                                side: const BorderSide(color: Color(0xFFE5E8EB)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('거절'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => _acceptInvitation(context, invitation),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('수락하고 참가'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRequestItem(
    BuildContext context,
    FriendRequest request,
    DateFormat dateFormat,
  ) {
    return FutureBuilder(
      future: FirestoreService().getUser(request.fromUserId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final nickname = user?.nickname ?? '사용자';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17C964).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Color(0xFF17C964),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '친구 요청',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8B95A1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$nickname님의 친구 요청',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191F28),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  dateFormat.format(request.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B95A1),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectFriendRequest(context, request),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B95A1),
                          side: const BorderSide(color: Color(0xFFE5E8EB)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('거절'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _acceptFriendRequest(context, request),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('수락'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildParticipantRequestItem(
    BuildContext context,
    Challenge challenge,
    String userId,
    String userNickname,
    DateFormat dateFormat,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '참가 신청',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B95A1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191F28),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 14,
                            color: Color(0xFF8B95A1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$userNickname님이 참가를 신청했습니다',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8B95A1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dateFormat.format(challenge.createdAt ?? challenge.startDate),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8B95A1),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectParticipant(context, challenge.id, userId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B95A1),
                      side: const BorderSide(color: Color(0xFFE5E8EB)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('거절'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _approveParticipant(context, challenge.id, userId),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('수락'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}