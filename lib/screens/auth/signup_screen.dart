import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';

class SignUpScreen extends StatefulWidget {
  final String? initialEmail;
  
  const SignUpScreen({
    super.key,
    this.initialEmail,
  });

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
  final _firestoreService = FirestoreService();
  
  File? _profileImage;
  Uint8List? _webImage; // Web용 이미지 데이터
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

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
        if (kIsWeb) {
          // Web: bytes로 읽기
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
          });
        } else {
          // Mobile/Desktop: File로 읽기
          setState(() {
            _profileImage = File(image.path);
          });
        }
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
        // 이메일 중복 체크
        final emailExists = await _firestoreService.isEmailExists(_emailController.text.trim());
        if (emailExists) {
          setState(() => _isUploading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이미 사용 중인 이메일입니다.'),
                backgroundColor: Color(0xFFFF5247),
              ),
            );
          }
          return;
        }

        // 닉네임 중복 체크
        final nicknameExists = await _firestoreService.isNicknameExists(_nicknameController.text.trim());
        if (nicknameExists) {
          setState(() => _isUploading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이미 사용 중인 닉네임입니다.'),
                backgroundColor: Color(0xFFFF5247),
              ),
            );
          }
          return;
        }

        String? profileImageUrl;

        // 프로필 이미지가 있으면 업로드
        if (_profileImage != null || _webImage != null) {
          final tempUserId = DateTime.now().millisecondsSinceEpoch.toString();
          if (kIsWeb) {
            // Web에서는 bytes로 업로드
            profileImageUrl = await _storageService.uploadProfileImageBytes(
              _webImage!,
              tempUserId,
            );
          } else {
            // Mobile/Desktop에서는 File로 업로드
            profileImageUrl = await _storageService.uploadProfileImage(
              _profileImage!,
              tempUserId,
            );
          }
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
          final authError = authProvider.error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authError ?? '회원가입에 실패했습니다.'),
              backgroundColor: const Color(0xFFFF5247),
            ),
          );
        }
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('회원가입 중 오류가 발생했습니다: $e'),
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: const Color(0xFFF9FAFB),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 프로필 이미지 선택
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xFFE8F3FF),
                              backgroundImage: kIsWeb
                                  ? (_webImage != null ? MemoryImage(_webImage!) : null)
                                  : (_profileImage != null ? FileImage(_profileImage!) : null),
                              child: (_webImage == null && _profileImage == null)
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
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3182F6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        '프로필 사진 (선택)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B95A1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
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
                    
                    // 닉네임
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '닉네임',
                        hintText: '사용할 닉네임을 입력하세요',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력해주세요';
                        }
                        if (value.length < 2) {
                          return '닉네임은 2자 이상이어야 합니다';
                        }
                        if (value.length > 10) {
                          return '닉네임은 10자 이하여야 합니다';
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
                        labelText: '비밀번호 확인',
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
                          return '비밀번호 확인을 입력해주세요';
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
                      onPressed: _isUploading ? null : _signUp,
                      child: _isUploading
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
                  ],
                ),
              ),
            ),
            if (_isUploading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
