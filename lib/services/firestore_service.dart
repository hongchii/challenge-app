import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/challenge.dart';
import '../models/member.dart';
import '../models/friend_request.dart';
import '../models/payment_record.dart';
import '../models/challenge_invitation.dart';

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

  // 이메일 중복 확인
  Future<bool> isEmailExists(String email) async {
    final snapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }

  // 닉네임 중복 확인
  Future<bool> isNicknameExists(String nickname) async {
    final snapshot = await _db
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
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

  // 챌린지 삭제
  Future<void> deleteChallenge(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).delete();
  }

  // 챌린지 업데이트
  Future<void> updateChallenge(Challenge challenge) async {
    await _db.collection('challenges').doc(challenge.id).update(challenge.toJson());
  }

  // 인증 추가
  Future<void> addVerification(String challengeId, dynamic verification) async {
    final challenge = await getChallenge(challengeId);
    if (challenge != null) {
      final updatedChallenge = challenge.copyWith(
        verifications: [...challenge.verifications, verification],
      );
      await updateChallenge(updatedChallenge);
    }
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

  // 특정 챌린지 상세 정보 스트림
  Stream<Challenge?> challengeStream(String challengeId) {
    return _db
        .collection('challenges')
        .doc(challengeId)
        .snapshots()
        .asyncMap((doc) async {
          if (doc.exists) {
            final data = doc.data()!;
            
            // participantIds를 사용해서 members 생성
            final List<String> participantIds = List<String>.from(data['participantIds'] ?? []);
            final String creatorId = data['creatorId'] ?? '';
            
            // Firestore에 있는 members와 participantIds를 병합
            final existingMembers = (data['members'] as List?)
                ?.map((m) => Member.fromJson(m))
                .toList() ?? [];
            
            // participantIds에 있지만 members에 없는 사용자를 추가
            final memberMap = {for (var m in existingMembers) m.id: m};
            for (final participantId in participantIds) {
              if (!memberMap.containsKey(participantId)) {
                // member 데이터가 없으면 ID만으로 생성
                memberMap[participantId] = Member(
                  id: participantId,
                  name: participantId, // 임시 이름, 나중에 사용자 정보를 가져와서 업데이트
                  isLeader: participantId == creatorId,
                );
              }
            }
            
            // Firestore의 기존 members를 participantIds 순서와 함께 사용
            final allParticipantIds = [...participantIds];
            
            // members에는 있지만 participantIds에 없는 경우 추가 (완전성을 위해)
            for (final member in existingMembers) {
              if (!allParticipantIds.contains(member.id)) {
                allParticipantIds.add(member.id);
              }
            }
            
            // 생성자도 participants에 포함되어 있는지 확인, 없으면 추가
            if (creatorId.isNotEmpty && !allParticipantIds.contains(creatorId)) {
              allParticipantIds.insert(0, creatorId);
            }
            
            // 모든 참가자의 사용자 정보를 한 번에 가져오기
            final List<Future<UserModel?>> userFutures = allParticipantIds
                .map((id) => getUser(id))
                .toList();
            final List<UserModel?> users = await Future.wait(userFutures);
            
            // 최종 members 리스트 생성 (participantIds 순서대로)
            final List<Member> finalMembers = allParticipantIds
                .asMap()
                .entries
                .map((entry) {
                  final id = entry.value;
                  final user = users[entry.key];
                  
                  // 항상 사용자 정보로 업데이트 (닉네임이 ID면 실제 닉네임으로 교체)
                  final displayName = user?.nickname ?? id;
                  
                  return Member(
                    id: id,
                    name: displayName, // 사용자 닉네임 또는 ID
                    isLeader: id == creatorId,
                  );
                })
                .toList();
            
            // data를 복사하고 members를 업데이트
            final updatedData = Map<String, dynamic>.from(data);
            updatedData['members'] = finalMembers.map((m) => m.toJson()).toList();
            
            return Challenge.fromJson(updatedData);
          }
          return null;
        });
  }

  // 내가 참여 중인 챌린지
  Stream<List<Challenge>> myChallenges(String userId) {
    return _db
        .collection('challenges')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs
              .map((doc) => Challenge.fromJson(doc.data()))
              .toList();
          // 클라이언트에서 정렬
          challenges.sort((a, b) => b.startDate.compareTo(a.startDate));
          return challenges;
        });
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
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map((doc) => PaymentRecord.fromJson(doc.data()))
              .toList();
          // 클라이언트에서 정렬
          records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return records;
        });
  }

  // ==================== 챌린지 초대 관련 ====================

  // 챌린지 초대 보내기
  Future<void> sendChallengeInvitation(ChallengeInvitation invitation) async {
    await _db.collection('challengeInvitations').doc(invitation.id).set(invitation.toJson());
  }

  // 받은 챌린지 초대 목록 (실시간)
  Stream<List<ChallengeInvitation>> challengeInvitationsStream(String userId) {
    return _db
        .collection('challengeInvitations')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final invitations = snapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return ChallengeInvitation.fromJson(data);
              })
              .toList();
          // 클라이언트에서 정렬 (복합 인덱스 불필요)
          invitations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return invitations;
        });
  }

  // 챌린지 초대 수락
  Future<void> acceptChallengeInvitation(String invitationId, String challengeId, String userId) async {
    final batch = _db.batch();

    // 초대 상태 업데이트
    batch.update(
      _db.collection('challengeInvitations').doc(invitationId),
      {'status': 'accepted'},
    );

    // 챌린지의 participantIds에 추가
    batch.update(
      _db.collection('challenges').doc(challengeId),
      {
        'participantIds': FieldValue.arrayUnion([userId])
      },
    );

    await batch.commit();
  }

  // 챌린지 초대 거절
  Future<void> rejectChallengeInvitation(String invitationId) async {
    await _db.collection('challengeInvitations').doc(invitationId).update({
      'status': 'rejected',
    });
  }

  // 받은 챌린지 초대 개수
  Future<int> getPendingInvitationsCount(String userId) async {
    final snapshot = await _db
        .collection('challengeInvitations')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();
    
    return snapshot.docs.length;
  }
}

