import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/challenge.dart';
import '../models/verification.dart';
import 'add_member_screen.dart';
import 'add_verification_screen.dart';
import 'verification_detail_screen.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final String challengeId;

  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
  });

  Future<void> _deleteChallenge(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '챌린지 삭제',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('정말 이 챌린지를 삭제하시겠습니까?\n삭제된 챌린지는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B95A1),
            ),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
        await firestoreService.deleteChallenge(challengeId);
        
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('챌린지가 삭제되었습니다'),
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

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userModel?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('챌린지 상세'),
        backgroundColor: const Color(0xFFF9FAFB),
      ),
      body: StreamBuilder<Challenge?>(
        stream: firestoreService.challengeStream(challengeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('오류가 발생했습니다: ${snapshot.error}'),
            );
          }

          final challenge = snapshot.data;

          if (challenge == null) {
            return const Center(
              child: Text('챌린지를 찾을 수 없습니다.'),
            );
          }

          final isCreator = challenge.creatorId == currentUserId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChallengeHeader(challenge: challenge),
                const SizedBox(height: 16),
                _ChallengeInfo(challenge: challenge),
                const SizedBox(height: 16),
                _MembersSection(
                  challenge: challenge,
                  onAddMember: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMemberScreen(
                          challengeId: challengeId,
                          challengeTitle: challenge.title,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _VerificationsSection(challenge: challenge),
                
                // 그룹장일 경우 삭제 버튼
                if (isCreator) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteChallenge(context),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('챌린지 삭제'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5247),
                          side: const BorderSide(color: Color(0xFFFF5247)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 100), // 하단 여백
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3182F6), Color(0xFF1B64DA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3182F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
          const SizedBox(height: 20),
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
    final dateFormat = DateFormat('yyyy.MM.dd');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 규칙',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191F28),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            challenge.rules,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4E5968),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          // 첫 번째 줄: 인증 빈도, 1회 실패당 벌금
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.repeat,
                  label: '인증 빈도',
                  value: _getFrequencyText(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoRow(
                  icon: Icons.payments,
                  label: '1회 실패당 벌금',
                  value: '${challenge.penaltyAmount.toStringAsFixed(0)}원',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 두 번째 줄: 시작일, 종료일
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.calendar_today,
                  label: '시작일',
                  value: dateFormat.format(challenge.startDate),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoRow(
                  icon: Icons.event,
                  label: '종료일',
                  value: challenge.endDate == null 
                      ? '미정' 
                      : dateFormat.format(challenge.endDate!),
                ),
              ),
            ],
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF4E5968)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191F28),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
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
                  color: Color(0xFF191F28),
                ),
              ),
              TextButton.icon(
                onPressed: onAddMember,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('초대'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3182F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...challenge.members.map((member) => _MemberItem(
            memberId: member.id,
            isLeader: member.isLeader,
            displayName: member.name, // ID가 아닌 실제 닉네임
          )),
        ],
      ),
    );
  }
}

class _MemberItem extends StatelessWidget {
  final String memberId;
  final bool isLeader;
  final String displayName;

  const _MemberItem({
    required this.memberId,
    required this.isLeader,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    // displayName이 이미 닉네임으로 설정되어 있음 (challengeStream에서 처리)
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8F3FF),
            child: const Icon(
              Icons.person,
              color: Color(0xFF3182F6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF191F28),
                      ),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3182F6),
                          borderRadius: BorderRadius.circular(4),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationsSection extends StatefulWidget {
  final Challenge challenge;

  const _VerificationsSection({required this.challenge});

  @override
  State<_VerificationsSection> createState() => _VerificationsSectionState();
}

class _VerificationsSectionState extends State<_VerificationsSection> {
  int _displayCount = 10;
  static const int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final verifications = [...widget.challenge.verifications]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final displayedVerifications = verifications.take(_displayCount).toList();
    final hasMore = verifications.length > _displayCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ 인증 내역 (${widget.challenge.verifications.length}건)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191F28),
            ),
          ),
          const SizedBox(height: 16),
          if (verifications.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '아직 인증 기록이 없습니다',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ...displayedVerifications.map((verification) {
                  return _VerificationItem(
                    verification: verification,
                    challengeId: widget.challenge.id,
                  );
                }),
                if (hasMore)
                  const SizedBox(height: 12),
                if (hasMore)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _displayCount += _itemsPerPage;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3182F6),
                        side: const BorderSide(color: Color(0xFF3182F6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '더 보기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _VerificationItem extends StatelessWidget {
  final dynamic verification;
  final String challengeId;

  const _VerificationItem({
    required this.verification,
    required this.challengeId,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final dateFormat = DateFormat('MM/dd HH:mm');

    return FutureBuilder(
      future: firestoreService.getUser(verification.memberId),
      builder: (context, snapshot) {
        final userName = snapshot.data?.nickname ?? '사용자';
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // verification이 Verification 객체가 아니라 Map일 수 있으므로 변환
              final Verification? verificationObj = verification is Verification
                  ? verification
                  : Verification.fromJson(verification);
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerificationDetailScreen(
                    verification: verificationObj!,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle, 
                    color: Color(0xFF17C964),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF191F28),
                          ),
                        ),
                        if (verification.note != null && verification.note!.isNotEmpty)
                          Text(
                            verification.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4E5968),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    dateFormat.format(verification.dateTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B95A1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
