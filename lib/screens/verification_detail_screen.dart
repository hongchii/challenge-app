import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/verification.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class VerificationDetailScreen extends StatelessWidget {
  final Verification verification;
  final String challengeId; // 챌린지 ID 추가

  const VerificationDetailScreen({
    super.key,
    required this.verification,
    required this.challengeId,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userModel?.id ?? '';
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final isMyVerification = verification.memberId == currentUserId;

    // 디버깅: imagePath 확인
    if (kDebugMode) {
      print('Verification imagePath: ${verification.imagePath}');
      print('Verification data: ${verification.toJson()}');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('인증 상세'),
        backgroundColor: const Color(0xFFF9FAFB),
        actions: [
          if (isMyVerification)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5247)),
              onPressed: () => _showDeleteDialog(context),
              tooltip: '삭제',
            ),
        ],
      ),
      body: FutureBuilder(
        future: firestoreService.getUser(verification.memberId),
        builder: (context, snapshot) {
          final userName = snapshot.data?.nickname ?? '사용자';

          return SingleChildScrollView(
            child: Column(
              children: [
                // 사용자 정보
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F3FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF3182F6),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF191F28),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateFormat.format(verification.dateTime),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8B95A1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 사진 (필수)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      verification.imagePath ?? '',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 300,
                          color: const Color(0xFFF2F4F6),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: const Color(0xFFF2F4F6),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Color(0xFF8B95A1),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '이미지를 불러올 수 없습니다',
                                  style: TextStyle(
                                    color: Color(0xFF8B95A1),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 메모
                if (verification.note != null && verification.note!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.note,
                              size: 20,
                              color: Color(0xFF4E5968),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '메모',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF191F28),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          verification.note!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF4E5968),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '인증 삭제',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('정말 이 인증을 삭제하시겠습니까?\n삭제된 인증은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B95A1),
            ),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF5247),
            ),
            child: const Text(
              '삭제',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final firestoreService = FirestoreService();
        await firestoreService.deleteVerification(challengeId, verification.id);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증이 삭제되었습니다'),
              backgroundColor: Color(0xFF17C964),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: $e'),
              backgroundColor: const Color(0xFFFF5247),
            ),
          );
        }
      }
    }
  }
}

