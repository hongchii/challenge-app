import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/challenge.dart';
import '../models/member.dart';
import '../utils/text_encoding.dart';

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _pageController = PageController();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  final _penaltyController = TextEditingController();
  final _penaltyValueController = TextEditingController();
  final _frequencyCountController = TextEditingController(text: '1');
  final _maxParticipantsController = TextEditingController();

  int _currentPage = 0;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isEndDateUndecided = false;
  ChallengeFrequency _frequency = ChallengeFrequency.daily;
  PenaltyType _penaltyType = PenaltyType.none;
  // bool _hasMaxParticipants = false; // TODO: 나중에 최대 정원 설정 기능 추가 시 사용

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _penaltyController.dispose();
    _penaltyValueController.dispose();
    _frequencyCountController.dispose();
    _maxParticipantsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('ko', 'KR'),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (!_isEndDateUndecided && _endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _nextPage() {
    if (_formKey1.currentState!.validate()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _createChallenge() async {
    if (_formKey2.currentState!.validate()) {
      final uuid = const Uuid();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firestoreService = FirestoreService();
      final currentUser = authProvider.userModel;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요합니다'),
            backgroundColor: Color(0xFFFF5247),
          ),
        );
        return;
      }

      final leader = Member(
        id: currentUser.id,
        name: currentUser.nickname,
        isLeader: true,
      );

      final challenge = Challenge(
        id: uuid.v4(),
        title: TextEncoding.normalizeInput(_titleController.text),
        description: TextEncoding.normalizeInput(_descriptionController.text),
        rules: TextEncoding.normalizeInput(_rulesController.text),
        startDate: _startDate,
        endDate: _isEndDateUndecided ? null : _endDate,
        frequency: _frequency,
        frequencyCount: int.parse(_frequencyCountController.text),
        penaltyAmount: double.parse(_penaltyController.text),
        penaltyType: _penaltyType,
        penaltyValue: _penaltyType == PenaltyType.none 
            ? 0.0 
            : double.parse(_penaltyValueController.text),
        isPrivate: false, // TODO: 나중에 비밀 챌린지 기능 활성화 시 사용
        maxParticipants: null, // TODO: 나중에 최대 정원 설정 기능 활성화 시 사용
        creatorId: currentUser.id,
        participantIds: [currentUser.id],
        members: [leader],
      );

      try {
        await firestoreService.createChallenge(challenge);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('챌린지가 생성되었습니다!'),
              backgroundColor: Color(0xFF17C964),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('생성 실패: $e'),
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
      appBar: AppBar(
        title: Text(_currentPage == 0 ? '새 챌린지 만들기 (1/2)' : '새 챌린지 만들기 (2/2)'),
      ),
      body: Column(
        children: [
          // 진행 표시 인디케이터
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3182F6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: _currentPage == 1 
                          ? const Color(0xFF3182F6) 
                          : const Color(0xFFE5E8EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 페이지 뷰
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildStep1(),
                _buildStep2(),
              ],
            ),
          ),
          
          // 하단 버튼
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentPage == 1) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFF3182F6)),
                        ),
                        child: const Text('이전'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: _currentPage == 0 ? _nextPage : _createChallenge,
                      child: Text(_currentPage == 0 ? '다음' : '챌린지 만들기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: 기본 정보
  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '기본 정보',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191F28),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '챌린지의 기본 정보를 입력해주세요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8B95A1),
            ),
          ),
          const SizedBox(height: 32),
          
          // 챌린지 제목
          const Text(
            '챌린지 제목',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191F28),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: '예: 무지출 챌린지',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(fontSize: 16),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '제목을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // 설명
          const Text(
            '설명',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191F28),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: '챌린지에 대한 간단한 설명',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(fontSize: 16),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '설명을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // 규칙
          const Text(
            '규칙',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191F28),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _rulesController,
            decoration: const InputDecoration(
              hintText: '챌린지 규칙을 입력하세요',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(fontSize: 16),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '규칙을 입력해주세요';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // Step 2: 상세 설정
  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '상세 설정',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191F28),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '챌린지의 기간과 벌금을 설정해주세요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8B95A1),
            ),
          ),
          const SizedBox(height: 32),
          
          // 시작일
          const Text(
            '시작일',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191F28),
            ),
          ),
          const SizedBox(height: 8),
          _DateSelector(
            date: _startDate,
            onTap: () => _selectDate(context, true),
          ),
          const SizedBox(height: 16),
          
          // 종료일 미정 체크박스
          CheckboxListTile(
            value: _isEndDateUndecided,
            onChanged: (value) {
              setState(() {
                _isEndDateUndecided = value ?? false;
              });
            },
            title: const Text(
              '종료일 미정',
              style: TextStyle(fontSize: 15),
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFF3182F6),
          ),
          
          // 종료일
          if (!_isEndDateUndecided) ...[
            const SizedBox(height: 8),
            const Text(
              '종료일',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191F28),
              ),
            ),
            const SizedBox(height: 8),
            _DateSelector(
              date: _endDate,
              onTap: () => _selectDate(context, false),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // 인증 빈도
          const Text(
            '인증 빈도',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E5968),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ChallengeFrequency>(
            segments: const [
              ButtonSegment(
                value: ChallengeFrequency.daily,
                label: Text('매일'),
                icon: Icon(Icons.today, size: 18),
              ),
              ButtonSegment(
                value: ChallengeFrequency.weekly,
                label: Text('주간'),
                icon: Icon(Icons.calendar_view_week, size: 18),
              ),
              ButtonSegment(
                value: ChallengeFrequency.monthly,
                label: Text('월간'),
                icon: Icon(Icons.calendar_month, size: 18),
              ),
            ],
            selected: {_frequency},
            onSelectionChanged: (Set<ChallengeFrequency> newSelection) {
              setState(() {
                _frequency = newSelection.first;
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF3182F6);
                }
                return Colors.white;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return const Color(0xFF4E5968);
              }),
              side: WidgetStateProperty.all(BorderSide.none),
            ),
          ),
          
          if (_frequency != ChallengeFrequency.daily) ...[
            const SizedBox(height: 24),
            Text(
              _frequency == ChallengeFrequency.weekly ? '주 몇 회?' : '월 몇 회?',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191F28),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _frequencyCountController,
              decoration: const InputDecoration(
                hintText: '1',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixText: '회',
              ),
              style: const TextStyle(fontSize: 16),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '횟수를 입력해주세요';
                }
                final num = int.tryParse(value);
                if (num == null || num < 1) {
                  return '1 이상의 숫자를 입력해주세요';
                }
                return null;
              },
            ),
          ],
          
          const SizedBox(height: 24),
          
          // 벌금 설정
          const Text(
            '1회 실패당 벌금',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191F28),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _penaltyController,
            decoration: const InputDecoration(
              hintText: '10000',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixText: '원',
            ),
            style: const TextStyle(fontSize: 16),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '벌금을 입력해주세요';
              }
              final num = double.tryParse(value);
              if (num == null || num < 0) {
                return '올바른 금액을 입력해주세요';
              }
              return null;
            },
          ),
          
          // TODO: 나중에 최대 정원 설정 기능 추가
          // const SizedBox(height: 24),
          // 
          // // 최대 정원 설정
          // CheckboxListTile(
          //   value: _hasMaxParticipants,
          //   onChanged: (value) {
          //     setState(() {
          //       _hasMaxParticipants = value ?? false;
          //       if (!_hasMaxParticipants) {
          //         _maxParticipantsController.clear();
          //       }
          //     });
          //   },
          //   title: const Text(
          //     '최대 정원 설정',
          //     style: TextStyle(fontSize: 15),
          //   ),
          //   contentPadding: EdgeInsets.zero,
          //   controlAffinity: ListTileControlAffinity.leading,
          //   activeColor: const Color(0xFF3182F6),
          // ),
          // 
          // if (_hasMaxParticipants) ...[
          //   const SizedBox(height: 16),
          //   const Text(
          //     '최대 참가 인원',
          //     style: TextStyle(
          //       fontSize: 15,
          //       fontWeight: FontWeight.w600,
          //       color: Color(0xFF191F28),
          //     ),
          //   ),
          //   const SizedBox(height: 8),
          //   TextFormField(
          //     controller: _maxParticipantsController,
          //     decoration: const InputDecoration(
          //       hintText: '10',
          //       border: OutlineInputBorder(),
          //       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          //       suffixText: '명',
          //     ),
          //     style: const TextStyle(fontSize: 16),
          //     keyboardType: TextInputType.number,
          //     validator: (value) {
          //       if (_hasMaxParticipants) {
          //         if (value == null || value.isEmpty) {
          //           return '최대 인원을 입력해주세요';
          //         }
          //         final num = int.tryParse(value);
          //         if (num == null || num < 2) {
          //           return '2명 이상이어야 합니다';
          //         }
          //       }
          //       return null;
          //     },
          //   ),
          // ],
          
          const SizedBox(height: 80), // 하단 버튼 공간 확보
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback? onTap;

  const _DateSelector({
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E8EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF191F28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
