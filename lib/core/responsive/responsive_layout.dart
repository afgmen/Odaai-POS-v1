import 'package:flutter/material.dart';

import 'responsive_helper.dart';

/// LayoutBuilder 래퍼 - 디바이스 타입별 빌더 제공
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType, double width)
      builder;

  const ResponsiveLayout({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveHelper.getDeviceType(constraints.maxWidth);
        return builder(context, deviceType, constraints.maxWidth);
      },
    );
  }
}

/// 모바일/태블릿 분기 위젯
class MobileOrTablet extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget? desktop;

  const MobileOrTablet({
    super.key,
    required this.mobile,
    required this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, deviceType, width) {
        return switch (deviceType) {
          DeviceType.mobile => mobile,
          DeviceType.tablet => tablet,
          DeviceType.desktop => desktop ?? tablet,
        };
      },
    );
  }
}
