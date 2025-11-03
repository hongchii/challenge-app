import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'signup_screen.dart';
import '../main/main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        // 로그인 성공 시 메인 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigation(),
          ),
        );
        return;
      }

      if (!success && mounted) {
        final errorMessage = authProvider.error ?? '';
        
        // invalid-credential 에러 (최신 Firebase에서 wrong-password/user-not-found 대체)
        if (errorMessage.contains('invalid-credential') ||
            errorMessage.contains('incorrect') ||
            errorMessage.contains('malformed') ||
            errorMessage.contains('expired') ||
            errorMessage.contains('credential')) {
          // 보안상 이유로 구체적인 정보를 제공하지 않으므로 일반적인 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이메일 또는 비밀번호가 올바르지 않습니다.'),
              backgroundColor: Color(0xFFFF5247),
            ),
          );
        }
        // 잘못된 비밀번호인 경우 (구버전 Firebase)
        else if (errorMessage.contains('wrong-password') || 
            errorMessage.contains('잘못된 비밀번호입니다')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('잘못된 비밀번호입니다.'),
              backgroundColor: Color(0xFFFF5247),
            ),
          );
        }
        // 가입되지 않은 이메일인 경우 (구버전 Firebase)
        else if (errorMessage.contains('user-not-found') || 
            errorMessage.contains('no user record') ||
            errorMessage.contains('There is no user') ||
            errorMessage.contains('사용자를 찾을 수 없습니다')) {
          _showSignupDialog();
        } 
        // 기타 오류 - 에러 코드 제거하고 메시지만 표시
        else {
          // 에러 메시지에서 [코드] 부분 제거
          String displayMessage = errorMessage;
          if (displayMessage.startsWith('[') && displayMessage.contains(']')) {
            final endIndex = displayMessage.indexOf(']');
            if (endIndex != -1 && endIndex < displayMessage.length - 1) {
              displayMessage = displayMessage.substring(endIndex + 1).trim();
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMessage.isEmpty ? '로그인에 실패했습니다.' : displayMessage),
              backgroundColor: const Color(0xFFFF5247),
            ),
          );
        }
      }
    }
  }

  void _showSignupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '가입되지 않은 이메일',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('아직 가입하지 않은 이메일입니다.\n회원가입을 진행하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B95A1),
            ),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SignUpScreen(
                    initialEmail: _emailController.text.trim(),
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3182F6),
            ),
            child: const Text(
              '회원가입',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 60),
                        // 로고/타이틀
                        const Icon(
                          Icons.emoji_events,
                          size: 80,
                          color: Color(0xFF3182F6),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '챌린지',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191F28),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '친구들과 함께하는 챌린지',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B95A1),
                          ),
                        ),
                        const SizedBox(height: 60),
                        
                        // 이메일
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: '이메일',
                            hintText: 'example@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '이메일을 입력해주세요';
                            }
                            if (!value.contains('@')) {
                              return '올바른 이메일 형식이 아닙니다';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // 비밀번호
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: '비밀번호',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword 
                                    ? Icons.visibility_outlined 
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // 로그인 버튼
                        ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _login,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('로그인'),
                        ),
                        const SizedBox(height: 16),
                        
                        // 회원가입 버튼
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: Color(0xFF3182F6),
                            ),
                          ),
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3182F6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

