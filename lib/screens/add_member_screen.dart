import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/challenge_invitation.dart';
import '../models/user_model.dart';

class AddMemberScreen extends StatefulWidget {
  final String challengeId;
  final String challengeTitle;

  const AddMemberScreen({
    super.key,
    required this.challengeId,
    required this.challengeTitle,
  });

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _firestoreService = FirestoreService();
  final Set<String> _selectedFriendIds = {};
  bool _isSending = false;

  Future<void> _sendInvitations() async {
    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('초대할 친구를 선택해주세요'),
          backgroundColor: Color(0xFFFF5247),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.userModel;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final uuid = const Uuid();

      // 선택한 친구들에게 초대 보내기
      for (final friendId in _selectedFriendIds) {
        final invitation = ChallengeInvitation(
          id: uuid.v4(),
          challengeId: widget.challengeId,
          challengeTitle: widget.challengeTitle,
          fromUserId: currentUser.id,
          fromUserNickname: currentUser.nickname,
          toUserId: friendId,
          createdAt: DateTime.now(),
        );

        await _firestoreService.sendChallengeInvitation(invitation);
      }

      setState(() => _isSending = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedFriendIds.length}명에게 초대를 보냈습니다!'),
            backgroundColor: const Color(0xFF17C964),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('초대 실패: $e'),
            backgroundColor: const Color(0xFFFF5247),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('친구 초대하기'),
          backgroundColor: const Color(0xFFF9FAFB),
        ),
        body: const Center(
          child: Text('로그인이 필요합니다'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('친구 초대하기'),
        backgroundColor: const Color(0xFFF9FAFB),
      ),
      body: StreamBuilder<UserModel?>(
        stream: _firestoreService.userStream(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          final friendIds = user?.friendIds ?? [];

          if (friendIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 친구가 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '친구를 먼저 추가해주세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3182F6), Color(0xFF1B64DA)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '챌린지 초대',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            widget.challengeTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '친구 목록 (${friendIds.length}명)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191F28),
                      ),
                    ),
                    if (_selectedFriendIds.isNotEmpty)
                      Text(
                        '${_selectedFriendIds.length}명 선택',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3182F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: friendIds.length,
                  itemBuilder: (context, index) {
                    final friendId = friendIds[index];
                    return FutureBuilder<UserModel?>(
                      future: _firestoreService.getUser(friendId),
                      builder: (context, friendSnapshot) {
                        if (!friendSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final friend = friendSnapshot.data!;
                        final isSelected = _selectedFriendIds.contains(friendId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE8F3FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF3182F6)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF3182F6),
                              backgroundImage: friend.profileImageUrl != null
                                  ? NetworkImage(friend.profileImageUrl!)
                                  : null,
                              child: friend.profileImageUrl == null
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            title: Text(
                              friend.nickname,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              friend.email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8B95A1),
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF3182F6),
                                  )
                                : const Icon(
                                    Icons.circle_outlined,
                                    color: Color(0xFFE5E8EB),
                                  ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedFriendIds.remove(friendId);
                                } else {
                                  _selectedFriendIds.add(friendId);
                                }
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _selectedFriendIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendInvitations,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('${_selectedFriendIds.length}명에게 초대 보내기'),
                ),
              ),
            )
          : null,
    );
  }
}
