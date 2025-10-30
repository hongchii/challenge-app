import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _passwordController;
  final _imagePicker = ImagePicker();
  final _storageService = StorageService();
  
  File? _newProfileImage;
  bool _isUpdating = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nicknameController = TextEditingController(
      text: authProvider.userModel?.nickname ?? '',
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
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
          _newProfileImage = File(image.path);
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.userModel;
      
      if (currentUser == null) return;

      String? newProfileImageUrl = currentUser.profileImageUrl;

      // 새 프로필 이미지가 있으면 업로드
      if (_newProfileImage != null) {
        newProfileImageUrl = await _storageService.uploadProfileImage(
          _newProfileImage!,
          currentUser.id,
        );
      }

      // 프로필 업데이트
      final updatedUser = currentUser.copyWith(
        nickname: _nicknameController.text.trim(),
        profileImageUrl: newProfileImageUrl,
      );

      await authProvider.updateProfile(updatedUser);

      // 비밀번호 변경이 요청된 경우
      if (_isChangingPassword && _passwordController.text.isNotEmpty) {
        await authProvider.updatePassword(_passwordController.text);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 업데이트되었습니다!'),
            backgroundColor: Color(0xFF17C964),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업데이트 실패: $e'),
            backgroundColor: const Color(0xFFFF5247),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 프로필 이미지
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFE8F3FF),
                    backgroundImage: _newProfileImage != null
                        ? FileImage(_newProfileImage!)
                        : (user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : null) as ImageProvider?,
                    child: _newProfileImage == null && user.profileImageUrl == null
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
            const SizedBox(height: 32),

            // 이메일 (읽기 전용)
            TextFormField(
              initialValue: user.email,
              decoration: const InputDecoration(
                labelText: '이메일',
                prefixIcon: Icon(Icons.email_outlined),
                enabled: false,
              ),
            ),
            const SizedBox(height: 16),

            // 닉네임
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
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
            const SizedBox(height: 24),

            // 비밀번호 변경 섹션
            CheckboxListTile(
              value: _isChangingPassword,
              onChanged: (value) {
                setState(() {
                  _isChangingPassword = value ?? false;
                  if (!_isChangingPassword) {
                    _passwordController.clear();
                  }
                });
              },
              title: const Text('비밀번호 변경'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF3182F6),
            ),

            if (_isChangingPassword) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호',
                  hintText: '6자 이상',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                obscureText: true,
                validator: (value) {
                  if (_isChangingPassword) {
                    if (value == null || value.isEmpty) {
                      return '새 비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다';
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 32),

            // 저장 버튼
            ElevatedButton(
              onPressed: _isUpdating ? null : _updateProfile,
              child: _isUpdating
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
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}

