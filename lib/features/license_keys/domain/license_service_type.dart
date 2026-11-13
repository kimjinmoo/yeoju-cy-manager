/// 여주자전거여행에서 관리하는 라이선스 키 서비스 구분이다.
enum LicenseServiceType {
  /// MiniPos (스마트 계산하기) 시디키 관리
  miniPos(
    basePath: '/v1/mini-pos',
    shortLabel: 'MiniPos',
    displayLabel: 'MiniPos (스마트 계산하기)',
    deliveryType: 'mini-pos',
  ),

  /// 간판서명 / 간편서명 (Sign) 키 관리
  sign(
    basePath: '/v1/sign',
    shortLabel: '간편서명',
    displayLabel: '간판서명 (간편서명)',
    deliveryType: 'sign',
  );

  const LicenseServiceType({
    required this.basePath,
    required this.shortLabel,
    required this.displayLabel,
    required this.deliveryType,
  });

  /// 백엔드 REST API 기본 경로 (`/v1/mini-pos` 또는 `/v1/sign`)
  final String basePath;

  /// 하단 탭 및 뱃지용 짧은 이름
  final String shortLabel;

  /// 화면 헤더 및 모달용 상세 이름
  final String displayLabel;

  /// 모바일 키 전달 URL의 `type` 쿼리 파라미터
  final String deliveryType;

  /// 전달 URL(`{webHost}/key-delivery?key=...&type=...`)을 생성한다.
  String buildDeliveryUrl({
    required String webHost,
    required String key,
  }) {
    final normalizedHost =
        webHost.endsWith('/') ? webHost.substring(0, webHost.length - 1) : webHost;
    final encodedKey = Uri.encodeQueryComponent(key);
    return '$normalizedHost/key-delivery?key=$encodedKey&type=$deliveryType';
  }
}
