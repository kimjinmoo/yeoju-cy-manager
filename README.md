# 여주자전거여행-관리자 (`yeoju_cy_manager`)

**여주자전거여행**의 **MiniPos 시디키** 및 **간편서명(Sign) 라이선스 키**를 모바일·태블릿·데스크톱에서 통합 관리하기 위한 순수 Flutter 네이티브 관리자 앱입니다.

---

## 주요 기능

- **관리자 인증**: 이메일/아이디 로그인 및 Google 네이티브 로그인 (`ADMIN` / `YEOJU_CYCLE_ADMIN` 권한 검증, Refresh Token 자동 갱신)
- **MiniPos & 간편서명(Sign) 통합 관리**:
  - 상태별 요약 KPI 스트립 (전체, 사용 대기, 사용중, 만료 임박, 사용 중지/만료)
  - 키워드·상태·키 구분(판매/테스트)·판매처 필터링 및 페이지네이션
  - 시디키 일괄 발급, 메타데이터 수정, 사용 중지/정상 재개, 단말기 연결 해제, 삭제, 만료 배치 점검
  - 발급 키 클립보드 복사 및 전달 URL 네이티브 공유
- **변경 이력 및 판매 통계**:
  - 서비스 전체 및 개별 키 단위 변경 이력 타임라인 조회
  - 최근 3개월 MiniPos · 간편서명 일별 판매 추이 차트 및 상세 내역

---

## 스토어 심사(Google Play / App Store) 테스트 계정 안내

스토어 심사 과정에서 실제 운영 데이터(고객·판매·라이선스 키)가 노출되지 않도록, **심사용 테스트 계정으로 로그인 시 운영 서버와 완전히 격리된 로컬 샌드박스 환경으로 동작**합니다.

| 항목 | 값 |
|------|----|
| **아이디 (ID)** | `test` |
| **비밀번호 (PW)** | `xptmxm1!` |
| **동작 방식** | 운영 API 서버에 요청하지 않고 앱 내부 인메모리 샌드박스 데이터로 동작 |

### 심사용 샌드박스 환경에서 테스트 가능한 기능
1. 로그인 화면에서 **아이디/이메일**에 `test`, **비밀번호**에 `xptmxm1!` 입력 후 **이메일로 로그인** 선택
2. **MiniPos / 간편서명** 탭에서 샘플 라이선스 키 목록 조회, 검색, 상태·구분·판매처 필터 확인
3. **시디키 발급** 시트에서 판매키/테스트키 일괄 발급 및 결과 확인(로컬 샌드박스 반영)
4. 개별 키 카드의 수정, 중지/재개, 기기 해제, 이력 확인, 만료 배치 점검 실행
5. **판매통계** 탭에서 최근 일별 판매 추이 차트 및 상세 테이블 확인
6. 우측 상단 계정 아이콘 → **로그아웃** 시 샌드박스 세션 초기화 및 로그인 화면 복귀

---

## 개발 및 빌드 환경

- **Flutter**: `3.44.9` / **Dart**: `^3.12.2`
- **서버 환경 주입 (`--dart-define`)**:
  ```bash
  # 운영 환경 (기본값)
  flutter run

  # 로컬 개발 서버 연동
  flutter run --dart-define=ENV=local --dart-define=API_BASE_URL=http://10.0.2.2:8010
  ```

### 정적 분석 및 테스트
```bash
flutter analyze
flutter test
```

---

## Google Play 광고 ID(`AD_ID`) 및 Google Analytics 설정

- **광고 ID 권한**: Android 13(API 33) 이상 Google Play 정책에 맞춰 [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)에 `com.google.android.gms.permission.AD_ID` 권한이 선언되어 있습니다.
- **Firebase Google Analytics**: `firebase_core` · `firebase_analytics` 연동 구조가 포함되어 있으며, Firebase 설정 파일이 없는 상태에서도 앱이 크래시 없이 안전하게 동작합니다. 실제 데이터 수집을 활성화하려면 다음 중 한 가지를 적용하세요.
  1. Firebase 콘솔에서 앱 등록 후 `android/app/google-services.json` (Android) / `ios/Runner/GoogleService-Info.plist` (iOS) 추가 (`google-services.json` 존재 시 Gradle `com.google.gms.google-services` 플러그인 자동 적용)
  2. 또는 빌드 시 `--dart-define=FIREBASE_API_KEY=...` (`FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, 선택 `FIREBASE_MEASUREMENT_ID`) 주입

---

## 마켓 등록 리소스 (`markets/`)

Google Play Console 및 App Store Connect 제출용 아이콘, 그래픽 배너, 폰(`1080×2400`)·태블릿(`2560×1600`) 스크린샷은 [`markets/`](markets/README.md) 폴더에 정리되어 있습니다.
