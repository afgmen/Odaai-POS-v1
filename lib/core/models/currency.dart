/// 지원하는 통화
enum AppCurrency {
  krw('KRW', '₩', 'won', 1.0, 0),
  usd('USD', '\$', 'dollar', 0.00075, 2),
  vnd('VND', '₫', 'dong', 19.5, 0);

  final String code;
  final String symbol;
  final String name;
  final double defaultRate;  // KRW 기준 환율
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
      orElse: () => AppCurrency.krw,
    );
  }
}
