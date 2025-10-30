import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/challenge.dart';
import '../models/friend_request.dart';
import '../models/payment_record.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== 사용자 관련 ====================

  // 사용자 생성
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toJson());
  }

  // 사용자 정보 가져오기
  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  // 사용자 정보 업데이트
  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.id).update(user.toJson());
  }

  // 닉네임으로 사용자 검색
  Future<List<UserModel>> searchUsersByNickname(String nickname) async {
    final snapshot = await _db
        .collection('users')
        .where('nickname', isGreaterThanOrEqualTo: nickname)
        .where('nickname', isLessThanOrEqualTo: '$nickname\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();
  }

  // 사용자 스트림
  Stream<UserModel?> userStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  // ==================== 친구 요청 관련 ====================

  // 친구 요청 보내기
  Future<void> sendFriendRequest(FriendRequest request) async {
    await _db.collection('friendRequests').doc(request.id).set(request.toJson());
  }

  // 친구 요청 수락
  Future<void> acceptFriendRequest(String requestId, String fromUserId, String toUserId) async {
    final batch = _db.batch();

    // 요청 상태 업데이트
    batch.update(
      _db.collection('friendRequests').doc(requestId),
      {'status': FriendRequestStatus.accepted.name},
    );

    // 양쪽 사용자의 friendIds에 추가
    batch.update(
      _db.collection('users').doc(fromUserId),
      {
        'friendIds': FieldValue.arrayUnion([toUserId])
      },
    );

    batch.update(
      _db.collection('users').doc(toUserId),
      {
        'friendIds': FieldValue.arrayUnion([fromUserId])
      },
    );

    await batch.commit();
  }

  // 친구 요청 거절
  Future<void> rejectFriendRequest(String requestId) async {
    await _db.collection('friendRequests').doc(requestId).update({
      'status': FriendRequestStatus.rejected.name,
    });
  }

  // 받은 친구 요청 목록
  Stream<List<FriendRequest>> receivedFriendRequests(String userId) {
    return _db
        .collection('friendRequests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromJson(doc.data()))
            .toList());
  }

  // ==================== 챌린지 관련 ====================

  // 챌린지 생성
  Future<void> createChallenge(Challenge challenge) async {
    await _db.collection('challenges').doc(challenge.id).set(challenge.toJson());
  }

  // 챌린지 업데이트
  Future<void> updateChallenge(Challenge challenge) async {
    await _db.collection('challenges').doc(challenge.id).update(challenge.toJson());
  }

  // 챌린지 삭제
  Future<void> deleteChallenge(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).delete();
  }

  // 챌린지 가져오기
  Future<Challenge?> getChallenge(String challengeId) async {
    final doc = await _db.collection('challenges').doc(challengeId).get();
    if (doc.exists) {
      return Challenge.fromJson(doc.data()!);
    }
    return null;
  }

  // 전체 챌린지 목록 (공개만)
  Stream<List<Challenge>> allPublicChallenges() {
    return _db
        .collection('challenges')
        .where('isPrivate', isEqualTo: false)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromJson(doc.data()))
            .toList());
  }

  // 모든 챌린지 (공개 + 비밀 기본정보)
  Stream<List<Challenge>> allChallenges() {
    return _db
        .collection('challenges')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromJson(doc.data()))
            .toList());
  }

  // 내가 참여 중인 챌린지
  Stream<List<Challenge>> myChallenges(String userId) {
    return _db
        .collection('challenges')
        .where('participantIds', arrayContains: userId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Challenge.fromJson(doc.data()))
            .toList());
  }

  // 챌린지 참가 신청
  Future<void> requestJoinChallenge(String challengeId, String userId) async {
    await _db.collection('challenges').doc(challengeId).update({
      'pendingParticipantIds': FieldValue.arrayUnion([userId]),
    });
  }

  // 챌린지 참가 승인
  Future<void> approveParticipant(String challengeId, String userId) async {
    final batch = _db.batch();
    final challengeRef = _db.collection('challenges').doc(challengeId);

    batch.update(challengeRef, {
      'pendingParticipantIds': FieldValue.arrayRemove([userId]),
      'participantIds': FieldValue.arrayUnion([userId]),
    });

    await batch.commit();
  }

  // 챌린지 참가 거절
  Future<void> rejectParticipant(String challengeId, String userId) async {
    await _db.collection('challenges').doc(challengeId).update({
      'pendingParticipantIds': FieldValue.arrayRemove([userId]),
    });
  }

  // ==================== 입금 기록 관련 ====================

  // 입금 기록 생성
  Future<void> createPaymentRecord(PaymentRecord record) async {
    await _db.collection('paymentRecords').doc(record.id).set(record.toJson());
  }

  // 입금 확인
  Future<void> confirmPayment(String recordId) async {
    await _db.collection('paymentRecords').doc(recordId).update({
      'status': PaymentStatus.completed.name,
      'confirmedAt': DateTime.now().toIso8601String(),
    });
  }

  // 챌린지별 입금 기록
  Stream<List<PaymentRecord>> challengePaymentRecords(String challengeId) {
    return _db
        .collection('paymentRecords')
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentRecord.fromJson(doc.data()))
            .toList());
  }

  // 사용자별 입금 기록 (벌금 현황)
  Stream<List<PaymentRecord>> userPaymentRecords(String userId) {
    return _db
        .collection('paymentRecords')
        .where('memberId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentRecord.fromJson(doc.data()))
            .toList());
  }
}

