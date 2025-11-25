import 'package:flutter/material.dart';
// import 'all_challenges_screen.dart';
import 'my_challenges_screen.dart';
import 'my_page_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    // const AllChallengesScreen(),
    const MyChallengesScreen(),
    const MyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 65,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: const Color(0xFF3182F6),
          unselectedItemColor: const Color(0xFF8B95A1),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.list_alt),
            //   label: '전체 챌린지',
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: '내 챌린지',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '마이페이지',
            ),
          ],
        ),
      ),
    );
  }
}

