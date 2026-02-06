import '../models/currency.dart';

class PriceFormatter {
  final AppCurrency currency;
  final double exchangeRate;

  PriceFormatter({
    required this.currency,
    required this.exchangeRate,
  });

  /// KRW 가격을 현재 통화로 변환
  double convert(double priceInKRW) {
    return priceInKRW * exchangeRate;
  }

  /// 현재 통화를 KRW로 역변환
  double toKRW(double priceInCurrency) {
    return priceInCurrency / exchangeRate;
  }

  /// 가격을 현재 통화 형식으로 포맷팅
  String format(double priceInKRW, {bool includeSymbol = true}) {
    final convertedPrice = convert(priceInKRW);
    final rounded = convertedPrice.toStringAsFixed(currency.decimalDigits);

    final parts = rounded.split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    final formattedNumber = parts.length > 1 && currency.decimalDigits > 0
        ? '$integerPart.${parts[1]}'
        : integerPart;

    return includeSymbol ? '${currency.symbol}$formattedNumber' : formattedNumber;
  }

  /// 간단한 포맷팅 (format과 동일, 하위 호환성)
  String formatSimple(double priceInKRW) {
    return format(priceInKRW);
  }
}
