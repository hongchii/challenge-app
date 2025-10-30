# 챌린지 앱 - 완성 가이드

## 🎉 구현된 기능

### ✅ 완료된 기능

1. **인증 시스템**
   - 이메일 회원가입/로그인
   - 프로필 설정 (닉네임, 프로필 사진)
   - 프로필 수정, 비밀번호 변경

2. **챌린지 관리**
   - 챌린지 생성 (공개/비밀, 최대정원 설정)
   - 전체 챌린지 목록
   - 내 챌린지 목록
   - 챌린지 상세 정보

3. **친구 시스템**
   - 닉네임으로 친구 검색
   - 친구 요청 보내기/받기
   - 친구 요청 수락/거절
   - 친구 목록 관리

4. **마이페이지**
   - 프로필 보기/수정
   - 벌금 현황 조회
   - 로그아웃

5. **벌금 시스템**
   - 기본 벌금 + 추가 벌금 (없음/이자율/고정금액)
   - 자동 벌금 계산
   - 입금 기록 관리

## 📋 추가 구현이 필요한 기능

다음 기능들은 기본 구조만 완성되었으며, 추가 구현이 필요합니다:

### 1. 챌린지 참가 시스템

`lib/screens/challenge_detail_screen.dart`에 추가 필요:

```dart
// 공개 챌린지 참가 버튼
ElevatedButton(
  onPressed: () async {
    final firestoreService = FirestoreService();
    await firestoreService.updateChallenge(
      challenge.copyWith(
        participantIds: [...challenge.participantIds, currentUserId],
      ),
    );
  },
  child: const Text('참가하기'),
)

// 비밀 챌린지 참가 신청 버튼
ElevatedButton(
  onPressed: () async {
    await firestoreService.requestJoinChallenge(challenge.id, currentUserId);
  },
  child: const Text('참가 신청'),
)

// 그룹장만 보이는 승인 대기 목록
if (challenge.creatorId == currentUserId && challenge.pendingParticipantIds.isNotEmpty) {
  // 승인 대기자 목록 표시
  // approveParticipant() / rejectParticipant() 호출
}
```

### 2. 입금 완료 및 확인 시스템

`lib/screens/penalty_screen.dart`에 추가 필요:

```dart
// 참가자용 "입금 완료" 버튼
ElevatedButton(
  onPressed: () async {
    final paymentRecord = PaymentRecord(
      id: uuid.v4(),
      challengeId: challengeId,
      memberId: currentUserId,
      amount: penaltyAmount,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
    );
    await firestoreService.createPaymentRecord(paymentRecord);
  },
  child: const Text('입금 완료'),
)

// 그룹장용 "입금 확인" 버튼
IconButton(
  onPressed: () async {
    await firestoreService.confirmPayment(paymentRecord.id);
  },
  icon: const Icon(Icons.check),
)
```

### 3. 인증 시스템 완성

`lib/screens/add_verification_screen.dart` Firebase 연동:

```dart
Future<void> _submitVerification() async {
  final firestoreService = FirestoreService();
  
  // 이미지를 Storage에 업로드
  String? imageUrl;
  if (_imagePath != null) {
    final storageService = StorageService();
    imageUrl = await storageService.uploadVerificationImage(
      File(_imagePath!),
      widget.challengeId,
    );
  }
  
  // Verification 생성 및 저장
  final verification = Verification(
    id: uuid.v4(),
    memberId: _selectedMemberId!,
    dateTime: DateTime.now(),
    imagePath: imageUrl,
    note: _noteController.text.trim(),
  );
  
  // Challenge 업데이트
  final challenge = await firestoreService.getChallenge(widget.challengeId);
  final updatedChallenge = challenge!.copyWith(
    verifications: [...challenge.verifications, verification],
  );
  await firestoreService.updateChallenge(updatedChallenge);
}
```

## 🚀 실행 방법

### 1. Firebase 설정

`FIREBASE_SETUP.md` 파일을 참조하여 Firebase 프로젝트를 설정하세요.

**필수 단계:**
```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 설정 (자동)
flutterfire configure
```

### 2. 패키지 설치

```bash
flutter pub get
```

### 3. 앱 실행

```bash
flutter run
```

## 📱 테스트 시나리오

### 1단계: 회원가입 및 로그인
1. 앱 실행
2. "회원가입" 클릭
3. 정보 입력 및 가입
4. 로그인

### 2단계: 친구 추가
1. 마이페이지 > 친구 관리
2. 친구 검색 아이콘 클릭
3. 닉네임으로 검색
4. 친구 신청

### 3단계: 챌린지 생성
1. 전체 챌린지 탭
2. "새 챌린지" 버튼
3. 정보 입력 (공개/비밀, 최대정원 선택)
4. 챌린지 만들기

### 4단계: 챌린지 참가 (추가 구현 필요)
1. 전체 챌린지에서 챌린지 선택
2. "참가하기" 또는 "참가 신청"

### 5단계: 인증하기 (추가 구현 필요)
1. 내 챌린지 선택
2. "인증하기" 버튼
3. 사진 선택 및 업로드

## 🔧 주요 파일 구조

```
lib/
├── main.dart                          # 앱 진입점
├── firebase_options.dart              # Firebase 설정 (자동생성)
├── models/                            # 데이터 모델
│   ├── user_model.dart
│   ├── challenge.dart
│   ├── member.dart
│   ├── verification.dart
│   ├── penalty.dart
│   ├── friend_request.dart
│   └── payment_record.dart
├── services/                          # 서비스 레이어
│   ├── auth_service.dart             # 인증
│   ├── firestore_service.dart        # 데이터베이스
│   └── storage_service.dart          # 파일 저장
├── providers/                         # 상태 관리
│   ├── auth_provider.dart
│   └── challenge_provider.dart
└── screens/                           # UI 화면
    ├── auth/                          # 인증 관련
    │   ├── login_screen.dart
    │   └── signup_screen.dart
    ├── main/                          # 메인 탭
    │   ├── main_navigation.dart
    │   ├── all_challenges_screen.dart
    │   ├── my_challenges_screen.dart
    │   └── my_page_screen.dart
    ├── friends/                       # 친구 관리
    │   ├── friends_screen.dart
    │   └── search_friends_screen.dart
    ├── profile/                       # 프로필
    │   ├── edit_profile_screen.dart
    │   └── penalty_history_screen.dart
    ├── create_challenge_screen.dart   # 챌린지 생성
    ├── challenge_detail_screen.dart   # 챌린지 상세
    ├── add_verification_screen.dart   # 인증하기
    └── penalty_screen.dart            # 벌금 계산
```

## 🎨 디자인 시스템

토스 스타일의 디자인을 적용했습니다:

- **메인 컬러**: #3182F6 (토스 블루)
- **배경색**: #F9FAFB
- **성공**: #17C964
- **에러**: #FF5247
- **경고**: #FF9800

## 📝 다음 단계

1. **Firebase 설정 완료**
2. **테스트 및 버그 수정**
3. **나머지 기능 구현**
   - 챌린지 참가/승인
   - 입금 완료/확인
   - 인증 Firebase 연동
4. **UI/UX 개선**
5. **프로덕션 배포 준비**

## 💡 유용한 명령어

```bash
# 패키지 설치
flutter pub get

# 앱 실행
flutter run

# 빌드 (릴리즈)
flutter build apk --release  # Android
flutter build ios --release  # iOS

# 클린 빌드
flutter clean
flutter pub get
flutter run

# 코드 분석
flutter analyze

# Firebase 재설정
flutterfire configure
```

## 🐛 문제 해결

### Firebase 초기화 오류
```bash
flutterfire configure
```

### Gradle 오류 (Android)
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### 패키지 버전 충돌
```bash
flutter pub upgrade
```

---

**제작**: 2025
**기술 스택**: Flutter, Firebase, Provider

