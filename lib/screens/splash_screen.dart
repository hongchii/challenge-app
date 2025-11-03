import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'main/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // 스플래시 화면을 최소 1.5초간 표시
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // 로그인 상태 확인
    await authProvider.checkAuthState();
    
    if (!mounted) return;
    
    // 로그인 상태에 따라 화면 전환
    final nextScreen = authProvider.isAuthenticated
        ? const MainNavigation()
        : const LoginScreen();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 트로피 아이콘
            const Icon(
              Icons.emoji_events,
              size: 120,
              color: Color(0xFF3182F6),
            ),
            const SizedBox(height: 24),
            // 로딩 인디케이터
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF3182F6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

