# 여주자전거여행 통합 키 관리 앱 (yeoju_cy_manager) - AGENTS.md

본 문서는 `grepiu_server` 및 `console_grepiu`의 **여주자전거여행 MiniPos 시디키 관리** 및 **간편서명(Sign) 키 관리** 기능을 순수 Flutter 네이티브 UI 컴포넌트로 구현하기 위한 기본 정책 및 아키텍처 가이드입니다.

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 앱 이름 | 여주자전거여행-관리자 (`yeoju_cy_manager`) |
| 프레임워크 | Flutter 3.44.9 / Dart 3.12.2 (`^3.12.2`) |
| 패키지명 (Application ID) | `com.grepiu.yeoju_cy_manager` |
| 백엔드 서버 | `grepiu_server` (`https://conf.grepiu.com` / 로컬 `http://localhost:8010`) |
| 참고 웹 콘솔 | `console_grepiu` (`YeojuCycleAdmin`, `LicenseKeyManagement`) |
| 핵심 원칙 | **WebView 미사용**, 모든 인증 및 관리 화면은 100% Flutter 네이티브 위젯으로 구현 |

---

## 2. 기술 스택 및 의존성 (`pubspec.yaml` 기준)

모든 의존성 버전은 반드시 `pubspec.yaml`을 기준으로 일치시켜야 합니다.

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `flutter` | SDK | UI 프레임워크 (Material 3) |
| `cupertino_icons` | `^1.0.9` | 아이콘 에셋 |
| `dio` | `^5.11.1` | REST API 통신, JWT 헤더 주입 및 401 토큰 자동 갱신 인터셉터 |
| `flutter_riverpod` | `^3.5.0` | 상태 관리 및 의존성 주입 (`NotifierProvider`) |
| `go_router` | `^18.1.4` | 선언적 라우팅 및 인증/권한 리다이렉트 가드 |
| `flutter_secure_storage` | `^11.2.0` | Access/Refresh Token 및 서버 환경 설정 암호화 저장 |
| `google_sign_in` | `^7.2.0` | Google 네이티브 로그인 (`idToken` 획득 후 서버 검증 연동) |
| `intl` | `^0.20.2` | 날짜 및 숫자 포맷팅 |
| `share_plus` | `^13.3.1` | 발급 키 및 전달 URL 네이티브 공유 |
| `flutter_lints` | `^6.0.0` | 정적 분석 및 린트 규칙 (dev) |

---

## 3. 아키텍처 및 디렉토리 구조

Feature-First 계층형 아키텍처를 따릅니다. `lib/` 하위 구조 변경 시 본 섹션을 반드시 함께 업데이트합니다.

```text
lib/
├── main.dart                                  # 앱 엔트리 포인트 및 ProviderScope 초기화
├── app.dart                                   # MaterialApp.router 및 전역 테마/라우터 연결
├── core/
│   ├── config/
│   │   └── app_config.dart                    # 서버 환경(prod/local/emulator/custom), Client ID, Web 호스트 설정
│   ├── network/
│   │   ├── api_exception.dart                 # 서버 StandardResponse 기반 공통 예외 모델 및 메시지 추출
│   │   ├── auth_interceptor.dart              # Bearer 토큰 주입, 401 동시성 잠금 기반 Refresh Token 재발급
│   │   └── dio_client.dart                    # Dio 인스턴스 생성 및 설정
│   ├── router/
│   │   └── app_router.dart                    # GoRouter 라우트 정의 및 로그인/권한 가드
│   ├── storage/
│   │   └── token_storage.dart                 # flutter_secure_storage 기반 토큰·서버URL 저장소 추상화
│   ├── theme/
│   │   └── app_theme.dart                     # Apple/Console 스타일 라이트 테마, 컬러 토큰
│   └── utils/
│       └── date_formatter.dart                # 날짜/D-day 포맷터 유틸리티
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart           # 로그인(ID/PW, Google), 토큰 갱신, 내 정보 조회, 로그아웃 API
│   │   ├── domain/
│   │   │   ├── auth_state.dart                # 인증 상태(initializing, unauthenticated, authenticated, forbidden)
│   │   │   └── auth_user.dart                 # 사용자 정보 및 권한(ADMIN, YEOJU_CYCLE_ADMIN) 판별 모델
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart         # AuthNotifier 및 authProvider
│   │       └── pages/
│   │           ├── login_page.dart            # ID/PW + Google 로그인 + 서버 환경 선택 화면
│   │           ├── splash_page.dart           # 초기 자동 로그인 확인 로딩 화면
│   │           └── unauthorized_page.dart     # 관리자 권한 미보유 안내 및 계정 전환 화면
│   └── license_keys/
│       ├── data/
│       │   └── license_key_repository.dart    # MiniPos(/v1/mini-pos) 및 Sign(/v1/sign) 통합 API 저장소
│       ├── domain/
│       │   ├── license_key_models.dart        # 키, 요약통계, 페이징, 발급/수정 요청, 변경이력, 판매통계 모델
│       │   └── license_service_type.dart      # 서비스 구분 열거형(miniPos, sign) 및 엔드포인트 매핑
│       └── presentation/
│           ├── providers/
│           │   ├── license_key_provider.dart  # 키 목록/필터/요약/CRUD 상태 관리 Notifier
│           │   ├── license_history_provider.dart # 변경 이력 목록/필터 상태 관리 Notifier
│           │   └── sales_stats_provider.dart  # MiniPos/Sign 최근 3개월 판매 통계 Notifier
│           ├── utils/
│           │   └── history_diff_helper.dart   # 변경 이력 스냅샷 diff 및 액션 배지 메타데이터 생성
│           ├── widgets/
│           │   ├── kpi_summary_strip.dart     # KPI 요약 카드 스트립 (전체/대기/사용중/만료임박/중지)
│           │   ├── license_key_card.dart      # 시디키 단건 정보 및 관리 액션 카드
│           │   ├── license_filter_bar.dart    # 상태/구분/판매처 필터 및 검색 바
│           │   ├── issue_key_sheet.dart       # 시디키 일괄 발급 바텀시트 (결과 복사/공유 포함)
│           │   ├── edit_key_sheet.dart        # 시디키 메타데이터 수정 바텀시트
│           │   ├── key_history_sheet.dart     # 개별 시디키 변경 이력 타임라인 바텀시트
│           │   ├── history_list_view.dart     # 서비스 전체 변경 이력 탭 뷰
│           │   └── sales_stats_view.dart      # MiniPos & 간편서명 일별 판매 추이 차트/상세 뷰
│           └── pages/
│               ├── manager_home_page.dart     # 하단 네비게이션(MiniPos / 간편서명 / 판매통계) 메인 쉘
│               └── license_management_view.dart # 서비스별 시디키 목록·이력 통합 관리 화면
└── shared/
    └── widgets/
        ├── app_feedback.dart                  # SnackBar(성공/경고/오류) 및 확인 다이얼로그 헬퍼
        ├── empty_state_view.dart              # 빈 목록 / 오류 재시도 공통 위젯
        └── pagination_bar.dart                # 페이지네이션 컨트롤 위젯
```

---

## 4. 인증 및 보안 정책

### 4.1 API 인증 흐름 (`grepiu_server` `AuthController` 규격)
1. **ID/PW 로그인**:
   - `POST /api/v1/auth/login`
   - 필수 헤더: `X-Client-Type: mobile` (모바일 응답 바디에 `access_token`, `refresh_token`, `expires_in` 수신)
   - 요청 바디: `{"email": "...", "password": "..."}`
2. **Google 로그인**:
   - `google_sign_in` (`GoogleSignIn.instance.initialize(serverClientId: ...)` → `authenticate()`)로 `idToken` 획득
   - `POST /api/v1/auth/google-login`
   - 요청 바디: `{"idToken": "..."}`
   - 서버에서 `GoogleIdTokenVerifier`로 `client-id` audience 검증 후 `access_token`, `refresh_token` 반환
   - 데스크톱 등 `supportsAuthenticate() == false` 플랫폼에서는 지원 안내 및 ID/PW 로그인 유도
3. **사용자 정보 및 권한 검증**:
   - `GET /api/v1/auth/me` (JSON 응답; Protobuf 엔드포인트 `/api/v2/auth/me` 대신 모바일 호환 JSON 사용)
   - 헤더: `Authorization: Bearer <access_token>`
   - **허용 권한 (`SecurityConfig` 기준)**: `ADMIN` 또는 `YEOJU_CYCLE_ADMIN` 역할을 반드시 포함해야 관리 화면 진입 가능 (단, 서버 응답에 `ROLE_` 접두사가 있거나 없더라도 모두 정규화하여 판별)
4. **토큰 자동 갱신 (Refresh Token Rotation)**:
   - API 요청 중 HTTP `401` 수신 시 `POST /api/v1/auth/refresh` 호출 (`X-Client-Type: mobile`, 바디 `{"refresh_token": "..."}`)
   - 동시 다발적인 401 요청 발생 시 단일 Refresh Future로 직렬화(Lock)하여 중복 회전 방지
   - Refresh 실패 시 저장된 토큰을 모두 삭제하고 로그인 화면으로 자동 이동
5. **로그아웃**:
   - `POST /api/v1/auth/logout` (`Authorization: Bearer <access_token>`) 호출 후 로컬 토큰 및 Google 세션 정리

### 4.2 보안 준수 사항
- 토큰(`access_token`, `refresh_token`)은 반드시 `flutter_secure_storage`에만 저장하며 일반 `SharedPreferences`나 평문 파일에 저장하지 않습니다.
- 디버그 로그(`debugPrint` 등)에 비밀번호, JWT 토큰, Google `idToken` 원문을 절대 출력하지 않습니다.
- WebView를 사용한 우회 로그인 또는 웹 화면 임베딩을 금지합니다.

---

## 5. 도메인 및 API 통합 정책

### 5.1 서비스 구분 공통화 (`LicenseServiceType`)
MiniPos(`/v1/mini-pos`)와 간편서명(`/v1/sign`)은 동일한 키 스키마와 관리 API 구조를 공유합니다.
- **중복 구현 금지**: 두 도메인을 별도 화면/저장소로 복제하지 않고 `LicenseServiceType` 열거형(`miniPos`, `sign`)으로 `basePath`, 화면 라벨, 전달 URL 파라미터(`mini-pos` / `sign`)를 통합 관리합니다.
- **공통 엔드포인트**:
  - 목록 조회: `GET {basePath}` (`page`, `size`, `key`, `status`, `keyType`, `salesLocation`)
  - 요약 통계: `GET {basePath}/summary`
  - 판매처 목록: `GET {basePath}/sales-locations`
  - 키 발급: `POST {basePath}/issue`
  - 정보 수정: `PUT {basePath}/info`
  - 중지/재개: `PUT {basePath}/reject` (`key`, `yn`)
  - 기기 초기화: `POST {basePath}/device-init` (`key`)
  - 키 삭제: `DELETE {basePath}` (`key`)
  - 만료 배치 점검: `POST {basePath}/expire-batch`
  - 변경 이력 조회: `GET {basePath}/history` (`key`, `actionType`, `keyword`, `page`, `size`)
  - 일별 판매 통계: `GET {basePath}/statistics`

### 5.2 서버 응답 규격
- `StandardResponse`: `{ "code": "200", "data": ..., "message": "..." }`
- `StandardPagingResponse`: `{ "code": "200", "data": [...], "tpage": N, "tcount": N, "message": "..." }`

---

## 6. 클린코드 및 Flutter 코딩 규칙

### 6.1 네이밍 및 포맷팅
- 파일명: `snake_case.dart` (예: `license_key_card.dart`)
- 클래스/열거형/타입: `UpperCamelCase` (예: `LicenseKeyItem`)
- 변수/메서드/파라미터/상수: `lowerCamelCase` (예: `defaultPageSize`)
- `flutter analyze` 경고 및 에러 **0건** 유지 필수

### 6.2 위젯 및 상태 설계
- 모든 재사용 위젯은 `const` 생성자를 우선 사용합니다.
- 한 위젯 파일이 비대해지지 않도록(권장 300라인 이내) 카드, 필터 바, 모달 시트를 하위 위젯으로 분리합니다.
- 도메인 모델은 불변(`final` 필드, `const` 생성자, `copyWith`)으로 작성합니다.
- 비즈니스 로직 및 API 호출은 위젯(`build`) 내부에 직접 작성하지 않고 `Notifier` 및 `Repository` 계층에 위임합니다.

### 6.3 주석 및 언어 정책 (필수)
- **모든 공개 클래스, 메서드, 주요 필드에 한글 문서 주석(`///`)을 작성합니다.**
- 복잡한 비즈니스 로직(예: 토큰 재발급 동시성 제어, 만료일 계산)에는 동작 이유를 설명하는 한글 주석을 작성합니다.
- UI 텍스트, 유효성 검사 메시지, 오류 안내 문구는 모두 자연스러운 한국어로 작성합니다.

---

## 7. 환경 설정 정책 (`--dart-define`)

빌드 또는 실행 시 `--dart-define`으로 환경을 주입할 수 있으며, 미지정 시 기본값을 사용합니다.

| 키 | 설명 | 기본값 |
|----|------|--------|
| `ENV` | 실행 환경 (`prod` / `local`) | `prod` |
| `API_BASE_URL` | API 서버 URL 직접 지정 | `https://conf.grepiu.com` (`local` 시 `http://localhost:8010`) |
| `WEB_HOST` | 시디키 전달 URL 호스트 | `https://www.grepiu.com` (`local` 시 `http://localhost:3000`) |
| `GOOGLE_SERVER_CLIENT_ID` | Google OAuth2 Web Client ID (`idToken` 검증용) | 서버 프로필별 Client ID |

- 보안 및 스토어 심사 정책상 로그인 UI에는 API 서버 URL(`conf.grepiu.com` 등)이나 서버 선택 버튼을 노출하지 않으며, 빌드/실행 시 `--dart-define`으로 환경을 주입합니다.

---

## 8. 테스트 및 검증 정책

- 코드 변경 후 반드시 다음 명령을 실행하여 통과 여부를 확인합니다:
  1. `flutter analyze` (정적 분석 통과, 0 issues)
  2. `flutter test` (모델 직렬화, 인터셉터/저장소 단위 테스트, 로그인/관리 화면 위젯 테스트)
- 테스트에서는 네트워크 실호출을 피하고 `Repository` 인터페이스/구현체 Override(Riverpod `overrides`) 또는 Fake/Mock 객체를 사용합니다.

---

## 9. Git 커밋 컨벤션

`grepiu_server`와 동일한 커밋 접두어를 사용합니다:
- `feat:` 신규 기능 구현
- `fix:` 버그 수정
- `improve:` 기존 기능 및 UX 개선
- `refactor:` 동작 변경 없는 구조 개선
- `docs:` `AGENTS.md`, `README.md` 등 문서 작업
- `test:` 단위/위젯 테스트 추가 및 수정
- `chore:` 의존성, 빌드 설정 변경

---

## 10. 변경 이력

| 버전 | 일자 | 내용 |
|------|------|------|
| 1.0 | 2026-11-14 | 초기 생성: Flutter 기본 정책, 인증(ID/PW + Google), MiniPos/간편서명 통합 아키텍처, 클린코드/테스트 규칙 수립 |
