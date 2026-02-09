import 'package:flutter/material.dart';

/// 디바이스 타입 열거형
enum DeviceType { mobile, tablet, desktop }

/// 반응형 헬퍼 유틸리티
class ResponsiveHelper {
  /// 브레이크포인트
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;

  /// 화면 너비 기반 디바이스 타입 판별
  static DeviceType getDeviceType(double width) {
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// BuildContext 기반 디바이스 타입 판별
  static DeviceType of(BuildContext context) {
    return getDeviceType(MediaQuery.of(context).size.width);
  }

  /// 상품 그리드 열 수
  static int getGridCrossAxisCount(double width) {
    if (width < 400) return 2;
    if (width < 700) return 3;
    if (width < 1000) return 4;
    return 5;
  }

  /// 카드 종횡비
  static double getCardAspectRatio(DeviceType type) {
    return switch (type) {
      DeviceType.mobile => 0.85,
      DeviceType.tablet => 0.80,
      DeviceType.desktop => 0.78,
    };
  }

  /// 화면 여백
  static EdgeInsets getScreenPadding(DeviceType type) {
    return switch (type) {
      DeviceType.mobile => const EdgeInsets.all(8),
      DeviceType.tablet => const EdgeInsets.all(12),
      DeviceType.desktop => const EdgeInsets.all(16),
    };
  }

  /// POS 장바구니 패널 폭 (태블릿/데스크탑에서 사이드 패널)
  static double getCartPanelWidth(DeviceType type) {
    return switch (type) {
      DeviceType.mobile => double.infinity,
      DeviceType.tablet => 300,
      DeviceType.desktop => 340,
    };
  }

  /// 카테고리 필터 폭
  static double getCategoryFilterWidth(DeviceType type) {
    return switch (type) {
      DeviceType.mobile => double.infinity, // 수평 스크롤
      DeviceType.tablet => 120,
      DeviceType.desktop => 140,
    };
  }

  /// 모바일인지 확인
  static bool isMobile(BuildContext context) {
    return of(context) == DeviceType.mobile;
  }

  /// 태블릿 이상인지 확인
  static bool isTabletOrWider(BuildContext context) {
    return of(context) != DeviceType.mobile;
  }
}
