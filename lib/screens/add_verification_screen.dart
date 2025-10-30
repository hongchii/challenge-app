import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../providers/challenge_provider.dart';
import '../models/verification.dart';

class AddVerificationScreen extends StatefulWidget {
  final String challengeId;

  const AddVerificationScreen({
    super.key,
    required this.challengeId,
  });

  @override
  State<AddVerificationScreen> createState() => _AddVerificationScreenState();
}

class _AddVerificationScreenState extends State<AddVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _selectedMemberId;
  String? _imagePath;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지를 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitVerification() {
    if (_formKey.currentState!.validate()) {
      if (_selectedMemberId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('참가자를 선택해주세요'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      
      // 오늘 이미 인증했는지 확인
      if (provider.hasVerifiedToday(widget.challengeId, _selectedMemberId!)) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('알림'),
            content: const Text('오늘 이미 인증을 완료하셨습니다.\n그래도 인증하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveVerification();
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      } else {
        _saveVerification();
      }
    }
  }

  void _saveVerification() {
    final uuid = const Uuid();
    final verification = Verification(
      id: uuid.v4(),
      memberId: _selectedMemberId!,
      dateTime: DateTime.now(),
      imagePath: _imagePath,
      note: _noteController.text.trim().isEmpty 
          ? null 
          : _noteController.text.trim(),
    );

    Provider.of<ChallengeProvider>(context, listen: false)
        .addVerification(widget.challengeId, verification);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('인증이 완료되었습니다!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인증하기'),
      ),
      body: Consumer<ChallengeProvider>(
        builder: (context, provider, child) {
          final challenge = provider.getChallengeById(widget.challengeId);

          if (challenge == null) {
            return const Center(
              child: Text('챌린지를 찾을 수 없습니다.'),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '📸 인증 사진',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[400]!,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _imagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 60,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '사진 추가하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(_imagePath!),
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _imagePath = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '👤 인증할 사람',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMemberId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    hintText: '참가자 선택',
                  ),
                  items: challenge.members.map((member) {
                    return DropdownMenuItem(
                      value: member.id,
                      child: Row(
                        children: [
                          Text(member.name),
                          if (member.isLeader) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '그룹장',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMemberId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return '참가자를 선택해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  '📝 메모 (선택사항)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '인증에 대한 메모를 남겨보세요',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitVerification,
                  child: const Text('인증 완료'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

