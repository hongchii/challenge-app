import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/challenge_provider.dart';
import '../models/penalty.dart';
import '../models/challenge.dart';

class PenaltyScreen extends StatelessWidget {
  final String challengeId;

  const PenaltyScreen({
    super.key,
    required this.challengeId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('벌금 계산'),
      ),
      body: Consumer<ChallengeProvider>(
        builder: (context, provider, child) {
          final challenge = provider.getChallengeById(challengeId);

          if (challenge == null) {
            return const Center(
              child: Text('챌린지를 찾을 수 없습니다.'),
            );
          }

          // 모든 멤버의 벌금 계산
          final penalties = challenge.members
              .map((member) => challenge.calculatePenalty(member.id))
              .toList();

          // 총 벌금 계산
          final totalPenalty = penalties.fold<double>(
            0.0,
            (sum, penalty) => sum + penalty.amount,
          );

          return Column(
            children: [
              _PenaltyHeader(
                challenge: challenge,
                totalPenalty: totalPenalty,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: penalties.length,
                  itemBuilder: (context, index) {
                    final penalty = penalties[index];
                    final member = challenge.members
                        .firstWhere((m) => m.id == penalty.memberId);

                    return _PenaltyCard(
                      memberName: member.name,
                      isLeader: member.isLeader,
                      penalty: penalty,
                      penaltyAmount: challenge.penaltyAmount,
                      penaltyType: challenge.penaltyType,
                      interestRate: challenge.penaltyValue,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PenaltyHeader extends StatelessWidget {
  final dynamic challenge;
  final double totalPenalty;

  const _PenaltyHeader({
    required this.challenge,
    required this.totalPenalty,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF5247),
            Color(0xFFFF7A6B),
          ],
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            '총 벌금',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${numberFormat.format(totalPenalty)}원',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (challenge.penaltyType != PenaltyType.none)
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
                challenge.penaltyType == PenaltyType.percentage
                    ? '이자율 ${challenge.penaltyValue.toStringAsFixed(1)}% 포함'
                    : '추가 벌금 +${challenge.penaltyValue.toStringAsFixed(0)}원 포함',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PenaltyCard extends StatelessWidget {
  final String memberName;
  final bool isLeader;
  final Penalty penalty;
  final double penaltyAmount;
  final PenaltyType penaltyType;
  final double interestRate;

  const _PenaltyCard({
    required this.memberName,
    required this.isLeader,
    required this.penalty,
    required this.penaltyAmount,
    required this.penaltyType,
    required this.interestRate,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final basePenalty = penalty.failedCount * penaltyAmount;
    
    double additionalAmount = 0;
    String additionalLabel = '';
    
    if (penaltyType == PenaltyType.percentage) {
      additionalAmount = basePenalty * (interestRate / 100);
      additionalLabel = '이자 (${interestRate.toStringAsFixed(1)}%)';
    } else if (penaltyType == PenaltyType.fixedAmount) {
      additionalAmount = penalty.failedCount * interestRate;
      additionalLabel = '추가 벌금 (+${interestRate.toStringAsFixed(0)}원)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EB)),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isLeader
              ? const Color(0xFFFFD600)
              : const Color(0xFFE8F3FF),
          child: Icon(
            isLeader ? Icons.star : Icons.person,
            color: isLeader
                ? Colors.white
                : const Color(0xFF3182F6),
          ),
        ),
        title: Row(
          children: [
            Text(
              memberName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isLeader) ...[
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
          '미달성 ${penalty.failedCount}회',
          style: TextStyle(
            fontSize: 13,
            color: penalty.failedCount > 0 ? const Color(0xFFFF9800) : const Color(0xFF17C964),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${numberFormat.format(penalty.amount)}원',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: penalty.amount > 0 ? const Color(0xFFFF5247) : const Color(0xFF17C964),
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '벌금 상세 내역',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: '미달성 횟수',
                  value: '${penalty.failedCount}회',
                ),
                _DetailRow(
                  label: '1회당 벌금',
                  value: '${numberFormat.format(penaltyAmount)}원',
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: '기본 벌금',
                  value: '${numberFormat.format(basePenalty)}원',
                  isHighlight: false,
                ),
                if (penaltyType != PenaltyType.none)
                  _DetailRow(
                    label: additionalLabel,
                    value: '${numberFormat.format(additionalAmount)}원',
                    isHighlight: false,
                  ),
                const Divider(height: 24),
                _DetailRow(
                  label: '최종 벌금',
                  value: '${numberFormat.format(penalty.amount)}원',
                  isHighlight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? const Color(0xFF191F28) : const Color(0xFF4E5968),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? const Color(0xFFFF5247) : const Color(0xFF191F28),
            ),
          ),
        ],
      ),
    );
  }
}

