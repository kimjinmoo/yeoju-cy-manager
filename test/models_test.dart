import 'package:flutter_test/flutter_test.dart';

import 'package:yeoju_cy_manager/features/auth/domain/auth_user.dart';
import 'package:yeoju_cy_manager/features/license_keys/domain/license_key_models.dart';
import 'package:yeoju_cy_manager/features/license_keys/presentation/utils/history_diff_helper.dart';

void main() {
  group('AuthUser 권한 판별 테스트', () {
    test('ROLE_ 접두사가 붙은 ADMIN / YEOJU_CYCLE_ADMIN 권한을 정규화하여 관리자 여부를 판별한다', () {
      final admin = AuthUser.fromJson({
        'email': 'admin@grepiu.com',
        'nickname': '관리자',
        'roles': ['ROLE_ADMIN'],
      });
      final cycleAdmin = AuthUser.fromJson({
        'email': 'cycle@grepiu.com',
        'nickname': '여주담당',
        'roles': ['yeoju_cycle_admin'],
        'provider': 'google',
      });
      final normalUser = AuthUser.fromJson({
        'email': 'user@grepiu.com',
        'nickname': '일반',
        'roles': ['ROLE_USER'],
      });

      expect(admin.roles, ['ADMIN']);
      expect(admin.hasCycleAdminRole, isTrue);

      expect(cycleAdmin.roles, ['YEOJU_CYCLE_ADMIN']);
      expect(cycleAdmin.hasCycleAdminRole, isTrue);
      expect(cycleAdmin.provider, 'google');

      expect(normalUser.hasCycleAdminRole, isFalse);
    });
  });

  group('라이선스 키 및 통계 모델 파싱 테스트', () {
    test('LicenseKeyItem.fromJson과 DailySalesStatItem.fromJson이 필드를 정확히 파싱한다', () {
      final keyItem = LicenseKeyItem.fromJson({
        'key': 'ABCD-1234-EFGH-5678',
        'device': 'DEVICE-01',
        'reject': 'N',
        'keyType': 'SALE',
        'salesLocation': '여주 본점',
        'validDays': 365,
        'expireDate': '2027-01-01T00:00:00',
        'memo': '초기 납품',
      });

      expect(keyItem.key, 'ABCD-1234-EFGH-5678');
      expect(keyItem.device, 'DEVICE-01');
      expect(keyItem.reject, 'N');
      expect(keyItem.keyType, 'SALE');
      expect(keyItem.salesLocation, '여주 본점');
      expect(keyItem.validDays, 365);

      final statByCount = DailySalesStatItem.fromJson({
        'date': '2026-11-01',
        'count': 5,
      });
      final statByCnt = DailySalesStatItem.fromJson({
        'date': '2026-11-02',
        'cnt': 3,
      });

      expect(statByCount.date, '2026-11-01');
      expect(statByCount.count, 5);
      expect(statByCnt.date, '2026-11-02');
      expect(statByCnt.count, 3);
    });

    test('HistoryDiffHelper.buildDiffs가 발급 및 수정 전후 스냅샷 diff를 생성한다', () {
      final issueDiffs = HistoryDiffHelper.buildDiffs(
        null,
        {
          'keyType': 'TEST',
          'salesLocation': '내부 테스트',
          'validDays': 7,
          'memo': '테스트용',
        },
      );
      expect(issueDiffs.map((e) => e.label), containsAll(['구분', '판매처', '기간', '비고']));
      expect(issueDiffs.first.after, '테스트키');

      final updateDiffs = HistoryDiffHelper.buildDiffs(
        {
          'keyType': 'SALE',
          'salesLocation': '여주 본점',
          'validDays': 30,
        },
        {
          'keyType': 'SALE',
          'salesLocation': '스마트스토어',
          'validDays': 90,
        },
      );
      expect(
        updateDiffs.any(
          (e) => e.label == '판매처' && e.before == '여주 본점' && e.after == '스마트스토어',
        ),
        isTrue,
      );
    });
  });
}
