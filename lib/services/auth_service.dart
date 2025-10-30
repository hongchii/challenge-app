import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // 현재 사용자 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 이메일/비밀번호로 회원가입
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
    String? profileImageUrl,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Firestore에 사용자 정보 저장
        final userModel = UserModel(
          id: credential.user!.uid,
          email: email,
          nickname: nickname,
          profileImageUrl: profileImageUrl,
          createdAt: DateTime.now(),
        );

        await _firestoreService.createUser(userModel);
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 이메일/비밀번호로 로그인
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 비밀번호 변경
  Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 에러 처리
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'user-not-found':
        return '사용자를 찾을 수 없습니다.';
      case 'wrong-password':
        return '잘못된 비밀번호입니다.';
      case 'too-many-requests':
        return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '오류가 발생했습니다: ${e.message}';
    }
  }
}

