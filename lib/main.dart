import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'providers/challenge_provider.dart';
// import 'providers/auth_provider.dart';
import 'providers/auth_provider_mock.dart'; // 임시 Mock Provider
// import 'screens/auth/login_screen.dart';
import 'screens/main/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 설정이 완료되면 아래 주석을 해제하세요
  /*
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
    print('Firebase 설정이 필요합니다. firebase_options.dart를 확인하세요.');
  }
  */
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProviderMock()), // Mock Provider 사용
            ChangeNotifierProvider(create: (_) => ChallengeProvider()..loadChallenges()),
          ],
          child: Consumer<AuthProviderMock>(
            builder: (context, authProvider, _) {
          return MaterialApp(
            title: '챌린지',
            theme: ThemeData(
          // 토스 블루 컬러
          primaryColor: const Color(0xFF3182F6),
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3182F6),
            secondary: Color(0xFF1B64DA),
            surface: Colors.white,
            error: Color(0xFFFF5247),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Color(0xFF191F28),
            onError: Colors.white,
          ),
          useMaterial3: true,
          // 토스 스타일 카드
          cardTheme: const CardThemeData(
            elevation: 0,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          // 토스 스타일 앱바
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(0xFFF9FAFB),
            foregroundColor: Color(0xFF191F28),
            titleTextStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191F28),
            ),
          ),
          // 토스 스타일 버튼
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF3182F6),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 토스 스타일 입력 필드
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E8EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E8EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3182F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          // 토스 스타일 플로팅 버튼
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF3182F6),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
            ),
              // Firebase 없이 테스트할 때는 바로 메인 화면으로
              home: const MainNavigation(),
              // Firebase 설정 후에는 아래 코드 사용:
              // home: authProvider.isAuthenticated
              //     ? const MainNavigation()
              //     : const LoginScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
