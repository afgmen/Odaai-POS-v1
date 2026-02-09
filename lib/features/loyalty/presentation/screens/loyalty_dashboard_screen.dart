import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../domain/services/loyalty_service.dart';
import '../../providers/loyalty_provider.dart';
import '../widgets/point_card_widget.dart';

/// 로열티 프로그램 대시보드 화면
class LoyaltyDashboardScreen extends ConsumerWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayStatsAsync = ref.watch(todayPointStatsProvider);
    final tierCountAsync = ref.watch(customerCountByTierProvider);
    final allTiersAsync = ref.watch(allTiersProvider);
    final totalPointsAsync = ref.watch(totalActivePointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('로열티 프로그램'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, ref),
            tooltip: '설정',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 오늘의 포인트 통계
            _buildTodayStats(todayStatsAsync, totalPointsAsync),
            const SizedBox(height: 24),

            // 등급별 고객 분포
            _buildTierDistribution(tierCountAsync, allTiersAsync),
            const SizedBox(height: 24),

            // 생일 고객 목록
            _buildBirthdayCustomers(context, ref),
            const SizedBox(height: 24),

            // 빠른 액션
            _buildQuickActions(context, ref),
          ],
        ),
      ),
    );
  }

  /// 오늘의 포인트 통계
  Widget _buildTodayStats(
    AsyncValue<Map<String, int>> todayStatsAsync,
    AsyncValue<int> totalPointsAsync,
  ) {
    return todayStatsAsync.when(
      data: (stats) {
        final earned = stats['earned'] ?? 0;
        final redeemed = stats['redeemed'] ?? 0;
        final totalPoints = totalPointsAsync.value ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.today, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      '오늘의 포인트 현황',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '적립',
                        earned,
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '사용',
                        redeemed,
                        Colors.orange,
                        Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '전체 유효',
                        totalPoints,
                        AppTheme.primary,
                        Icons.account_balance_wallet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('오류: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    final format = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${format.format(value)}P',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 등급별 고객 분포
  Widget _buildTierDistribution(
    AsyncValue<Map<String, int>> tierCountAsync,
    AsyncValue<List<MembershipTier>> allTiersAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '등급별 고객 분포',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            tierCountAsync.when(
              data: (tierCount) {
                return allTiersAsync.when(
                  data: (tiers) {
                    final totalCustomers = tierCount.values.fold(0, (a, b) => a + b);

                    return Column(
                      children: tiers.map((tier) {
                        final count = tierCount[tier.tierCode] ?? 0;
                        final percent = totalCustomers > 0
                            ? (count / totalCustomers * 100).toStringAsFixed(1)
                            : '0.0';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getTierColor(tier.tierCode),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  _getTierName(tier.tierCode),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: totalCustomers > 0 ? count / totalCustomers : 0,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation(
                                    _getTierColor(tier.tierCode),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '$count명 ($percent%)',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('오류: $err'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('오류: $err'),
            ),
          ],
        ),
      ),
    );
  }

  /// 생일 고객 목록
  Widget _buildBirthdayCustomers(BuildContext context, WidgetRef ref) {
    final birthdayCustomersAsync = ref.watch(todayBirthdayCustomersProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cake, color: Colors.pink),
                const SizedBox(width: 8),
                const Text(
                  '오늘의 생일 고객',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            birthdayCustomersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '오늘 생일인 고객이 없습니다',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                return Column(
                  children: customers.map((customer) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.pink[100],
                        child: const Icon(Icons.cake, color: Colors.pink),
                      ),
                      title: Text(customer.name),
                      subtitle: Text(customer.phone ?? '-'),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _grantBirthdayBonus(context, ref, customer),
                        icon: const Icon(Icons.card_giftcard, size: 18),
                        label: const Text('보너스 지급'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('오류: $err'),
            ),
          ],
        ),
      ),
    );
  }

  /// 빠른 액션
  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '빠른 액션',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  '고객 검색',
                  Icons.search,
                  AppTheme.primary,
                  () => _searchCustomer(context, ref),
                ),
                _buildActionButton(
                  '포인트 조정',
                  Icons.edit,
                  Colors.orange,
                  () => _adjustPoints(context, ref),
                ),
                _buildActionButton(
                  '등급 관리',
                  Icons.military_tech,
                  Colors.purple,
                  () => _manageTiers(context, ref),
                ),
                _buildActionButton(
                  '설정',
                  Icons.settings,
                  Colors.grey,
                  () => _showSettingsDialog(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 헬퍼 메서드
  // ═══════════════════════════════════════════════════════

  Color _getTierColor(String tierCode) {
    switch (tierCode.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return Colors.grey;
    }
  }

  String _getTierName(String tierCode) {
    switch (tierCode.toLowerCase()) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      default:
        return tierCode;
    }
  }

  Future<void> _grantBirthdayBonus(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('생일 보너스 지급'),
        content: Text('${customer.name}님께 생일 보너스 포인트를 지급하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('지급'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final loyaltyService = ref.read(loyaltyServiceProvider);
        // TODO: employeeId는 현재 로그인된 직원 ID로 교체 필요
        await loyaltyService.grantBirthdayBonus(customer.id, 1);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('생일 보너스가 지급되었습니다')),
          );
          ref.invalidate(todayBirthdayCustomersProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e')),
          );
        }
      }
    }
  }

  void _searchCustomer(BuildContext context, WidgetRef ref) {
    // TODO: 고객 검색 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('고객 검색 기능 (구현 예정)')),
    );
  }

  void _adjustPoints(BuildContext context, WidgetRef ref) {
    // TODO: 포인트 조정 다이얼로그 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('포인트 조정 기능 (구현 예정)')),
    );
  }

  void _manageTiers(BuildContext context, WidgetRef ref) {
    // TODO: 등급 관리 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('등급 관리 기능 (구현 예정)')),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(loyaltySettingsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로열티 설정'),
        content: SizedBox(
          width: 400,
          child: settingsAsync.when(
            data: (settings) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSettingRow('최소 사용 포인트', settings['min_redeem_points'] ?? '-'),
                    _buildSettingRow('최대 사용 비율', '${settings['max_redeem_percent'] ?? '-'}%'),
                    _buildSettingRow('포인트 사용 단위', settings['point_unit'] ?? '-'),
                    _buildSettingRow('생일 보너스', settings['birthday_bonus_points'] ?? '-'),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('오류: $err'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 설정 편집 기능
              Navigator.of(context).pop();
            },
            child: const Text('편집'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}
