import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/friend_request.dart';
import 'search_friends_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('친구'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '내 친구'),
              Tab(text: '친구 요청'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: '친구 검색',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchFriendsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _FriendsListTab(userId: userId),
            _FriendRequestsTab(userId: userId),
          ],
        ),
      ),
    );
  }
}

class _FriendsListTab extends StatelessWidget {
  final String userId;

  const _FriendsListTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return FutureBuilder<UserModel?>(
      future: firestoreService.getUser(userId),
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
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    size: 50,
                    color: Color(0xFF8B95A1),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '아직 친구가 없어요',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191F28),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '친구를 검색해서 추가해보세요!',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8B95A1),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friendIds.length,
          itemBuilder: (context, index) {
            return FutureBuilder<UserModel?>(
              future: firestoreService.getUser(friendIds[index]),
              builder: (context, friendSnapshot) {
                if (!friendSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final friend = friendSnapshot.data!;
                return _FriendCard(friend: friend);
              },
            );
          },
        );
      },
    );
  }
}

class _FriendRequestsTab extends StatelessWidget {
  final String userId;

  const _FriendRequestsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<List<FriendRequest>>(
      stream: firestoreService.receivedFriendRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Text(
              '친구 요청이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8B95A1),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return FutureBuilder<UserModel?>(
              future: firestoreService.getUser(request.fromUserId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final requester = userSnapshot.data!;
                return _FriendRequestCard(
                  requester: requester,
                  request: request,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FriendCard extends StatelessWidget {
  final UserModel friend;

  const _FriendCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFE8F3FF),
          backgroundImage: friend.profileImageUrl != null
              ? NetworkImage(friend.profileImageUrl!)
              : null,
          child: friend.profileImageUrl == null
              ? const Icon(
                  Icons.person,
                  color: Color(0xFF3182F6),
                )
              : null,
        ),
        title: Text(
          friend.nickname,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          friend.email,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8B95A1),
          ),
        ),
      ),
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  final UserModel requester;
  final FriendRequest request;

  const _FriendRequestCard({
    required this.requester,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE8F3FF),
              backgroundImage: requester.profileImageUrl != null
                  ? NetworkImage(requester.profileImageUrl!)
                  : null,
              child: requester.profileImageUrl == null
                  ? const Icon(
                      Icons.person,
                      color: Color(0xFF3182F6),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requester.nickname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    requester.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8B95A1),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    try {
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
                            content: Text('오류: $e'),
                            backgroundColor: const Color(0xFFFF5247),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  color: const Color(0xFF17C964),
                  iconSize: 28,
                ),
                IconButton(
                  onPressed: () async {
                    try {
                      await firestoreService.rejectFriendRequest(request.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('친구 요청을 거절했습니다'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('오류: $e'),
                            backgroundColor: const Color(0xFFFF5247),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.cancel),
                  color: const Color(0xFFFF5247),
                  iconSize: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

