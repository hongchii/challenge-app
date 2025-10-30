// Firebase 없이 테스트할 때 사용하는 Mock Provider
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProviderMock extends ChangeNotifier {
  UserModel? _userModel;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  UserModel? get userModel => _userModel;

  // 테스트용 자동 로그인
  AuthProviderMock() {
    // 앱 시작시 테스트 사용자로 자동 로그인
    _userModel = UserModel(
      id: 'test-user-1',
      email: 'test@test.com',
      nickname: '테스트유저',
      profileImageUrl: null,
      createdAt: DateTime.now(),
      friendIds: [],
    );
    _isAuthenticated = true;
  }

  Future<void> signOut() async {
    _userModel = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> updateProfile(UserModel user) async {
    _userModel = user;
    notifyListeners();
  }

  Future<void> updatePassword(String newPassword) async {
    // Mock - 아무것도 하지 않음
  }
}

