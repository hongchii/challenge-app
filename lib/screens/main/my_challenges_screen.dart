import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import '../../providers/auth_provider.dart';
import '../../providers/auth_provider_mock.dart';
// import '../../services/firestore_service.dart';
import '../../models/challenge.dart';
import '../challenge_detail_screen.dart';

class MyChallengesScreen extends StatelessWidget {
  const MyChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMock>(context);
    final userId = authProvider.userModel?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다')),
      );
    }

    // Firebase 없이 테스트할 때는 빈 리스트 사용
    final challenges = <Challenge>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 챌린지'),
      ),
      body: Builder(
        builder: (context) {
          // Firebase 설정 후에는 StreamBuilder 사용
          // final firestoreService = FirestoreService();
          // stream: firestoreService.myChallenges(userId),

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
                    '참여 중인 챌린지가 없어요',
                    style: TextStyle(
                      fontSize: 22,
                      color: Color(0xFF191F28),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '챌린지에 참여해보세요!',
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
              
              return _ChallengeCard(
                challenge: challenge,
                userId: userId,
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
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final String userId;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.challenge,
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final daysLeft = challenge.endDate?.difference(DateTime.now()).inDays;
    final isCreator = challenge.creatorId == userId;

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
                  if (isCreator)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECB3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Color(0xFFFFD600)),
                          SizedBox(width: 4),
                          Text(
                            '그룹장',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF8F00),
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
                      color: daysLeft == null
                          ? const Color(0xFFF2F4F6)
                          : (daysLeft > 0
                              ? const Color(0xFFE8F3FF)
                              : const Color(0xFFFFEBEE)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      daysLeft == null 
                          ? '진행중' 
                          : (daysLeft > 0 ? 'D-$daysLeft' : '종료'),
                      style: TextStyle(
                        color: daysLeft == null
                            ? const Color(0xFF4E5968)
                            : (daysLeft > 0 
                                ? const Color(0xFF3182F6)
                                : const Color(0xFFFF5247)),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                challenge.description,
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
                    label: '${challenge.participantIds.length}명',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.attach_money,
                    label: '${challenge.penaltyAmount.toStringAsFixed(0)}원',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Color(0xFF8B95A1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    challenge.endDate == null
                        ? '${dateFormat.format(challenge.startDate)} ~ 미정'
                        : '${dateFormat.format(challenge.startDate)} ~ ${dateFormat.format(challenge.endDate!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8B95A1),
                    ),
                  ),
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

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
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
            color: const Color(0xFF4E5968),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4E5968),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

