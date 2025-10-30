import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/challenge.dart';
import '../models/member.dart';

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  final _penaltyController = TextEditingController();
  final _penaltyValueController = TextEditingController();
  final _leaderNameController = TextEditingController();
  final _frequencyCountController = TextEditingController(text: '1');
  final _maxParticipantsController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isEndDateUndecided = false;
  ChallengeFrequency _frequency = ChallengeFrequency.daily;
  PenaltyType _penaltyType = PenaltyType.none;
  bool _isPrivate = false;
  bool _hasMaxParticipants = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _penaltyController.dispose();
    _penaltyValueController.dispose();
    _leaderNameController.dispose();
    _frequencyCountController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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

  Future<void> _createChallenge() async {
    if (_formKey.currentState!.validate()) {
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
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        rules: _rulesController.text.trim(),
        startDate: _startDate,
        endDate: _isEndDateUndecided ? null : _endDate,
        frequency: _frequency,
        frequencyCount: int.parse(_frequencyCountController.text),
        penaltyAmount: double.parse(_penaltyController.text),
        penaltyType: _penaltyType,
        penaltyValue: _penaltyType == PenaltyType.none 
            ? 0.0 
            : double.parse(_penaltyValueController.text),
        isPrivate: _isPrivate,
        maxParticipants: _hasMaxParticipants 
            ? int.parse(_maxParticipantsController.text)
            : null,
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
        title: const Text('새 챌린지 만들기'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('기본 정보'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '챌린지 제목',
                hintText: '예: 무지출 챌린지',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '제목을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명',
                hintText: '챌린지에 대한 간단한 설명',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '설명을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rulesController,
              decoration: const InputDecoration(
                labelText: '규칙',
                hintText: '챌린지 규칙을 자세히 적어주세요',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.rule),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '규칙을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('기간 설정'),
            Row(
              children: [
                Expanded(
                  child: _DateSelector(
                    label: '시작일',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateSelector(
                    label: '종료일',
                    date: _endDate,
                    onTap: _isEndDateUndecided ? null : () => _selectDate(context, false),
                    isDisabled: _isEndDateUndecided,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 24),
            _buildSectionTitle('인증 빈도'),
            DropdownButtonFormField<ChallengeFrequency>(
              initialValue: _frequency,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(
                  value: ChallengeFrequency.daily,
                  child: Text('매일'),
                ),
                DropdownMenuItem(
                  value: ChallengeFrequency.weekly,
                  child: Text('주 n회'),
                ),
                DropdownMenuItem(
                  value: ChallengeFrequency.monthly,
                  child: Text('월 n회'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _frequency = value!;
                });
              },
            ),
            if (_frequency != ChallengeFrequency.daily) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _frequencyCountController,
                decoration: InputDecoration(
                  labelText: _frequency == ChallengeFrequency.weekly
                      ? '주당 횟수'
                      : '월당 횟수',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers),
                ),
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
            _buildSectionTitle('벌금 설정'),
            TextFormField(
              controller: _penaltyController,
              decoration: const InputDecoration(
                labelText: '1회 실패당 벌금 (원)',
                hintText: '10000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
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
            const SizedBox(height: 16),
            const Text(
              '추가 벌금',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E5968),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PenaltyTypeChip(
                  label: '없음',
                  isSelected: _penaltyType == PenaltyType.none,
                  onTap: () {
                    setState(() {
                      _penaltyType = PenaltyType.none;
                    });
                  },
                ),
                _PenaltyTypeChip(
                  label: '이자율 (%)',
                  isSelected: _penaltyType == PenaltyType.percentage,
                  onTap: () {
                    setState(() {
                      _penaltyType = PenaltyType.percentage;
                    });
                  },
                ),
                _PenaltyTypeChip(
                  label: '고정 금액 (+원)',
                  isSelected: _penaltyType == PenaltyType.fixedAmount,
                  onTap: () {
                    setState(() {
                      _penaltyType = PenaltyType.fixedAmount;
                    });
                  },
                ),
              ],
            ),
            if (_penaltyType != PenaltyType.none) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _penaltyValueController,
                decoration: InputDecoration(
                  labelText: _penaltyType == PenaltyType.percentage 
                      ? '이자율 (%)' 
                      : '추가 금액 (원)',
                  hintText: _penaltyType == PenaltyType.percentage 
                      ? '10' 
                      : '5000',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    _penaltyType == PenaltyType.percentage 
                        ? Icons.percent 
                        : Icons.add,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_penaltyType == PenaltyType.none) return null;
                  if (value == null || value.isEmpty) {
                    return '값을 입력해주세요';
                  }
                  final num = double.tryParse(value);
                  if (num == null || num < 0) {
                    return '0 이상의 숫자를 입력해주세요';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            _buildSectionTitle('챌린지 설정'),
            
            // 공개/비밀 선택
            CheckboxListTile(
              value: _isPrivate,
              onChanged: (value) {
                setState(() {
                  _isPrivate = value ?? false;
                });
              },
              title: const Text(
                '비밀 챌린지',
                style: TextStyle(fontSize: 15),
              ),
              subtitle: const Text(
                '승인된 사람만 참여할 수 있습니다',
                style: TextStyle(fontSize: 13, color: Color(0xFF8B95A1)),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF3182F6),
            ),
            
            // 최대 정원 설정
            CheckboxListTile(
              value: _hasMaxParticipants,
              onChanged: (value) {
                setState(() {
                  _hasMaxParticipants = value ?? false;
                  if (!_hasMaxParticipants) {
                    _maxParticipantsController.clear();
                  }
                });
              },
              title: const Text(
                '최대 정원 설정',
                style: TextStyle(fontSize: 15),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF3182F6),
            ),
            
            if (_hasMaxParticipants) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(
                  labelText: '최대 참가 인원',
                  hintText: '10',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                  suffixText: '명',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_hasMaxParticipants) {
                    if (value == null || value.isEmpty) {
                      return '최대 인원을 입력해주세요';
                    }
                    final num = int.tryParse(value);
                    if (num == null || num < 2) {
                      return '2명 이상이어야 합니다';
                    }
                  }
                  return null;
                },
              ),
            ],
                const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createChallenge,
              child: const Text('챌린지 만들기'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF191F28),
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback? onTap;
  final bool isDisabled;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
          enabled: !isDisabled,
        ),
        child: Text(
          isDisabled 
              ? '미정' 
              : '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 16,
            color: isDisabled ? const Color(0xFF8B95A1) : null,
          ),
        ),
      ),
    );
  }
}

class _PenaltyTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PenaltyTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F3FF) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF3182F6) : const Color(0xFFE5E8EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFF3182F6) : const Color(0xFF4E5968),
          ),
        ),
      ),
    );
  }
}

