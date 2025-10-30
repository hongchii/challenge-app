import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import '../../providers/auth_provider.dart';
import '../../providers/auth_provider_mock.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/penalty_history_screen.dart';
import '../friends/friends_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMock>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: ListView(
        children: [
          // 프로필 카드
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E8EB)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFE8F3FF),
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 40,
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
                        user.nickname,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191F28),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B95A1),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 메뉴 리스트
          _buildMenuSection(
            context,
            '내 정보',
            [
              _MenuItem(
                icon: Icons.person_outline,
                title: '내 프로필',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.people_outline,
                title: '친구 관리',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FriendsScreen(),
                    ),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.account_balance_wallet_outlined,
                title: '벌금 현황',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PenaltyHistoryScreen(
                        userId: user.id,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          _buildMenuSection(
            context,
            '설정',
            [
              _MenuItem(
                icon: Icons.logout,
                title: '로그아웃',
                onTap: () {
                  _showLogoutDialog(context, authProvider);
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    String title,
    List<_MenuItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B95A1),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E8EB)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (index > 0) const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      item.icon,
                      color: const Color(0xFF4E5968),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF191F28),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF8B95A1),
                    ),
                    onTap: item.onTap,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProviderMock authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Color(0xFFFF5247)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

