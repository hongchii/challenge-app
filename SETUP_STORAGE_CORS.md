# Firebase Storage CORS 설정 가이드

Flutter Web에서 Firebase Storage 이미지를 로드하려면 CORS 설정이 필요합니다.

## 방법 1: Firebase Console 사용 (추천)

1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. 프로젝트 `challenge-app-d13ff` 선택
3. 왼쪽 메뉴에서 **Storage** 선택
4. 상단의 **Rules** 탭 클릭
5. **CORS** 버튼 클릭 (또는 Storage 설정에서 CORS 찾기)
6. 다음 JSON을 입력:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "PUT", "POST", "DELETE", "HEAD"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"]
  }
]
```

7. **저장** 클릭

## 방법 2: Firebase CLI + gsutil 사용

### 1. Google Cloud SDK 설치
- [Google Cloud SDK 설치 페이지](https://cloud.google.com/sdk/docs/install)에서 설치
- Windows: 설치 후 PowerShell 재시작

### 2. 인증 설정
```bash
gcloud auth login
```

### 3. CORS 설정 적용
```bash
gsutil cors set cors.json gs://challenge-app-d13ff.firebasestorage.app
```

## 방법 3: Google Cloud Shell 사용 (추천 - 터미널 설치 불필요!)

Google Cloud SDK를 설치하지 않고도 Google Cloud Console 웹 브라우저의 Cloud Shell을 통해 CORS 설정 가능합니다.

### Step 1: Firebase Storage 초기화 (버킷 생성)

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 `challenge-app-d13ff` 선택
3. 왼쪽 메뉴에서 **Storage** 클릭
4. **Get started** 또는 **시작하기** 버튼 클릭
5. **Production mode** 선택 (보안 규칙: 인증된 사용자만 접근 가능)
6. Firebase Hosting 기본 위치 선택 (예: `asia-northeast1`)
7. **Done** 클릭

Storage 버킷이 자동으로 생성됩니다!

### Step 2: CORS 설정 (Google Cloud Shell 사용)

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 상단 오른쪽에 있는 **Cloud Shell 아이콘** (터미널 모양) 클릭
   - 브라우저 창에서 하단에 Cloud Shell 창이 열립니다
3. Cloud Shell에서 다음 명령어 실행:

```bash
echo '[{"origin":["*"],"method":["GET","PUT","POST","DELETE","HEAD"],"maxAgeSeconds":3600,"responseHeader":["Content-Type","Access-Control-Allow-Origin"]}]' > cors.json

gsutil cors set cors.json gs://challenge-app-d13ff.firebasestorage.app
```

4. 성공 메시지가 나오면 완료!

## Storage 보안 규칙 설정

Firebase Console에서 인증된 사용자의 파일 업로드/다운로드를 허용해야 합니다:

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 `challenge-app-d13ff` 선택
3. **Storage** > **Rules** 탭 선택
4. 다음 규칙 입력:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 프로필 이미지: 누구나 읽기 가능, 본인만 업로드 가능
    match /profile_images/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // 인증 이미지: 인증된 사용자만 읽기/업로드 가능
    match /verification_images/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

5. **Publish** 클릭

## 확인

설정 적용 후:
1. Firebase Console > Storage > Rules 탭에서 규칙 확인
2. Google Cloud Console에서 CORS 설정 확인
3. 브라우저 개발자 도구(F12) > Network 탭에서 이미지 로드 확인
4. 에러가 없으면 설정 완료!

## 주의사항

- `origin: ["*"]`는 개발 환경에 적합하며, 프로덕션에서는 특정 도메인을 지정하는 것이 보안상 좋습니다.
- CORS 설정 변경 후 즉시 적용되지만, 일부 경우 캐시로 인해 몇 분이 걸릴 수 있습니다.
- 브라우저 캐시를 지우고 강력 새로고침(Ctrl+Shift+R)을 시도해보세요.

