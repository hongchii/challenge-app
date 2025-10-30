import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/payment_record.dart';

class PenaltyHistoryScreen extends StatelessWidget {
  final String userId;

  const PenaltyHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('벌금 현황'),
      ),
      body: StreamBuilder<List<PaymentRecord>>(
        stream: firestoreService.userPaymentRecords(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('오류가 발생했습니다: ${snapshot.error}'),
            );
          }

          final records = snapshot.data ?? [];

          // 총 벌금 계산
          final totalPending = records
              .where((r) => r.status == PaymentStatus.pending)
              .fold<double>(0, (sum, r) => sum + r.amount);

          final totalCompleted = records
              .where((r) => r.status == PaymentStatus.completed)
              .fold<double>(0, (sum, r) => sum + r.amount);

          final numberFormat = NumberFormat('#,###');

          return Column(
            children: [
              // 요약 카드
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5247), Color(0xFFFF7A6B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          label: '미입금',
                          amount: totalPending,
                          numberFormat: numberFormat,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _SummaryItem(
                          label: '입금 완료',
                          amount: totalCompleted,
                          numberFormat: numberFormat,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 벌금 목록
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: Text(
                          '벌금 내역이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B95A1),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return _PaymentRecordCard(
                            record: record,
                            numberFormat: numberFormat,
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

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final NumberFormat numberFormat;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${numberFormat.format(amount)}원',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PaymentRecordCard extends StatelessWidget {
  final PaymentRecord record;
  final NumberFormat numberFormat;

  const _PaymentRecordCard({
    required this.record,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final isPending = record.status == PaymentStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isPending
              ? const Color(0xFFFFEBEE)
              : const Color(0xFFE8F5E9),
          child: Icon(
            isPending ? Icons.schedule : Icons.check_circle,
            color: isPending ? const Color(0xFFFF5247) : const Color(0xFF17C964),
          ),
        ),
        title: Text(
          '${numberFormat.format(record.amount)}원',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dateFormat.format(record.createdAt),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8B95A1),
              ),
            ),
            if (!isPending && record.confirmedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '입금 확인: ${dateFormat.format(record.confirmedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF17C964),
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isPending
                ? const Color(0xFFFFEBEE)
                : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isPending ? '미입금' : '완료',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPending ? const Color(0xFFFF5247) : const Color(0xFF17C964),
            ),
          ),
        ),
      ),
    );
  }
}

