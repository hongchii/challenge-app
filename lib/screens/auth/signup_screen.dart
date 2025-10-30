import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _storageService = StorageService();
  
  File? _profileImage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isUploading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지를 불러오는데 실패했습니다: $e'),
            backgroundColor: const Color(0xFFFF5247),
          ),
        );
      }
    }
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);

      try {
        String? profileImageUrl;

        // 프로필 이미지가 있으면 업로드
        if (_profileImage != null) {
          final tempUserId = DateTime.now().millisecondsSinceEpoch.toString();
          profileImageUrl = await _storageService.uploadProfileImage(
            _profileImage!,
            tempUserId,
          );
        }

        setState(() => _isUploading = false);

        if (!mounted) return;

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        final success = await authProvider.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nickname: _nicknameController.text.trim(),
          profileImageUrl: profileImageUrl,
        );

        if (success && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원가입이 완료되었습니다!'),
              backgroundColor: Color(0xFF17C964),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? '회원가입에 실패했습니다.'),
              backgroundColor: const Color(0xFFFF5247),
            ),
          );
        }
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류가 발생했습니다: $e'),
              backgroundColor: const Color(0xFFFF5247),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final isLoading = authProvider.isLoading || _isUploading;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 프로필 이미지
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xFFE8F3FF),
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFF3182F6),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF3182F6),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '프로필 사진 (선택사항)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8B95A1),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // 닉네임
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '닉네임 *',
                        hintText: '챌린지에서 사용할 이름',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력해주세요';
                        }
                        if (value.length < 2) {
                          return '닉네임은 2자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 이메일
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: '이메일 *',
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
                        labelText: '비밀번호 *',
                        hintText: '6자 이상',
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
                        if (value.length < 6) {
                          return '비밀번호는 6자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 비밀번호 확인
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: '비밀번호 확인 *',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 다시 입력해주세요';
                        }
                        if (value != _passwordController.text) {
                          return '비밀번호가 일치하지 않습니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // 회원가입 버튼
                    ElevatedButton(
                      onPressed: isLoading ? null : _signUp,
                      child: isLoading
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
                          : const Text('회원가입'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

