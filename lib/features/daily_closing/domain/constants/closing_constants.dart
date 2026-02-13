/// 일일 마감 관련 상수
class ClosingConstants {
  ClosingConstants._(); // Private constructor to prevent instantiation

  /// 시재 차액 허용 범위 (원)
  /// 이 범위 내의 차액은 정상으로 간주됩니다.
  static const double acceptableCashDifference = 1000.0;

  /// 통화 형식 (한국 원화)
  static const String currencyLocale = 'ko_KR';
  static const String currencySymbol = '₩';

  /// 마감 이력 기본 조회 개수
  static const int defaultHistoryLimit = 30;
}
