import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      
      if (user != null) {
        _userModel = await _firestoreService.getUser(user.uid);
      } else {
        _userModel = null;
      }
      
      notifyListeners();
    });
  }

  // 회원가입
  Future<bool> signUp({
    required String email,
    required String password,
    required String nickname,
    String? profileImageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
      );

      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 로그인
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }

  // 프로필 업데이트
  Future<bool> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updateUser(updatedUser);
      _userModel = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 비밀번호 변경
  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.updatePassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

