import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// PIN 암호화 유틸리티
/// SHA-256 해시를 사용하여 PIN을 안전하게 저장
class PinHasher {
  // 레거시 전역 salt (기존 데이터 호환용 — 신규 PIN 설정 시에는 사용하지 않음)
  static const String _legacySalt = 'ODA_POS_PIN_SALT_v1_2026';

  /// 직원별 고유 salt 생성 (16바이트 랜덤)
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// PIN을 SHA-256 해시로 변환
  ///
  /// [plainPin] 평문 PIN (4-6자리 숫자)
  /// [salt] 직원별 고유 salt. null이면 레거시 전역 salt 사용
  /// Returns: SHA-256 해시 문자열
  static String hashPin(String plainPin, {String? salt}) {
    final effectiveSalt = salt ?? _legacySalt;
    final saltedPin = plainPin + effectiveSalt;
    final bytes = utf8.encode(saltedPin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// PIN 검증
  ///
  /// [plainPin] 입력받은 평문 PIN
  /// [storedHash] 저장된 해시 값
  /// [salt] 직원별 고유 salt. null이면 레거시 전역 salt로 검증
  /// Returns: 일치 여부
  static bool verifyPin(String plainPin, String storedHash, {String? salt}) {
    final inputHash = hashPin(plainPin, salt: salt);
    return inputHash == storedHash;
  }

  /// PIN 형식 검증 (4-6자리 숫자)
  ///
  /// [pin] 검증할 PIN
  /// Returns: 유효성 여부
  static bool isValidPinFormat(String pin) {
    // 길이 체크
    if (pin.length < 4 || pin.length > 6) {
      return false;
    }

    // 숫자만 포함되어 있는지 확인
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  /// PIN 강도 체크 (보안 수준)
  ///
  /// [pin] 검증할 PIN
  /// Returns: 강도 (0: 약함, 1: 보통, 2: 강함)
  static int checkPinStrength(String pin) {
    if (!isValidPinFormat(pin)) return 0;

    // 연속된 숫자 체크 (1234, 4321 등)
    bool hasSequential = false;
    for (int i = 0; i < pin.length - 1; i++) {
      final current = int.parse(pin[i]);
      final next = int.parse(pin[i + 1]);
      if ((next - current).abs() == 1) {
        hasSequential = true;
        break;
      }
    }

    // 반복된 숫자 체크 (1111, 2222 등)
    bool hasRepeated = pin.split('').toSet().length == 1;

    // 일반적인 PIN 체크
    final commonPins = ['1234', '4321', '0000', '1111', '2222', '5555'];
    bool isCommon = commonPins.contains(pin);

    if (isCommon || hasRepeated) {
      return 0; // 약함
    } else if (hasSequential) {
      return 1; // 보통
    } else {
      return 2; // 강함
    }
  }
}
