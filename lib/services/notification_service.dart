import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/challenge.dart';
import '../models/verification.dart';
import '../models/verification_notification.dart';
import '../screens/verification_history_screen.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirestoreService _firestoreService = FirestoreService();
  bool _initialized = false;
  String? _currentUserId;
  final Map<String, StreamSubscription> _challengeSubscriptions = {};
  final Map<String, List<String>> _knownVerificationIds = {}; // 챌린지별로 알려진 인증 ID 저장

  // 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🔔 알림 서비스 초기화 시작...');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    debugPrint('🔔 알림 플러그인 초기화 결과: $initialized');

    // Android 알림 채널 생성
    const androidChannel = AndroidNotificationChannel(
      'challenge_verifications',
      '챌린지 인증 알림',
      description: '챌린지 인증 내역 알림',
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Android 13 이상에서 알림 권한 요청
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      debugPrint('🔔 Android 알림 권한 요청 결과: $granted');
    }

    // iOS 알림 권한 요청
    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🔔 iOS 알림 권한 요청 결과: $granted');
    }

    _initialized = true;
    debugPrint('✅ 알림 서비스 초기화 완료');
  }

  // 알림 클릭 핸들러
  void _onNotificationTapped(NotificationResponse response) {
    // payload에서 challengeId를 추출
    final challengeId = response.payload;
    if (challengeId != null) {
      // 전역 네비게이터 키를 통해 화면 이동
      // main.dart에서 전역 네비게이터 키를 제공해야 함
      final navigatorKey = NotificationService.navigatorKey;
      if (navigatorKey?.currentContext != null) {
        final context = navigatorKey!.currentContext!;
        // 인증내역 화면으로 이동
        _navigateToVerificationHistory(context, challengeId);
      }
    }
  }

  // 인증내역 화면으로 이동
  Future<void> _navigateToVerificationHistory(BuildContext context, String challengeId) async {
    try {
      final challenge = await _firestoreService.getChallenge(challengeId);
      if (challenge != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _VerificationHistoryRoute(challengeId: challengeId, challenge: challenge),
          ),
        );
      }
    } catch (e) {
      debugPrint('인증내역 화면 이동 실패: $e');
    }
  }

  // 사용자별 챌린지 감지 시작
  Future<void> startListeningForVerifications(String userId) async {
    debugPrint('🔔 알림 리스너 시작 요청: $userId');
    
    if (_currentUserId == userId) {
      debugPrint('🔔 이미 같은 사용자로 리스너가 실행 중입니다.');
      return; // 이미 같은 사용자로 시작됨
    }
    
    await stopListening(); // 기존 리스너 중지
    _currentUserId = userId;
    
    debugPrint('🔔 참여 중인 챌린지 스트림 구독 시작...');
    
    // 사용자가 참여 중인 챌린지 스트림 구독
    _firestoreService.myChallenges(userId).listen(
      (challenges) {
        debugPrint('🔔 참여 중인 챌린지 업데이트: ${challenges.length}개');
        
        // 새로운 챌린지 목록
        final currentChallengeIds = challenges.map((c) => c.id).toSet();
        
        // 기존 리스너 중 불필요한 것 제거
        for (final challengeId in _challengeSubscriptions.keys.toList()) {
          if (!currentChallengeIds.contains(challengeId)) {
            _challengeSubscriptions[challengeId]?.cancel();
            _challengeSubscriptions.remove(challengeId);
            _knownVerificationIds.remove(challengeId);
          }
        }
        
        // 새 챌린지에 대한 리스너 추가
        for (final challenge in challenges) {
          if (!_challengeSubscriptions.containsKey(challenge.id)) {
            debugPrint('🔔 챌린지 리스너 추가: ${challenge.id} (${challenge.title})');
            _listenToChallengeVerifications(challenge.id, userId, challenge);
          }
        }
      },
      onError: (error) {
        debugPrint('❌ 챌린지 스트림 오류: $error');
      },
    );
  }

  // 특정 챌린지의 인증 내역 감지
  void _listenToChallengeVerifications(String challengeId, String userId, Challenge? initialChallenge) {
    debugPrint('🔔 챌린지 인증 감지 시작: $challengeId');
    
    // 초기 챌린지 데이터가 있으면 현재 인증 ID들을 알려진 목록에 추가
    if (initialChallenge != null) {
      final initialIds = initialChallenge.verifications.map((v) => v.id).toList();
      _knownVerificationIds[challengeId] = initialIds;
      debugPrint('🔔 초기 인증 ID 목록: ${initialIds.length}개');
    } else {
      _knownVerificationIds[challengeId] = [];
    }
    
    // Firestore에서 챌린지의 verifications 변경 감지
    final subscription = _firestoreService.challengeStream(challengeId).listen(
      (challenge) {
        if (challenge == null) {
          debugPrint('⚠️ 챌린지 데이터가 null입니다: $challengeId');
          return;
        }
        
        // 기존 인증 ID 목록 가져오기 또는 초기화
        final knownIds = _knownVerificationIds[challengeId] ?? [];
        
        debugPrint('🔔 챌린지 인증 업데이트 감지: ${challenge.verifications.length}개 (알려진: ${knownIds.length}개)');
        
        // 모든 인증 ID 로그 출력 (디버깅용)
        final allCurrentIds = challenge.verifications.map((v) => v.id).toList();
        debugPrint('🔔 현재 인증 ID 목록: $allCurrentIds');
        debugPrint('🔔 알려진 인증 ID 목록: $knownIds');
        
        // 새로운 인증 찾기
        final newVerifications = challenge.verifications.where((v) {
          // 본인이 올린 인증은 제외
          if (v.memberId == userId) {
            debugPrint('🔔 본인 인증 제외: ${v.id} (본인: $userId)');
            return false;
          }
          // 이미 알려진 인증은 제외
          final isNew = !knownIds.contains(v.id);
          if (isNew) {
            debugPrint('🔔 새로운 인증 발견: ${v.id} (멤버: ${v.memberId}, 본인: $userId)');
          } else {
            debugPrint('🔔 기존 인증 스킵: ${v.id}');
          }
          return isNew;
        }).toList();
        
        // 새로운 인증이 있으면 알림 표시
        if (newVerifications.isNotEmpty) {
          debugPrint('🔔 새로운 인증 ${newVerifications.length}개 발견, 알림 표시 중...');
        }
        
        for (final verification in newVerifications) {
          _showVerificationNotification(challenge, verification);
          // 알려진 ID 목록에 추가
          knownIds.add(verification.id);
        }
        
        // 알려진 ID 목록 업데이트
        _knownVerificationIds[challengeId] = knownIds;
      },
      onError: (error) {
        debugPrint('❌ 챌린지 인증 감지 오류: $error');
      },
    );
    
    _challengeSubscriptions[challengeId] = subscription;
  }

  // 인증 알림 표시 (Firestore에 저장하여 앱 내 알림으로 표시)
  Future<void> _showVerificationNotification(Challenge challenge, Verification verification) async {
    try {
      debugPrint('🔔 인증 알림 생성 시작: 챌린지=${challenge.id}, 인증=${verification.id}');
      debugPrint('🔔 참가자 목록: ${challenge.participantIds}');
      debugPrint('🔔 인증한 사용자: ${verification.memberId}');

      // 인증을 올린 사용자 정보 가져오기
      final user = await _firestoreService.getUser(verification.memberId);
      final userName = user?.nickname ?? '사용자';
      
      debugPrint('🔔 알림 내용: $userName 님이 챌린지 인증을 했습니다. (${challenge.title})');
      
      // 챌린지 참가자 목록 가져오기 (본인 제외한 다른 참가자들에게 알림)
      int notificationCount = 0;
      for (final participantId in challenge.participantIds) {
        // 본인이 올린 인증이면 본인에게는 알림을 보내지 않음 (이미 필터링됨)
        // 다른 참가자들에게만 알림 생성
        if (participantId != verification.memberId) {
          final notificationId = '${challenge.id}_${verification.id}_$participantId';
          
          final notification = VerificationNotification(
            id: notificationId,
            challengeId: challenge.id,
            challengeTitle: challenge.title,
            verificationId: verification.id,
            memberId: verification.memberId,
            memberNickname: userName,
            toUserId: participantId,
            createdAt: verification.dateTime,
            isRead: false,
          );
          
          try {
            await _firestoreService.createVerificationNotification(notification);
            notificationCount++;
            debugPrint('✅ 인증 알림 생성 완료: $participantId에게 알림 전송 (ID: $notificationId)');
          } catch (e) {
            debugPrint('❌ 인증 알림 생성 실패 ($participantId): $e');
          }
        } else {
          debugPrint('🔔 본인 인증이므로 알림 생성 스킵: $participantId');
        }
      }
      
      debugPrint('🔔 총 $notificationCount개의 인증 알림 생성 완료');
      
    } catch (e, stackTrace) {
      debugPrint('❌ 인증 알림 표시 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }

  // 리스너 중지
  Future<void> stopListening() async {
    for (final subscription in _challengeSubscriptions.values) {
      await subscription.cancel();
    }
    _challengeSubscriptions.clear();
    _knownVerificationIds.clear();
    _currentUserId = null;
  }

  // 전역 네비게이터 키 (main.dart에서 설정)
  static GlobalKey<NavigatorState>? navigatorKey;
}

// 인증내역 화면 루트 (순환 참조 방지)
class _VerificationHistoryRoute extends StatelessWidget {
  final String challengeId;
  final Challenge challenge;

  const _VerificationHistoryRoute({
    required this.challengeId,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    // verification_history_screen.dart를 동적으로 임포트
    // 순환 참조를 방지하기 위해 여기서 직접 임포트
    return VerificationHistoryScreen(
      challengeId: challengeId,
      challenge: challenge,
    );
  }
}

