import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/verification.dart';
import '../utils/text_encoding.dart';
import '../utils/image_timestamp.dart';

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
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();

  File? _selectedImage;
  Uint8List? _webImage; // Web용 이미지 데이터
  bool _isUploading = false;

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
        if (kIsWeb) {
          // Web: bytes로 읽기
          var bytes = await image.readAsBytes();
          
          // 카메라로 촬영한 경우에만 타임스탬프 추가 (중앙에 표시)
          if (source == ImageSource.camera) {
            debugPrint('📸 카메라로 촬영 - 타임스탬프 추가 시작 (중앙)');
            try {
              bytes = await ImageTimestamp.addTimestamp(
                bytes,
                position: 'center',
              );
              debugPrint('✅ 타임스탬프 추가 완료');
            } catch (e) {
              debugPrint('❌ 타임스탬프 추가 실패: $e');
              // 오류가 발생해도 계속 진행
            }
          }
          
          setState(() {
            _webImage = bytes;
          });
        } else {
          // Mobile/Desktop: File로 읽기
          File imageFile = File(image.path);
          
          // 카메라로 촬영한 경우에만 타임스탬프 추가 (중앙에 표시)
          if (source == ImageSource.camera) {
            imageFile = await ImageTimestamp.addTimestampToFile(
              imageFile,
              position: 'center',
            );
          }
          
          setState(() {
            _selectedImage = imageFile;
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF3182F6)),
                ),
                title: const Text(
                  '카메라로 촬영',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  '📅 날짜/시간이 자동으로 추가됩니다',
                  style: TextStyle(fontSize: 12, color: Color(0xFF3182F6)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF3182F6)),
                ),
                title: const Text(
                  '갤러리에서 선택',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  '기존 사진 선택 (타임스탬프 없음)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8B95A1)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitVerification() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null && _webImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증 사진을 선택해주세요'),
            backgroundColor: Color(0xFFFF5247),
          ),
        );
        return;
      }

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.userModel?.id;

        if (currentUserId == null) {
          throw Exception('로그인이 필요합니다');
        }

        // 하루에 한번만 인증 가능한지 확인
        final challenge = await _firestoreService.getChallenge(widget.challengeId);
        if (challenge != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          final hasVerifiedToday = challenge.verifications.any((v) {
            final verificationDate = DateTime(
              v.dateTime.year,
              v.dateTime.month,
              v.dateTime.day,
            );
            return v.memberId == currentUserId && verificationDate == today;
          });

          if (hasVerifiedToday) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('인증은 하루에 한번만 가능합니다'),
                backgroundColor: Color(0xFFFF5247),
              ),
            );
            return;
          }
        }

        setState(() => _isUploading = true);

        // 이미지 업로드
        String imageUrl;
        if (kIsWeb) {
          // Web에서는 bytes로 업로드
          imageUrl = await _storageService.uploadVerificationImageBytes(
            _webImage!,
            widget.challengeId,
            currentUserId,
          );
        } else {
          // Mobile/Desktop에서는 File로 업로드
          imageUrl = await _storageService.uploadVerificationImage(
            _selectedImage!,
            widget.challengeId,
            currentUserId,
          );
        }

        // 인증 기록 생성
        final uuid = const Uuid();
        final normalizedNote = TextEncoding.normalizeInput(_noteController.text);
        final verification = Verification(
          id: uuid.v4(),
          memberId: currentUserId,
          dateTime: DateTime.now(),
          imagePath: imageUrl, // Firebase Storage URL 저장
          note: normalizedNote.isEmpty ? null : normalizedNote,
        );

        // Firestore에 인증 추가
        await _firestoreService.addVerification(widget.challengeId, verification);

        setState(() => _isUploading = false);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증이 완료되었습니다!'),
              backgroundColor: Color(0xFF17C964),
            ),
          );
        }
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('인증 실패: $e'),
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
        title: const Text('인증하기'),
        backgroundColor: const Color(0xFFF9FAFB),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  '📸 인증 사진',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191F28),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '챌린지 완료 사진을 업로드해주세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8B95A1),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE5E8EB),
                        width: 2,
                      ),
                    ),
                    child: (_selectedImage == null && _webImage == null)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F4F6),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  size: 60,
                                  color: Color(0xFF8B95A1),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '사진 추가하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4E5968),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '카메라 또는 갤러리에서 선택',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                kIsWeb
                                    ? Image.memory(
                                        _webImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Material(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedImage = null;
                                          _webImage = null;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '📝 메모 (선택)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191F28),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: '인증에 대한 메모를 남겨보세요',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: const TextStyle(fontSize: 16),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isUploading ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('인증 완료'),
                ),
                const SizedBox(height: 80),
              ],
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
    );
  }
}

