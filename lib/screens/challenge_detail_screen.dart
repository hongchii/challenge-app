import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/challenge.dart';
import '../models/verification.dart';
import 'add_member_screen.dart';
import 'add_verification_screen.dart';
import 'verification_detail_screen.dart';
import 'verification_history_screen.dart';
import 'edit_challenge_screen.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final String challengeId;

  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
  });

  Future<void> _deleteChallenge(BuildContext context, Challenge challenge) async {
    debugPrint('_deleteChallenge 함수 시작');
    if (!context.mounted) {
      debugPrint('context가 mounted되지 않음');
      return;
    }
    
    debugPrint('다이얼로그 표시 시작');
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
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

    debugPrint('다이얼로그 결과: $confirmed');
    if (confirmed != true || !context.mounted) {
      debugPrint('확인되지 않았거나 context가 유효하지 않음');
      return;
    }

    try {
      debugPrint('챌린지 삭제 시작: $challengeId');
      final firestoreService = FirestoreService();
      await firestoreService.deleteChallenge(challengeId);
      debugPrint('챌린지 삭제 완료: $challengeId');
      
      if (context.mounted) {
        Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('챌린지가 삭제되었습니다'),
              backgroundColor: Color(0xFF17C964),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('챌린지 삭제 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: const Color(0xFFFF5247),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _endChallenge(BuildContext context, Challenge challenge) async {
    debugPrint('_endChallenge 함수 시작');
    if (!context.mounted) {
      debugPrint('context가 mounted되지 않음');
      return;
    }
    
    debugPrint('다이얼로그 표시 시작');
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '챌린지 종료',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('이 챌린지를 종료하시겠습니까?\n종료된 챌린지는 더 이상 진행할 수 없습니다.'),
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
              foregroundColor: const Color(0xFF3182F6),
            ),
            child: const Text(
              '종료',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    debugPrint('다이얼로그 결과: $confirmed');
    if (confirmed != true || !context.mounted) {
      debugPrint('확인되지 않았거나 context가 유효하지 않음');
      return;
    }

    try {
      debugPrint('챌린지 종료 시작: ${challenge.id}');
      final firestoreService = FirestoreService();
      final now = DateTime.now();
      debugPrint('종료 시간 설정: $now');
      // 종료 시간을 현재 시간으로 설정
      final endedChallenge = challenge.copyWith(endDate: now);
      debugPrint('업데이트할 챌린지 endDate: ${endedChallenge.endDate}');
      await firestoreService.updateChallenge(endedChallenge);
      debugPrint('챌린지 종료 완료: ${challenge.id}');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('챌린지가 종료되었습니다'),
            backgroundColor: Color(0xFF17C964),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('챌린지 종료 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('종료 실패: $e'),
            backgroundColor: const Color(0xFFFF5247),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _requestJoinChallenge(BuildContext context, Challenge challenge, String userId) async {
    debugPrint('_requestJoinChallenge 함수 시작');
    if (!context.mounted) {
      return;
    }

    // 이미 참가 신청 중인지 확인
    if (challenge.pendingParticipantIds.contains(userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미 참가 신청이 완료되었습니다'),
          backgroundColor: Color(0xFFFF5247),
        ),
      );
      return;
    }

    // 이미 참가자인지 확인
    if (challenge.participantIds.contains(userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미 참가 중인 챌린지입니다'),
          backgroundColor: Color(0xFFFF5247),
        ),
      );
      return;
    }

    try {
      final firestoreService = FirestoreService();
      
      // 모든 챌린지는 참가 신청만 가능 (그룹장 승인 필요)
      await firestoreService.requestJoinChallenge(challenge.id, userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('참가 신청이 완료되었습니다. 그룹장의 승인을 기다려주세요'),
            backgroundColor: Color(0xFF3182F6),
          ),
        );
      }
    } catch (e) {
      debugPrint('참가 신청 오류: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('참가 신청 실패: $e'),
            backgroundColor: const Color(0xFFFF5247),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _leaveChallenge(BuildContext context, Challenge challenge, String userId) async {
    debugPrint('_leaveChallenge 함수 시작');
    if (!context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '챌린지 나가기',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('정말 이 챌린지를 나가시겠습니까?\n나가면 다시 참가할 수 없습니다.'),
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
              '나가기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      final firestoreService = FirestoreService();
      await firestoreService.leaveChallenge(challenge.id, userId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('챌린지에서 나갔습니다'),
            backgroundColor: Color(0xFF17C964),
          ),
        );
        // 상세 화면을 닫고 이전 화면으로 이동
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('챌린지 나가기 오류: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('나가기 실패: $e'),
            backgroundColor: const Color(0xFFFF5247),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showSettingsMenu(BuildContext context, Challenge challenge, bool isCreator, bool isMember) {
    debugPrint('_showSettingsMenu 호출됨, challenge.id: ${challenge.id}');
    final parentContext = context; // 원래 context 저장
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.id ?? '';
    
    // 메뉴 아이템 리스트 구성
    final List<Widget> menuItems = [];
    
    // 그룹장인 경우: 수정, 종료, 삭제
    if (isCreator) {
      menuItems.addAll([
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: const Icon(Icons.edit, color: Color(0xFF3182F6), size: 24),
          title: const Text(
            '챌린지 수정',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              parentContext,
              MaterialPageRoute(
                builder: (context) => EditChallengeScreen(
                  challenge: challenge,
                ),
              ),
            );
          },
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: const Icon(Icons.stop_circle, color: Color(0xFF3182F6), size: 24),
          title: const Text(
            '챌린지 종료',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          onTap: () {
            debugPrint('종료 버튼 클릭됨');
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (parentContext.mounted) {
                debugPrint('종료 함수 호출 시작');
                _endChallenge(parentContext, challenge);
              } else {
                debugPrint('parentContext가 mounted되지 않음');
              }
            });
          },
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: const Icon(Icons.delete_outline, color: Color(0xFFFF5247), size: 24),
          title: const Text(
            '챌린지 삭제',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFF5247),
            ),
          ),
          onTap: () {
            debugPrint('삭제 버튼 클릭됨');
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (parentContext.mounted) {
                debugPrint('삭제 함수 호출 시작');
                _deleteChallenge(parentContext, challenge);
              } else {
                debugPrint('parentContext가 mounted되지 않음');
              }
            });
          },
        ),
      ]);
    }
    // 참가자가 아닌 경우: 참가 신청
    else if (!isMember) {
      menuItems.add(
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: const Icon(Icons.person_add, color: Color(0xFF3182F6), size: 24),
          title: const Text(
            '참가 신청',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          onTap: () {
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (parentContext.mounted) {
                _requestJoinChallenge(parentContext, challenge, currentUserId);
              }
            });
          },
        ),
      );
    }
    // 단순 참가자인 경우: 챌린지 나가기
    else {
      menuItems.add(
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: const Icon(Icons.exit_to_app, color: Color(0xFFFF5247), size: 24),
          title: const Text(
            '챌린지 나가기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFF5247),
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (parentContext.mounted) {
                _leaveChallenge(parentContext, challenge, currentUserId);
              }
            });
          },
        ),
      );
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...menuItems,
            SizedBox(
              height: MediaQuery.of(bottomSheetContext).padding.bottom,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userModel?.id ?? '';

    return StreamBuilder<Challenge?>(
      stream: firestoreService.challengeStream(challengeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              title: const Text('챌린지 상세'),
              backgroundColor: const Color(0xFFF9FAFB),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              title: const Text('챌린지 상세'),
              backgroundColor: const Color(0xFFF9FAFB),
            ),
            body: Center(
              child: Text('오류가 발생했습니다: ${snapshot.error}'),
            ),
          );
        }

        final challenge = snapshot.data;

        if (challenge == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              title: const Text('챌린지 상세'),
              backgroundColor: const Color(0xFFF9FAFB),
            ),
            body: const Center(
              child: Text('챌린지를 찾을 수 없습니다.'),
            ),
          );
        }

        final isCreator = challenge.creatorId == currentUserId;
        final isMember = challenge.participantIds.contains(currentUserId);
        // 챌린지가 종료되었는지 확인 (endDate가 현재보다 과거이거나 같으면 종료)
        final now = DateTime.now();
        final isEnded = challenge.endDate != null && 
            !challenge.endDate!.isAfter(now); // endDate가 현재보다 미래가 아니면 종료

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            title: const Text('챌린지 상세'),
            backgroundColor: const Color(0xFFF9FAFB),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  debugPrint('설정 메뉴 버튼 클릭됨');
                  _showSettingsMenu(context, challenge, isCreator, isMember);
                },
                tooltip: '더보기',
              ),
            ],
          ),

          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChallengeHeader(challenge: challenge, isEnded: isEnded),
                const SizedBox(height: 16),
                _ChallengeInfo(challenge: challenge),
                const SizedBox(height: 16),
                _MembersSection(
                  challenge: challenge,
                  isCreator: isCreator,
                  isMember: isMember && !isEnded,
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
                _VerificationsSection(
                  challenge: challenge,
                  isMember: isMember,
                ),
                
                const SizedBox(height: 100), // 하단 여백
              ],
            ),
          ),
          floatingActionButton: (isMember && !isEnded)
              ? FloatingActionButton.extended(
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
                )
              : null,
        );
      },
    );
  }
}

class _ChallengeHeader extends StatelessWidget {
  final Challenge challenge;
  final bool isEnded;

  const _ChallengeHeader({
    required this.challenge,
    required this.isEnded,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysLeft = challenge.endDate?.difference(now).inDays;
    // 종료일이 없으면 시작일부터 경과한 일수 계산
    final daysPassed = now.difference(challenge.startDate).inDays;
    
    final totalDays = challenge.endDate?.difference(challenge.startDate).inDays ?? 0;
    final progress = totalDays > 0 && daysLeft != null && !isEnded
        ? ((totalDays - daysLeft) / totalDays).clamp(0.0, 1.0)
        : (isEnded ? 1.0 : 0.0);

    // 뱃지 텍스트와 색상 결정
    String badgeText;
    Color badgeColor;
    if (isEnded) {
      badgeText = '종료';
      badgeColor = Colors.white;
    } else if (challenge.endDate == null) {
      // 종료일이 없으면 경과일수 표시 (파란색)
      badgeText = 'D+$daysPassed';
      badgeColor = Colors.white;
    } else if (daysLeft != null && daysLeft > 0) {
      badgeText = 'D-$daysLeft';
      badgeColor = Colors.white;
    } else {
      badgeText = '종료';
      badgeColor = Colors.white;
    }

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
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
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
                      isEnded
                          ? '종료됨'
                          : (challenge.endDate == null
                              ? '기한 없음'
                              : '${(progress * 100).toStringAsFixed(0)}% 진행'),
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

class _ChallengeInfo extends StatefulWidget {
  final Challenge challenge;

  const _ChallengeInfo({required this.challenge});

  @override
  State<_ChallengeInfo> createState() => _ChallengeInfoState();
}

class _ChallengeInfoState extends State<_ChallengeInfo> {
  bool _isRulesExpanded = false;

  String _getFrequencyText() {
    switch (widget.challenge.frequency) {
      case ChallengeFrequency.daily:
        return '매일';
      case ChallengeFrequency.weekly:
        return '주 ${widget.challenge.frequencyCount}회';
      case ChallengeFrequency.monthly:
        return '월 ${widget.challenge.frequencyCount}회';
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
          // 헤더 (항상 표시)
          InkWell(
            onTap: () {
              setState(() {
                _isRulesExpanded = !_isRulesExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📋 규칙',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191F28),
                    ),
                  ),
                  Icon(
                    _isRulesExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF8B95A1),
                  ),
                ],
              ),
            ),
          ),
          
          // 규칙 텍스트 (접기/펼치기)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: Text(
                widget.challenge.rules,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4E5968),
                  height: 1.6,
                ),
              ),
            ),
            crossFadeState: _isRulesExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          
          // 중요 정보 (항상 표시)
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
                  value: '${widget.challenge.penaltyAmount.toStringAsFixed(0)}원',
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
                  value: dateFormat.format(widget.challenge.startDate),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoRow(
                  icon: Icons.event,
                  label: '종료일',
                  value: widget.challenge.endDate == null 
                      ? '미정' 
                      : dateFormat.format(widget.challenge.endDate!),
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

class _MembersSection extends StatefulWidget {
  final Challenge challenge;
  final bool isCreator;
  final bool isMember;
  final VoidCallback onAddMember;

  const _MembersSection({
    required this.challenge,
    required this.isCreator,
    required this.isMember,
    required this.onAddMember,
  });

  @override
  State<_MembersSection> createState() => _MembersSectionState();
}

class _MembersSectionState extends State<_MembersSection> {
  bool _isExpanded = false;

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
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '👥 참가자 (${widget.challenge.members.length}명)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191F28),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFF8B95A1),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.isCreator)
                TextButton.icon(
                  onPressed: widget.onAddMember,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('초대'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3182F6),
                  ),
                ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: widget.challenge.members.map((member) => _MemberItem(
                  memberId: member.id,
                  isLeader: member.isLeader,
                  displayName: member.name, // ID가 아닌 실제 닉네임
                )).toList(),
              ),
            ),
            crossFadeState: _isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
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
  final bool isMember;

  const _VerificationsSection({
    required this.challenge,
    required this.isMember,
  });

  @override
  State<_VerificationsSection> createState() => _VerificationsSectionState();
}

class _VerificationsSectionState extends State<_VerificationsSection> {
  bool _isExpanded = false;
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
          InkWell(
            onTap: widget.isMember
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VerificationHistoryScreen(
                          challengeId: widget.challenge.id,
                          challenge: widget.challenge,
                        ),
                      ),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '✅ 인증 내역 (${widget.challenge.verifications.length}건)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isMember 
                          ? const Color(0xFF191F28)
                          : const Color(0xFF8B95A1),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: widget.isMember 
                        ? const Color(0xFF8B95A1)
                        : const Color(0xFFE5E8EB),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: verifications.isEmpty
                  ? Center(
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
                  : Column(
                      children: [
                        ...displayedVerifications.map((verification) {
                          return _VerificationItem(
                            verification: verification,
                            challengeId: widget.challenge.id,
                          );
                        }),
                        if (hasMore) const SizedBox(height: 12),
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
            ),
            crossFadeState: _isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
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
