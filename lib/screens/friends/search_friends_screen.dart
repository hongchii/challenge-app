import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/friend_request.dart';

class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({super.key});

  @override
  State<SearchFriendsScreen> createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final _searchController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _uuid = const Uuid();
  
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await _firestoreService.searchUsersByNickname(query);
      
      // 자기 자신은 제외
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userModel?.id;
      
      setState(() {
        _searchResults = results
            .where((user) => user.id != currentUserId)
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('검색 실패: $e'),
            backgroundColor: const Color(0xFFFF5247),
          ),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(UserModel targetUser) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.id;
    
    if (currentUserId == null) return;

    try {
      final request = FriendRequest(
        id: _uuid.v4(),
        fromUserId: currentUserId,
        toUserId: targetUser.id,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestoreService.sendFriendRequest(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${targetUser.nickname}님에게 친구 요청을 보냈습니다'),
            backgroundColor: const Color(0xFF17C964),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('요청 실패: $e'),
            backgroundColor: const Color(0xFFFF5247),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 검색'),
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '닉네임으로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchResults = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (value) => _searchUsers(),
            ),
          ),

          // 검색 버튼
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchUsers,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isSearching ? '검색 중...' : '검색'),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 검색 결과
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched && _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          '검색 결과가 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B95A1),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return _UserCard(
                            user: user,
                            onSendRequest: () => _sendFriendRequest(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onSendRequest;

  const _UserCard({
    required this.user,
    required this.onSendRequest,
  });

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
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? const Icon(
                  Icons.person,
                  color: Color(0xFF3182F6),
                )
              : null,
        ),
        title: Text(
          user.nickname,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          user.email,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8B95A1),
          ),
        ),
        trailing: OutlinedButton(
          onPressed: onSendRequest,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF3182F6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            '친구 신청',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF3182F6),
            ),
          ),
        ),
      ),
    );
  }
}

