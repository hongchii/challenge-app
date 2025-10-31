# 챌린지 앱 🏆

친구들과 함께하는 챌린지 & 벌금 관리 앱

## 📱 소개

친구들과 함께 챌린지를 만들고, 인증하고, 벌금을 관리하는 소셜 챌린지 플랫폼입니다.
"무지출 챌린지", "주3회 운동하기" 등 다양한 챌린지를 만들고 친구들과 함께 목표를 달성하세요!

## ✨ 주요 기능

### 🔐 인증 시스템
- 이메일 회원가입 및 로그인
- 프로필 설정 및 관리 (닉네임, 프로필 사진)
- 프로필 수정 및 비밀번호 변경
- 실시간 인증 상태 관리

### 🎯 챌린지 관리
- 유연한 빈도 설정:
  - 매일 인증
  - 주 N회 인증
  - 월 N회 인증
- 종료일 미정 옵션 지원
- 전체 챌린지 / 내 챌린지 구분
- 챌린지 상세 정보 확인
- 챌린지 삭제 (생성자만 가능)
- 멤버 추가 및 관리

### 🎉 챌린지 초대 시스템
- 챌린지 초대장 발송
- 초대 수락/거절
- 초대 알림 관리

### 👥 친구 시스템
- 닉네임으로 친구 검색
- 친구 요청 보내기/받기
- 친구 요청 수락/거절
- 친구 목록 관리 및 확인

### 📸 인증 시스템
- 사진 인증 (갤러리/카메라)
- 인증 메모 작성
- 인증 내역 상세 보기
- 실시간 인증 업데이트

## 🎨 디자인

**토스(Toss) 스타일 UI/UX** 적용
- 메인 컬러: #3182F6 (토스 블루)
- 깔끔한 카드형 디자인
- 직관적인 네비게이션
- Material 3 디자인 시스템

## 🛠 기술 스택

- **Frontend**: Flutter 3.x
- **State Management**: Provider
- **Backend**: Firebase
  - Authentication (이메일/비밀번호)
  - Cloud Firestore (데이터베이스)
  - Cloud Storage (이미지 저장)
- **이미지 처리**: image_picker
- **날짜 포맷**: intl

## 🚀 시작하기

### 1. 사전 요구사항

- Flutter SDK 3.0 이상
- Dart SDK 3.0 이상
- Firebase 프로젝트

### 2. 설치

```bash
# 저장소 클론
git clone https://github.com/hongchii/challenge-app.git
cd challenge-app

# 패키지 설치
flutter pub get
```

### 3. Firebase 설정

⚠️ **중요**: 이 저장소는 보안상의 이유로 Firebase 설정 파일들이 `.gitignore`에 포함되어 있습니다.  
다른 컴퓨터에서 클론한 경우, 아래 방법 중 하나로 Firebase 설정 파일을 생성해야 합니다.

**방법 1: FlutterFire CLI 사용 (권장)**

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# PATH 설정 (Windows)
# PowerShell: $env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
# CMD: set PATH=%PATH%;%LOCALAPPDATA%\Pub\Cache\bin

# Firebase 자동 설정
flutterfire configure
```

이 명령어가 자동으로 다음 파일들을 생성합니다:
- `lib/firebase_options.dart` ⚠️ API 키 포함
- `android/app/google-services.json` (Android 앱이 있다면) ⚠️ API 키 포함

**방법 2: Firebase Console에서 수동 다운로드**

자세한 설정 방법은 [FIREBASE_SETUP.md](FIREBASE_SETUP.md)를 참조하세요.

### 4. 실행

```bash
# Windows
flutter run -d windows

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## 📖 상세 가이드

- **Firebase 설정**: [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
- **실행 및 기능 구현**: [README_SETUP.md](README_SETUP.md)

## 📂 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점
├── firebase_options.dart              # Firebase 설정
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
    ├── auth/                          # 로그인/회원가입
    ├── main/                          # 메인 탭
    ├── friends/                       # 친구 관리
    ├── profile/                       # 프로필
    └── ...
```

## 🔧 개발 모드 (Firebase 없이 테스트)

Firebase 설정 전에 UI만 테스트하려면:

1. `lib/main.dart`의 주석을 확인
2. Mock Provider가 자동으로 활성화되어 있음
3. 실제 데이터는 저장되지 않지만 UI는 확인 가능

## 📝 라이센스

이 프로젝트는 MIT 라이센스를 따릅니다.

## 👤 개발자

**hongchii**
- GitHub: [@hongchii](https://github.com/hongchii)

## 🙏 감사의 말

- Flutter 팀
- Firebase 팀
- Toss 디자인 시스템에서 영감을 받았습니다

---

**⭐ 이 프로젝트가 마음에 드셨다면 Star를 눌러주세요!**
