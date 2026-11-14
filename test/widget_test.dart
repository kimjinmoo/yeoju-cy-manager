import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeoju_cy_manager/app.dart';
import 'package:yeoju_cy_manager/core/network/api_exception.dart';
import 'package:yeoju_cy_manager/core/storage/token_storage.dart';
import 'package:yeoju_cy_manager/features/auth/data/auth_repository.dart';
import 'package:yeoju_cy_manager/features/auth/domain/auth_user.dart';
import 'package:yeoju_cy_manager/features/license_keys/data/license_key_repository.dart';
import 'package:yeoju_cy_manager/features/license_keys/domain/license_key_models.dart';
import 'package:yeoju_cy_manager/features/license_keys/domain/license_service_type.dart';
import 'package:yeoju_cy_manager/features/license_keys/presentation/widgets/issue_key_sheet.dart';

class _FakeTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;
  String? _envId;
  String? _customUrl;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<String?> getSavedCustomUrl() async => _customUrl;

  @override
  Future<String?> getSavedEnvId() async => _envId;

  @override
  Future<void> saveServerPreference({
    required String envId,
    String? customUrl,
  }) async {
    _envId = envId;
    _customUrl = customUrl;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
}

class _FakeAuthRepository implements AuthRepository {
  AuthUser? emailUser;
  AuthUser? googleUser;
  AuthUser? restoredUser;
  Exception? emailError;

  @override
  Future<AuthUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (emailError != null) {
      throw emailError!;
    }
    return emailUser!;
  }

  @override
  Future<AuthUser?> loginWithGoogle() async => googleUser;

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser?> restoreSession() async => restoredUser;
}

class _FakeLicenseKeyRepository implements LicenseKeyRepository {
  final Map<LicenseServiceType, List<LicenseKeyItem>> _store = {
    LicenseServiceType.miniPos: [
      const LicenseKeyItem(
        key: 'MPOS-1111-2222-3333',
        device: 'POS-DEV-01',
        reject: 'N',
        keyType: 'SALE',
        salesLocation: '여주 본점',
        validDays: 365,
        expireDate: '2027-01-01T00:00:00',
        memo: '본점 포스',
      ),
    ],
    LicenseServiceType.sign: [
      const LicenseKeyItem(
        key: 'SIGN-AAAA-BBBB-CCCC',
        reject: 'N',
        keyType: 'TEST',
        salesLocation: '스마트스토어',
        validDays: 30,
        memo: '서명 태블릿',
      ),
    ],
  };

  @override
  Future<void> deleteKey({
    required LicenseServiceType serviceType,
    required String key,
  }) async {
    _store[serviceType]?.removeWhere((item) => item.key == key);
  }

  @override
  Future<int> expireBatch(LicenseServiceType serviceType) async => 0;

  @override
  Future<LicenseKeyHistoryPageResult> fetchHistories({
    required LicenseServiceType serviceType,
    String? key,
    String? actionType,
    String keyword = '',
    int page = 0,
    int size = 20,
  }) async {
    return const LicenseKeyHistoryPageResult(
      items: [],
      totalPages: 1,
      totalCount: 0,
    );
  }

  @override
  Future<LicenseKeyPageResult> fetchKeys({
    required LicenseServiceType serviceType,
    required int page,
    required int size,
    String keyword = '',
    LicenseKeyStatusFilter status = LicenseKeyStatusFilter.all,
    LicenseKeyType? keyType,
    String salesLocation = '',
  }) async {
    final items = _store[serviceType] ?? const [];
    return LicenseKeyPageResult(
      items: items,
      totalPages: 1,
      totalCount: items.length,
    );
  }

  @override
  Future<List<String>> fetchSalesLocations(LicenseServiceType serviceType) async {
    return const ['여주 본점', '스마트스토어'];
  }

  @override
  Future<List<DailySalesStatItem>> fetchStatistics(
    LicenseServiceType serviceType,
  ) async {
    if (serviceType == LicenseServiceType.sign) {
      return const [DailySalesStatItem(date: '2026-11-10', count: 4)];
    }
    return const [DailySalesStatItem(date: '2026-11-10', count: 2)];
  }

  @override
  Future<LicenseKeySummary> fetchSummary(LicenseServiceType serviceType) async {
    final count = _store[serviceType]?.length ?? 0;
    return LicenseKeySummary(
      total: count,
      active: serviceType == LicenseServiceType.miniPos ? 1 : 0,
      unused: serviceType == LicenseServiceType.sign ? 1 : 0,
      stopped: 0,
      expired: 0,
      expiringSoon: 0,
      saleCount: serviceType == LicenseServiceType.miniPos ? 1 : 0,
      testCount: serviceType == LicenseServiceType.sign ? 1 : 0,
    );
  }

  @override
  Future<List<LicenseKeyItem>> issueKeys({
    required LicenseServiceType serviceType,
    required LicenseKeyCreatePayload payload,
  }) async {
    final created = LicenseKeyItem(
      key: '${serviceType == LicenseServiceType.miniPos ? 'MPOS' : 'SIGN'}-NEW-0001',
      keyType: payload.keyType.value,
      salesLocation: payload.salesLocation,
      validDays: payload.validDays,
      memo: payload.memo,
    );
    _store[serviceType]?.insert(0, created);
    return [created];
  }

  @override
  Future<void> initDevice({
    required LicenseServiceType serviceType,
    required String key,
  }) async {}

  @override
  Future<LicenseKeyItem> updateKeyInfo({
    required LicenseServiceType serviceType,
    required LicenseKeyUpdatePayload payload,
  }) async {
    return _store[serviceType]!.first;
  }

  @override
  Future<void> updateReject({
    required LicenseServiceType serviceType,
    required String key,
    required bool stop,
  }) async {}
}

Widget _buildTestApp({
  required _FakeTokenStorage tokenStorage,
  required _FakeAuthRepository authRepository,
  required _FakeLicenseKeyRepository licenseRepository,
}) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(tokenStorage),
      authRepositoryProvider.overrideWithValue(authRepository),
      licenseKeyRepositoryProvider.overrideWithValue(licenseRepository),
    ],
    child: const YeojuCycleManagerApp(),
  );
}

void main() {
  testWidgets('초기 구동 시 애니메이션 스플래시 화면을 표시한 뒤 로그인 화면으로 전환한다', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        tokenStorage: _FakeTokenStorage(),
        authRepository: _FakeAuthRepository(),
        licenseRepository: _FakeLicenseKeyRepository(),
      ),
    );

    // 초기 마이크로태스크 및 스플래시 인트로 애니메이션 진행 확인
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('여주자전거여행'), findsOneWidget);
    expect(find.text('MANAGER · LICENSE & SIGN'), findsOneWidget);
    expect(find.text('인증 세션을 확인하고 있습니다...'), findsOneWidget);

    // 최소 스플래시 시간 경과 후 로그인 화면으로 자동 전환 확인
    await tester.pumpAndSettle();
    expect(find.text('관리자 로그인'), findsOneWidget);
    expect(find.text('Google 계정으로 로그인'), findsOneWidget);
  });

  testWidgets('ID/PW 관리자 로그인 성공 후 MiniPos·간편서명·판매통계 관리 화면으로 이동한다', (
    tester,
  ) async {
    final authRepo = _FakeAuthRepository()
      ..emailUser = const AuthUser(
        email: 'admin@grepiu.com',
        nickname: '여주관리자',
        roles: ['ROLE_ADMIN'],
      );
    final licenseRepo = _FakeLicenseKeyRepository();
    final tokenStorage = _FakeTokenStorage();

    await tester.pumpWidget(
      _buildTestApp(
        tokenStorage: tokenStorage,
        authRepository: authRepo,
        licenseRepository: licenseRepo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('여주자전거여행'), findsOneWidget);
    expect(find.text('Google 계정으로 로그인'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@grepiu.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123!');
    await tester.ensureVisible(find.text('이메일로 로그인'));
    await tester.tap(find.text('이메일로 로그인'));
    await tester.pumpAndSettle();

    // MiniPos 관리 화면 진입 확인
    expect(find.text('MiniPos 시디키 관리'), findsOneWidget);
    expect(find.text('MPOS-1111-2222-3333'), findsOneWidget);

    // 간편서명 탭 전환 확인
    await tester.tap(find.text('간편서명'));
    await tester.pumpAndSettle();
    expect(find.text('간편서명 키 관리'), findsOneWidget);
    expect(find.text('SIGN-AAAA-BBBB-CCCC'), findsOneWidget);

    // 판매통계 탭 전환 확인
    await tester.tap(find.text('판매통계'));
    await tester.pumpAndSettle();
    expect(find.text('판매 통계 (최근 3개월)'), findsOneWidget);
    expect(find.text('6건'), findsOneWidget);
  });

  testWidgets('Google 로그인으로 YEOJU_CYCLE_ADMIN 계정 인증 시 관리 화면에 진입한다', (
    tester,
  ) async {
    final authRepo = _FakeAuthRepository()
      ..googleUser = const AuthUser(
        email: 'cycle@grepiu.com',
        nickname: '자전거담당',
        roles: ['YEOJU_CYCLE_ADMIN'],
        provider: 'google',
      );

    await tester.pumpWidget(
      _buildTestApp(
        tokenStorage: _FakeTokenStorage(),
        authRepository: authRepo,
        licenseRepository: _FakeLicenseKeyRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Google 계정으로 로그인'));
    await tester.tap(find.text('Google 계정으로 로그인'));
    await tester.pumpAndSettle();

    expect(find.text('MiniPos 시디키 관리'), findsOneWidget);
  });

  testWidgets('관리자 권한이 없는 일반 계정은 권한 안내 화면으로 이동한다', (tester) async {
    final authRepo = _FakeAuthRepository()
      ..googleUser = const AuthUser(
        email: 'guest@grepiu.com',
        nickname: '일반사용자',
        roles: ['ROLE_USER'],
        provider: 'google',
      );

    await tester.pumpWidget(
      _buildTestApp(
        tokenStorage: _FakeTokenStorage(),
        authRepository: authRepo,
        licenseRepository: _FakeLicenseKeyRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Google 계정으로 로그인'));
    await tester.tap(find.text('Google 계정으로 로그인'));
    await tester.pumpAndSettle();

    expect(find.text('관리자 접근 권한이 필요합니다'), findsOneWidget);
    expect(find.textContaining('guest@grepiu.com'), findsOneWidget);
  });

  testWidgets('로그인 실패 시 한글 오류 배너를 표시한다', (tester) async {
    final authRepo = _FakeAuthRepository()
      ..emailError = const ApiException(
        message: '이메일 또는 비밀번호가 올바르지 않습니다.',
        statusCode: 401,
      );

    await tester.pumpWidget(
      _buildTestApp(
        tokenStorage: _FakeTokenStorage(),
        authRepository: authRepo,
        licenseRepository: _FakeLicenseKeyRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'wrong@grepiu.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'badpass');
    await tester.ensureVisible(find.text('이메일로 로그인'));
    await tester.tap(find.text('이메일로 로그인'));
    await tester.pumpAndSettle();

    expect(find.text('이메일 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
  });

  testWidgets('시디키 발급 바텀시트는 판매키와 테스트키 전환 시에도 높이가 일정하게 유지된다', (
    tester,
  ) async {
    final authRepo = _FakeAuthRepository()
      ..emailUser = const AuthUser(
        email: 'admin@grepiu.com',
        nickname: '여주관리자',
        roles: ['ROLE_ADMIN'],
      );

    await tester.pumpWidget(
      _buildTestApp(
        tokenStorage: _FakeTokenStorage(),
        authRepository: authRepo,
        licenseRepository: _FakeLicenseKeyRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@grepiu.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123!');
    await tester.ensureVisible(find.text('이메일로 로그인'));
    await tester.tap(find.text('이메일로 로그인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('시디키 발급'));
    await tester.pumpAndSettle();

    final saleHeight = tester.getSize(find.byType(IssueKeySheet)).height;

    await tester.tap(find.text('테스트키 (TEST)'));
    await tester.pumpAndSettle();
    final testHeight = tester.getSize(find.byType(IssueKeySheet)).height;

    await tester.tap(find.text('판매키 (SALE)'));
    await tester.pumpAndSettle();
    final backToSaleHeight = tester.getSize(find.byType(IssueKeySheet)).height;

    expect(testHeight, saleHeight);
    expect(backToSaleHeight, saleHeight);
  });
}
