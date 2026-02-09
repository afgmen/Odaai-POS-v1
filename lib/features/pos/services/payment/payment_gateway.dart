/// 결제 처리 결과
class PaymentResult {
  final bool success;
  final String? reference;    // 결제 참조번호 (승인번호, 이체확인번호 등)
  final String? errorMessage; // 실패 시 에러 메시지
  final Map<String, dynamic>? metadata; // 추가 메타데이터

  const PaymentResult({
    required this.success,
    this.reference,
    this.errorMessage,
    this.metadata,
  });

  factory PaymentResult.success({required String reference, Map<String, dynamic>? metadata}) =>
      PaymentResult(success: true, reference: reference, metadata: metadata);

  factory PaymentResult.failure({required String errorMessage}) =>
      PaymentResult(success: false, errorMessage: errorMessage);
}

/// 결제 게이트웨이 추상 인터페이스
/// 모든 외부 결제 연동은 이 인터페이스를 구현
abstract class PaymentGateway {
  /// 게이트웨이 이름 (예: '카드 단말기', '은행 이체')
  String get name;

  /// 결제 처리
  Future<PaymentResult> processPayment({
    required double amount,
    required String orderId,
    Map<String, dynamic>? options,
  });

  /// 결제 취소 (환불)
  Future<PaymentResult> cancelPayment({
    required String reference,
    required double amount,
  });

  /// 게이트웨이 사용 가능 여부 확인
  Future<bool> isAvailable();
}

/// 카드 결제 게이트웨이 (오프라인 시뮬레이션)
/// 실제 카드 단말기 연동 시 이 클래스를 확장/교체
class CardPaymentGateway implements PaymentGateway {
  @override
  String get name => '카드 단말기';

  @override
  Future<PaymentResult> processPayment({
    required double amount,
    required String orderId,
    Map<String, dynamic>? options,
  }) async {
    // 실제 환경에서는 카드 단말기 SDK와 통신
    // 현재는 즉시 승인 (오프라인 모드)
    await Future.delayed(const Duration(milliseconds: 500));

    final approvalNo = 'CRD-${DateTime.now().millisecondsSinceEpoch % 1000000}';

    return PaymentResult.success(
      reference: approvalNo,
      metadata: {'gateway': 'card', 'approvalNo': approvalNo},
    );
  }

  @override
  Future<PaymentResult> cancelPayment({
    required String reference,
    required double amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return PaymentResult.success(reference: 'CANCEL-$reference');
  }

  @override
  Future<bool> isAvailable() async => true;
}

/// QR 결제 게이트웨이
class QrPaymentGateway implements PaymentGateway {
  @override
  String get name => 'QR 결제';

  @override
  Future<PaymentResult> processPayment({
    required double amount,
    required String orderId,
    Map<String, dynamic>? options,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final qrRef = 'QR-${DateTime.now().millisecondsSinceEpoch % 1000000}';

    return PaymentResult.success(
      reference: qrRef,
      metadata: {'gateway': 'qr', 'qrRef': qrRef},
    );
  }

  @override
  Future<PaymentResult> cancelPayment({
    required String reference,
    required double amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return PaymentResult.success(reference: 'CANCEL-$reference');
  }

  @override
  Future<bool> isAvailable() async => true;
}

/// 이체 결제 게이트웨이 (수동 확인 방식)
class TransferPaymentGateway implements PaymentGateway {
  @override
  String get name => '계좌이체';

  @override
  Future<PaymentResult> processPayment({
    required double amount,
    required String orderId,
    Map<String, dynamic>? options,
  }) async {
    // 이체는 수동 확인이므로 참조번호 즉시 발급
    final transferRef = 'TRF-${DateTime.now().millisecondsSinceEpoch % 1000000}';

    return PaymentResult.success(
      reference: transferRef,
      metadata: {
        'gateway': 'transfer',
        'transferRef': transferRef,
        'senderNote': options?['senderNote'] ?? '',
      },
    );
  }

  @override
  Future<PaymentResult> cancelPayment({
    required String reference,
    required double amount,
  }) async {
    // 이체 환불은 수동 처리
    return PaymentResult.success(reference: 'CANCEL-$reference');
  }

  @override
  Future<bool> isAvailable() async => true;
}
