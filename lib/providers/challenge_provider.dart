import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge.dart';
import '../models/member.dart';
import '../models/verification.dart';

class ChallengeProvider with ChangeNotifier {
  List<Challenge> _challenges = [];
  
  List<Challenge> get challenges => _challenges;

  // SharedPreferences 키
  static const String _storageKey = 'challenges';

  // 데이터 로드
  Future<void> loadChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final String? challengesJson = prefs.getString(_storageKey);
    
    if (challengesJson != null) {
      final List<dynamic> decoded = jsonDecode(challengesJson);
      _challenges = decoded.map((json) => Challenge.fromJson(json)).toList();
      notifyListeners();
    }
  }

  // 데이터 저장
  Future<void> _saveChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _challenges.map((c) => c.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  // 챌린지 추가
  Future<void> addChallenge(Challenge challenge) async {
    _challenges.add(challenge);
    notifyListeners();
    await _saveChallenges();
  }

  // 챌린지 업데이트
  Future<void> updateChallenge(Challenge challenge) async {
    final index = _challenges.indexWhere((c) => c.id == challenge.id);
    if (index != -1) {
      _challenges[index] = challenge;
      notifyListeners();
      await _saveChallenges();
    }
  }

  // 챌린지 삭제
  Future<void> deleteChallenge(String challengeId) async {
    _challenges.removeWhere((c) => c.id == challengeId);
    notifyListeners();
    await _saveChallenges();
  }

  // 챌린지 가져오기
  Challenge? getChallengeById(String id) {
    try {
      return _challenges.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // 멤버 추가
  Future<void> addMember(String challengeId, Member member) async {
    final challenge = getChallengeById(challengeId);
    if (challenge != null) {
      final updatedMembers = [...challenge.members, member];
      final updatedChallenge = challenge.copyWith(members: updatedMembers);
      await updateChallenge(updatedChallenge);
    }
  }

  // 인증 추가
  Future<void> addVerification(String challengeId, Verification verification) async {
    final challenge = getChallengeById(challengeId);
    if (challenge != null) {
      final updatedVerifications = [...challenge.verifications, verification];
      final updatedChallenge = challenge.copyWith(verifications: updatedVerifications);
      await updateChallenge(updatedChallenge);
    }
  }

  // 특정 멤버의 오늘 인증 여부 확인
  bool hasVerifiedToday(String challengeId, String memberId) {
    final challenge = getChallengeById(challengeId);
    if (challenge == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return challenge.verifications.any((v) {
      final verificationDate = DateTime(
        v.dateTime.year,
        v.dateTime.month,
        v.dateTime.day,
      );
      return v.memberId == memberId && verificationDate == today;
    });
  }
}

