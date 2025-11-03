import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/challenge.dart';
import '../utils/text_encoding.dart';

class EditChallengeScreen extends StatefulWidget {
  final Challenge challenge;

  const EditChallengeScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<EditChallengeScreen> createState() => _EditChallengeScreenState();
}

class _EditChallengeScreenState extends State<EditChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _rulesController;
  late final TextEditingController _penaltyController;
  late final TextEditingController _penaltyValueController;
  late final TextEditingController _frequencyCountController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.challenge.title);
    _descriptionController = TextEditingController(text: widget.challenge.description);
    _rulesController = TextEditingController(text: widget.challenge.rules);
    _penaltyController = TextEditingController(text: widget.challenge.penaltyAmount.toStringAsFixed(0));
    _penaltyValueController = TextEditingController(
      text: widget.challenge.penaltyValue > 0 
          ? widget.challenge.penaltyValue.toStringAsFixed(0) 
          : '',
    );
    _frequencyCountController = TextEditingController(text: widget.challenge.frequencyCount.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _penaltyController.dispose();
    _penaltyValueController.dispose();
    _frequencyCountController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final firestoreService = FirestoreService();
        final updatedChallenge = widget.challenge.copyWith(
          title: TextEncoding.normalizeInput(_titleController.text),
          description: TextEncoding.normalizeInput(_descriptionController.text),
          rules: TextEncoding.normalizeInput(_rulesController.text),
          penaltyAmount: double.parse(_penaltyController.text),
          penaltyValue: _penaltyValueController.text.isNotEmpty 
              ? double.parse(_penaltyValueController.text)
              : 0.0,
          frequencyCount: int.parse(_frequencyCountController.text),
        );

        await firestoreService.updateChallenge(updatedChallenge);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('챌린지가 수정되었습니다!'),
              backgroundColor: Color(0xFF17C964),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('수정 실패: $e'),
              backgroundColor: const Color(0xFFFF5247),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('챌린지 수정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              const Text(
                '제목',
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
                  hintText: '챌린지 규칙을 입력해주세요',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '규칙을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // 인증 빈도
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '인증 빈도',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF191F28),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _frequencyCountController,
                          decoration: const InputDecoration(
                            hintText: '횟수',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '횟수를 입력해주세요';
                            }
                            if (int.tryParse(value) == null || int.parse(value) < 1) {
                              return '1 이상의 숫자를 입력해주세요';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            hintText: '금액',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            suffixText: '원',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '벌금을 입력해주세요';
                            }
                            if (double.tryParse(value) == null || double.parse(value) < 0) {
                              return '0 이상의 숫자를 입력해주세요';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

