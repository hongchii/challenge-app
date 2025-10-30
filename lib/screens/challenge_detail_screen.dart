import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/challenge_provider.dart';
import '../models/challenge.dart';
import 'add_member_screen.dart';
import 'add_verification_screen.dart';
import 'penalty_screen.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final String challengeId;

  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('챌린지 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            tooltip: '벌금 계산',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PenaltyScreen(challengeId: challengeId),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChallengeProvider>(
        builder: (context, provider, child) {
          final challenge = provider.getChallengeById(challengeId);

          if (challenge == null) {
            return const Center(
              child: Text('챌린지를 찾을 수 없습니다.'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChallengeHeader(challenge: challenge),
                const Divider(height: 1),
                _ChallengeInfo(challenge: challenge),
                const Divider(height: 1),
                _MembersSection(
                  challenge: challenge,
                  onAddMember: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMemberScreen(
                          challengeId: challengeId,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _VerificationsSection(challenge: challenge),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddVerificationScreen(
                challengeId: challengeId,
              ),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('인증하기'),
      ),
    );
  }
}

class _ChallengeHeader extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeHeader({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final daysLeft = challenge.endDate?.difference(DateTime.now()).inDays;
    final totalDays = challenge.endDate?.difference(challenge.startDate).inDays ?? 0;
    final progress = totalDays > 0 && daysLeft != null
        ? ((totalDays - daysLeft) / totalDays).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3182F6),
            Color(0xFF1B64DA),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challenge.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysLeft == null 
                        ? '진행중' 
                        : (daysLeft > 0 ? 'D-$daysLeft' : '종료'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.endDate == null
                          ? '기한 없음'
                          : '${(progress * 100).toStringAsFixed(0)}% 진행',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeInfo extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeInfo({required this.challenge});

  String _getFrequencyText() {
    switch (challenge.frequency) {
      case ChallengeFrequency.daily:
        return '매일';
      case ChallengeFrequency.weekly:
        return '주 ${challenge.frequencyCount}회';
      case ChallengeFrequency.monthly:
        return '월 ${challenge.frequencyCount}회';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 규칙',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.rules,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.repeat,
            label: '인증 빈도',
            value: _getFrequencyText(),
          ),
          _InfoRow(
            icon: Icons.calendar_today,
            label: '시작일',
            value: dateFormat.format(challenge.startDate),
          ),
          _InfoRow(
            icon: Icons.event,
            label: '종료일',
            value: challenge.endDate == null 
                ? '미정' 
                : dateFormat.format(challenge.endDate!),
          ),
          _InfoRow(
            icon: Icons.attach_money,
            label: '1회 실패당 벌금',
            value: '${challenge.penaltyAmount.toStringAsFixed(0)}원',
          ),
          _InfoRow(
            icon: Icons.more_horiz,
            label: '추가 벌금',
            value: challenge.penaltyType == PenaltyType.none
                ? '없음'
                : (challenge.penaltyType == PenaltyType.percentage
                    ? '이자율 ${challenge.penaltyValue.toStringAsFixed(1)}%'
                    : '+${challenge.penaltyValue.toStringAsFixed(0)}원'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8B95A1)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4E5968),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191F28),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onAddMember;

  const _MembersSection({
    required this.challenge,
    required this.onAddMember,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '👥 참가자 (${challenge.members.length}명)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: onAddMember,
                icon: const Icon(Icons.add),
                label: const Text('초대'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...challenge.members.map((member) {
            final verificationCount = challenge.getVerificationCount(member.id);
            final failedCount = challenge.getFailedCount(member.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E8EB)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: member.isLeader
                      ? const Color(0xFFFFD600)
                      : const Color(0xFFE8F3FF),
                  child: Icon(
                    member.isLeader ? Icons.star : Icons.person,
                    color: member.isLeader
                        ? Colors.white
                        : const Color(0xFF3182F6),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (member.isLeader) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '그룹장',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '인증 $verificationCount회 · 미달성 $failedCount회',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8B95A1),
                  ),
                ),
                trailing: failedCount > 0
                    ? const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800))
                    : const Icon(Icons.check_circle, color: Color(0xFF17C964)),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _VerificationsSection extends StatelessWidget {
  final Challenge challenge;

  const _VerificationsSection({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final verifications = [...challenge.verifications]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ 최근 인증 (${challenge.verifications.length}건)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (verifications.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '아직 인증 기록이 없습니다',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...verifications.take(10).map((verification) {
              final member = challenge.members
                  .firstWhere((m) => m.id == verification.memberId);
              final dateFormat = DateFormat('MM/dd HH:mm');

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E8EB)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Color(0xFF17C964)),
                  title: Text(
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    verification.note ?? '인증 완료',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    dateFormat.format(verification.dateTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B95A1),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

