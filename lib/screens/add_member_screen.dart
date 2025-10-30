import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/challenge_provider.dart';
import '../models/member.dart';

class AddMemberScreen extends StatefulWidget {
  final String challengeId;

  const AddMemberScreen({
    super.key,
    required this.challengeId,
  });

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addMember() {
    if (_formKey.currentState!.validate()) {
      final uuid = const Uuid();
      final member = Member(
        id: uuid.v4(),
        name: _nameController.text.trim(),
        isLeader: false,
      );

      Provider.of<ChallengeProvider>(context, listen: false)
          .addMember(widget.challengeId, member);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name}님이 초대되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 초대하기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3FF),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 50,
                  color: Color(0xFF3182F6),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '새로운 참가자를 초대하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '참가자 이름',
                  hintText: '홍길동',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addMember,
                child: const Text('초대하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

