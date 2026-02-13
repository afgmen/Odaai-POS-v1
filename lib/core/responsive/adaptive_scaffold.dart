import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'responsive_helper.dart';

/// 반응형 네비게이션 구조
/// - 모바일: BottomNavigationBar (주요 4개 + 더보기)
/// - 태블릿/데스크탑: NavigationRail (좌측 사이드바, 전체 탭 스크롤)
class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationItem> destinations;
  final IndexedWidgetBuilder bodyBuilder;
  final Widget? trailing; // NavigationRail 하단에 표시할 위젯 (동기화 상태 등)

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.bodyBuilder,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.of(context);

    if (deviceType == DeviceType.mobile) {
      return _buildMobileLayout(context);
    } else {
      return _buildTabletLayout(context, deviceType);
    }
  }

  // ─── 모바일: 하단 4개 탭 + "더보기" 메뉴 ──────────────────
  /// 모바일 하단 바에 표시할 주요 탭 인덱스
  static const _mobileMainIndices = [0, 1, 2, 3]; // POS, 상품, 주문, 대시보드

  Widget _buildMobileLayout(BuildContext context) {
    // "더보기" 메뉴에 들어갈 나머지 탭들
    final moreIndices = List<int>.generate(destinations.length, (i) => i)
        .where((i) => !_mobileMainIndices.contains(i))
        .toList();

    // 현재 선택이 "더보기" 그룹에 속하는지
    final isMoreSelected = moreIndices.contains(currentIndex);

    // 하단 바에서의 선택 인덱스
    final bottomIndex = isMoreSelected
        ? _mobileMainIndices.length // "더보기" 위치
        : _mobileMainIndices.indexOf(currentIndex).clamp(0, _mobileMainIndices.length - 1);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: bodyBuilder(context, currentIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomIndex,
        onDestinationSelected: (idx) {
          if (idx < _mobileMainIndices.length) {
            onDestinationSelected(_mobileMainIndices[idx]);
          } else {
            // "더보기" 탭 클릭 → 팝업 메뉴
            _showMoreMenu(context, moreIndices);
          }
        },
        backgroundColor: AppTheme.cardWhite,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x14000000),
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          );
        }),
        indicatorColor: const Color(0xFFE8F0FE),
        destinations: [
          // 주요 4개 탭
          ..._mobileMainIndices.map((i) {
            final d = destinations[i];
            return NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            );
          }),
          // "더보기" 탭
          NavigationDestination(
            icon: Icon(
              Icons.more_horiz,
              color: isMoreSelected ? AppTheme.primary : null,
            ),
            selectedIcon: const Icon(Icons.more_horiz),
            label: _getMoreLabel(context),
          ),
        ],
      ),
    );
  }

  String _getMoreLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'vi':
        return 'Thêm';
      default:
        return 'More';
    }
  }

  void _showMoreMenu(BuildContext context, List<int> moreIndices) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ...moreIndices.map((i) {
              final d = destinations[i];
              final isSelected = currentIndex == i;
              return ListTile(
                leading: Icon(
                  isSelected ? d.selectedIcon : d.icon,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
                title: Text(
                  d.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
                selected: isSelected,
                onTap: () {
                  Navigator.pop(ctx);
                  onDestinationSelected(i);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 태블릿/데스크탑: NavigationRail (좌측, 스크롤 가능)
  Widget _buildTabletLayout(BuildContext context, DeviceType deviceType) {
    final extended = deviceType == DeviceType.desktop;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // NavigationRail + trailing을 Column으로 분리
          Container(
            color: AppTheme.cardWhite,
            width: extended ? 180 : 60,
            child: Column(
              children: [
                // 로고
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: extended ? 16 : 8,
                  ),
                  child: extended
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Oda POS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.point_of_sale,
                          size: 28,
                          color: AppTheme.primary,
                        ),
                ),
                // 탭 목록 (스크롤 가능)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(destinations.length, (i) {
                        final d = destinations[i];
                        final isSelected = currentIndex == i;
                        return _NavRailItem(
                          icon: isSelected ? d.selectedIcon : d.icon,
                          label: d.label,
                          isSelected: isSelected,
                          extended: extended,
                          onTap: () => onDestinationSelected(i),
                        );
                      }),
                    ),
                  ),
                ),
                // Trailing 위젯 (동기화 상태 등) — 하단 고정
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 8),
                    child: trailing,
                  ),
              ],
            ),
          ),
          // Divider
          Container(width: 1, color: AppTheme.divider),
          // Body
          Expanded(child: bodyBuilder(context, currentIndex)),
        ],
      ),
    );
  }
}

/// 커스텀 NavigationRail 아이템 (스크롤 가능하게 하기 위해)
class _NavRailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool extended;
  final VoidCallback onTap;

  const _NavRailItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.extended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.primary : AppTheme.textSecondary;
    final bgColor = isSelected ? const Color(0xFFE8F0FE) : Colors.transparent;

    if (extended) {
      // 확장 모드: 아이콘 + 라벨 가로 배치
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // 축소 모드: 아이콘만
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Icon(icon, size: 22, color: color),
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 60,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// 네비게이션 아이템 데이터
class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
