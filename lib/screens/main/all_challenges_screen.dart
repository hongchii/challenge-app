import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/challenge.dart';
import '../challenge_detail_screen.dart';
import '../create_challenge_screen.dart';

class AllChallengesScreen extends StatelessWidget {
  const AllChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 챌린지'),
      ),
      body: StreamBuilder<List<Challenge>>(
        stream: firestoreService.allChallenges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('오류가 발생했습니다: ${snapshot.error}'),
            );
          }

          final challenges = snapshot.data ?? [];

          if (challenges.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      size: 60,
                      color: Color(0xFF8B95A1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '아직 챌린지가 없어요',
                    style: TextStyle(
                      fontSize: 22,
                      color: Color(0xFF191F28),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '첫 챌린지를 만들어보세요!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8B95A1),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              // TODO: 나중에 비밀 챌린지 기능 추가
              // final isPrivate = challenge.isPrivate;
              final isPrivate = false; // 임시로 비공개 기능 비활성화
              final isFull = challenge.maxParticipants != null &&
                  challenge.participantIds.length >= challenge.maxParticipants!;

              return _ChallengeCard(
                challenge: challenge,
                isPrivate: isPrivate,
                isFull: isFull,
                currentUserId: authProvider.userModel?.id ?? '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChallengeDetailScreen(
                        challengeId: challenge.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateChallengeScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('새 챌린지'),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final bool isPrivate;
  final bool isFull;
  final String currentUserId;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.challenge,
    required this.isPrivate,
    required this.isFull,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysLeft = challenge.endDate?.difference(now).inDays;
    // 종료일이 없으면 시작일부터 경과한 일수 계산
    final daysPassed = now.difference(challenge.startDate).inDays;
    
    // 뱃지 텍스트와 색상 결정
    String badgeText;
    Color badgeBgColor;
    Color badgeTextColor;
    
    if (challenge.endDate != null && daysLeft != null && daysLeft <= 0) {
      // 종료됨
      badgeText = '종료';
      badgeBgColor = const Color(0xFFFFEBEE);
      badgeTextColor = const Color(0xFFFF5247);
    } else if (challenge.endDate == null) {
      // 종료일이 없으면 경과일수 표시 (파란색)
      badgeText = 'D+$daysPassed';
      badgeBgColor = const Color(0xFFE8F3FF);
      badgeTextColor = const Color(0xFF3182F6);
    } else if (daysLeft != null && daysLeft > 0) {
      badgeText = 'D-$daysLeft';
      badgeBgColor = const Color(0xFFE8F3FF);
      badgeTextColor = const Color(0xFF3182F6);
    } else {
      badgeText = '진행중';
      badgeBgColor = const Color(0xFFF2F4F6);
      badgeTextColor = const Color(0xFF4E5968);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E8EB), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isPrivate)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, size: 14, color: Color(0xFFFF5247)),
                          SizedBox(width: 4),
                          Text(
                            '비밀',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF5247),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isPrivate ? '비밀 챌린지입니다' : challenge.description,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4E5968),
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.people,
                    label: isFull 
                        ? '정원 마감'
                        : (challenge.maxParticipants != null
                            ? '${challenge.participantIds.length}/${challenge.maxParticipants}명'
                            : '${challenge.participantIds.length}명'),
                    color: isFull ? const Color(0xFFFF5247) : null,
                  ),
                  if (!isPrivate) ...[
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.payments,
                      label: '${challenge.penaltyAmount.toStringAsFixed(0)}원',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF4E5968);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

