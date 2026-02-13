/// 지원하는 통화
enum AppCurrency {
  vnd('VND', '₫', 'dong', 1.0, 0),
  usd('USD', '\$', 'dollar', 0.000038, 2);

  final String code;
  final String symbol;
  final String name;
  final double defaultRate;  // VND 기준 환율
  final int decimalDigits;   // 소수점 자릿수

  const AppCurrency(
    this.code,
    this.symbol,
    this.name,
    this.defaultRate,
    this.decimalDigits,
  );

  static AppCurrency fromCode(String code) {
    return AppCurrency.values.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => AppCurrency.vnd,
    );
  }
}
