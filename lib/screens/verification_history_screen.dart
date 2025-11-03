import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/challenge.dart';
import '../models/verification.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import 'verification_detail_screen.dart';

class VerificationHistoryScreen extends StatefulWidget {
  final String challengeId;
  final Challenge challenge;

  const VerificationHistoryScreen({
    super.key,
    required this.challengeId,
    required this.challenge,
  });

  @override
  State<VerificationHistoryScreen> createState() => _VerificationHistoryScreenState();
}

class _VerificationHistoryScreenState extends State<VerificationHistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLocaleInitialized = false;

  @override
  void initState() {
    super.initState();
    // 현재 날짜로 초기화
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    // 한국어 로케일 초기화
    _initializeDateFormatting();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('ko_KR', null);
    if (mounted) {
      setState(() {
        _isLocaleInitialized = true;
      });
    }
  }

  // 인증된 날짜 목록 가져오기 (중복 제거하여 하나의 날짜만 표시)
  Set<String> _getVerificationDates() {
    return widget.challenge.verifications
        .map((v) {
          final date = DateTime(v.dateTime.year, v.dateTime.month, v.dateTime.day);
          return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        })
        .toSet();
  }

  // 날짜를 정규화된 문자열로 변환
  String _normalizeDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 특정 날짜의 인증 목록 가져오기
  List<Verification> _getVerificationsForDate(DateTime date) {
    return widget.challenge.verifications.where((v) {
      final verificationDate = DateTime(v.dateTime.year, v.dateTime.month, v.dateTime.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return verificationDate.isAtSameMomentAs(targetDate);
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  // 달력 이벤트 표시용
  List<Verification> _getEventsForDay(DateTime day) {
    return _getVerificationsForDate(day);
  }

  // 해당 월의 인증 목록 가져오기
  List<Verification> _getVerificationsForMonth(DateTime month) {
    return widget.challenge.verifications.where((v) {
      return v.dateTime.year == month.year && v.dateTime.month == month.month;
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Widget build(BuildContext context) {
    // 참가자 확인
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userModel?.id ?? '';
    final isMember = widget.challenge.participantIds.contains(currentUserId);

    if (!isMember) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9FAFB),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF191F28)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '인증내역',
            style: TextStyle(
              color: Color(0xFF191F28),
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '챌린지 참가자만 접근할 수 있습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isLocaleInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9FAFB),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF191F28)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '인증내역',
            style: TextStyle(
              color: Color(0xFF191F28),
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final verificationDates = _getVerificationDates();
    final monthVerifications = _getVerificationsForMonth(_focusedDay);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // 흰색 배경
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF191F28)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '인증내역',
          style: TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 챌린지 요약 박스
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3182F6), Color(0xFF1B64DA)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '인증하기',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.challenge.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 달력
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar<Verification>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: true,
                weekendTextStyle: const TextStyle(color: Color(0xFF3182F6)),
                holidayTextStyle: const TextStyle(color: Color(0xFFFF5247)),
                defaultTextStyle: const TextStyle(color: Color(0xFF191F28)),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                todayTextStyle: const TextStyle(
                  color: Color(0xFF191F28),
                  fontWeight: FontWeight.bold,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF3182F6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: const Color(0xFF3182F6),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFFFD700), // 노란색 점
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerSize: 6,
                outsideTextStyle: TextStyle(
                  color: Colors.grey[400],
                ),
                outsideDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF191F28),
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF191F28),
                ),
                titleTextStyle: const TextStyle(
                  color: Color(0xFF191F28),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Color(0xFF191F28)),
                weekendStyle: TextStyle(color: Color(0xFF3182F6)),
              ),
              locale: 'ko_KR',
              // 요일 헤더 커스터마이징
              daysOfWeekHeight: 40,
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                  // 월이 변경되면 첫 번째 날로 선택 초기화
                  _selectedDay = DateTime(focusedDay.year, focusedDay.month, 1);
                });
              },
              // 요일 헤더 커스터마이징
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, events) {
                  final isVerificationDay = verificationDates.contains(
                    _normalizeDate(date),
                  );
                  
                  return Container(
                    height: 36,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: date.weekday == DateTime.sunday
                                ? const Color(0xFFFF5247)
                                : date.weekday == DateTime.saturday
                                    ? const Color(0xFF3182F6)
                                    : const Color(0xFF191F28),
                            fontSize: 13,
                          ),
                        ),
                        if (isVerificationDay)
                          Positioned(
                            bottom: 3,
                            child: ClipOval(
                              child: Container(
                                width: 6,
                                height: 6,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                todayBuilder: (context, date, events) {
                  final isVerificationDay = verificationDates.contains(
                    _normalizeDate(date),
                  );
                  
                  return Container(
                    height: 36,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3182F6).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: date.weekday == DateTime.sunday
                                    ? const Color(0xFFFF5247)
                                    : date.weekday == DateTime.saturday
                                        ? const Color(0xFF3182F6)
                                        : const Color(0xFF191F28),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (isVerificationDay)
                          Positioned(
                            bottom: 3,
                            child: ClipOval(
                              child: Container(
                                width: 6,
                                height: 6,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                selectedBuilder: (context, date, events) {
                  final isVerificationDay = verificationDates.contains(
                    _normalizeDate(date),
                  );
                  
                  return Container(
                    height: 36,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3182F6),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (isVerificationDay)
                          Positioned(
                            bottom: 3,
                            child: ClipOval(
                              child: Container(
                                width: 6,
                                height: 6,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                outsideBuilder: (context, date, events) {
                  return Text(
                    '${date.day}',
                    style: TextStyle(
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 인증 목록
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: monthVerifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '이번 달 인증 기록이 없습니다',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: monthVerifications.length,
                      itemBuilder: (context, index) {
                        final verification = monthVerifications[index];
                        return _VerificationListItem(
                          verification: verification,
                          challengeId: widget.challengeId,
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _VerificationListItem extends StatelessWidget {
  final Verification verification;
  final String challengeId;

  const _VerificationListItem({
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerificationDetailScreen(
                    verification: verification,
                    challengeId: challengeId,
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
                    size: 24,
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
                            fontSize: 15,
                            color: Color(0xFF191F28),
                          ),
                        ),
                        if (verification.note != null && verification.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              verification.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4E5968),
                              ),
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

