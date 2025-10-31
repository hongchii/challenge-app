# Firebase 설정 가이드

챌린지 앱을 실행하기 위해서는 Firebase 프로젝트 설정이 필요합니다.

## ⚠️ 다른 컴퓨터에서 클론한 경우

이 저장소는 보안상의 이유로 Firebase 설정 파일들이 `.gitignore`에 포함되어 있습니다:
- `android/app/google-services.json` ⚠️ API 키 포함
- `lib/firebase_options.dart` ⚠️ API 키 포함
- `firebase.json`

**다른 컴퓨터에서 작업하려면:**

1. **방법 1 (권장)**: `flutterfire configure` 명령어로 자동 생성
   - 아래 "5. FlutterFire 설정" 섹션 참조
   - 가장 간단하고 안전한 방법입니다

2. **방법 2**: Firebase Console에서 수동 다운로드
   - 아래 각 플랫폼별 설정 섹션 참조

## 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름 입력 (예: challenge-app)
4. Google 애널리틱스 설정 (선택사항)
5. 프로젝트 생성 완료

## 2. Firebase CLI 설치

```bash
npm install -g firebase-tools
```

## 3. FlutterFire CLI 설치

```bash
dart pub global activate flutterfire_cli
```

## 4. Firebase 로그인

```bash
firebase login
```

## 5. FlutterFire 설정 (자동)

프로젝트 루트에서 실행:

```bash
flutterfire configure
```

- 프로젝트 선택
- 플랫폼 선택 (Android, iOS, Web 등)
- 자동으로 `firebase_options.dart` 파일이 생성됩니다

## 6. Firebase 서비스 활성화

### 6.1 Authentication (인증)

1. Firebase Console > Authentication
2. "시작하기" 클릭
3. "이메일/비밀번호" 로그인 방법 활성화
4. 저장

### 6.2 Cloud Firestore (데이터베이스)

1. Firebase Console > Firestore Database
2. "데이터베이스 만들기" 클릭
3. "테스트 모드로 시작" 선택 (개발용)
4. 위치 선택 (asia-northeast3 - 서울 권장)
5. 프로덕션 환경에서는 보안 규칙 설정 필요!

#### 보안 규칙 예시 (개발용):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자 문서
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // 챌린지 문서
    match /challenges/{challengeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.creatorId || 
         request.auth.uid in resource.data.participantIds);
      allow delete: if request.auth != null && 
        request.auth.uid == resource.data.creatorId;
    }
    
    // 친구 요청 문서
    match /friendRequests/{requestId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.fromUserId || 
         request.auth.uid == resource.data.toUserId);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        request.auth.uid == resource.data.toUserId;
    }
    
    // 입금 기록 문서
    match /paymentRecords/{recordId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
  }
}
```

### 6.3 Storage (저장소)

1. Firebase Console > Storage
2. "시작하기" 클릭
3. 보안 규칙 선택
4. 위치 선택

#### 보안 규칙 예시:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /verification_images/{challengeId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 7. Android 설정

1. Firebase Console에서 Android 앱 추가
2. 패키지 이름: `com.hong.challenge` (또는 실제 패키지명)
3. `google-services.json` 다운로드
4. `android/app/` 폴더에 복사
5. `android/build.gradle.kts`에 classpath 추가:

```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

6. `android/app/build.gradle.kts` 하단에 추가:

```kotlin
apply(plugin = "com.google.gms.google-services")
```

## 8. iOS 설정

1. Firebase Console에서 iOS 앱 추가
2. 번들 ID: `com.hong.challenge`
3. `GoogleService-Info.plist` 다운로드
4. Xcode에서 `ios/Runner/` 폴더에 추가
5. Xcode 프로젝트에서 파일이 target에 포함되었는지 확인

## 9. 패키지 설치

```bash
flutter pub get
```

## 10. 앱 실행

```bash
flutter run
```

## 문제 해결

### FlutterFire CLI가 없다는 오류

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Firebase 초기화 오류

- `firebase_options.dart` 파일이 생성되었는지 확인
- Firebase 프로젝트 설정이 올바른지 확인
- `flutterfire configure` 재실행

### Android 빌드 오류

- `google-services.json` 파일 위치 확인
- Gradle 버전 확인
- `flutter clean` 후 재빌드

## 테스트 계정

개발 중에는 테스트 이메일 계정을 만들어 사용하세요:

```
test1@test.com / test123
test2@test.com / test123
```

## 프로덕션 배포 전 체크리스트

- [ ] Firestore 보안 규칙 설정
- [ ] Storage 보안 규칙 설정
- [ ] Authentication 이메일 인증 활성화
- [ ] 앱 버전 관리
- [ ] 에러 로깅 설정
- [ ] 성능 모니터링 설정

---

더 자세한 내용은 [FlutterFire 공식 문서](https://firebase.flutter.dev/)를 참조하세요.

