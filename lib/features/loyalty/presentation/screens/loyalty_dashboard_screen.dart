import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../customers/presentation/screens/customer_management_screen.dart';
import '../../../customers/providers/customers_provider.dart';
import '../../domain/services/loyalty_service.dart';
import '../../providers/loyalty_provider.dart';

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
        title: const Text('Loyalty Program'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, ref),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's point stats
            _buildTodayStats(todayStatsAsync, totalPointsAsync),
            const SizedBox(height: 24),

            // Tier distribution
            _buildTierDistribution(tierCountAsync, allTiersAsync),
            const SizedBox(height: 24),

            // Birthday customers
            _buildBirthdayCustomers(context, ref),
            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(context, ref),
          ],
        ),
      ),
    );
  }

  /// Today's point stats
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
                      "Today's Points",
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
                        'Earned',
                        earned,
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Redeemed',
                        redeemed,
                        Colors.orange,
                        Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Active',
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
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    final format = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  /// Tier distribution
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
                  'Customer by Tier',
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
                                  '$count ($percent%)',
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
                  error: (err, stack) => Text('Error: $err'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  /// Birthday customers
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
                  "Today's Birthday Customers",
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
                        'No birthday customers today',
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
                        label: const Text('Grant Bonus'),
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
              error: (err, stack) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick actions
  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
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
                  'Customer Search',
                  Icons.search,
                  AppTheme.primary,
                  () => _searchCustomer(context, ref),
                ),
                _buildActionButton(
                  'Adjust Points',
                  Icons.edit,
                  Colors.orange,
                  () => _adjustPoints(context, ref),
                ),
                _buildActionButton(
                  'Tier Management',
                  Icons.military_tech,
                  Colors.purple,
                  () => _manageTiers(context, ref),
                ),
                _buildActionButton(
                  'Settings',
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
        title: const Text('Grant Birthday Bonus'),
        content: Text('Grant birthday bonus points to ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Grant'),
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
            const SnackBar(content: Text('Birthday bonus granted')),
          );
          ref.invalidate(todayBirthdayCustomersProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _searchCustomer(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerManagementScreen()),
    );
  }

  void _adjustPoints(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _PointAdjustmentDialog(ref: ref),
    );
  }

  void _manageTiers(BuildContext context, WidgetRef ref) {
    final tiersAsync = ref.watch(allTiersProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tier Management'),
        content: SizedBox(
          width: 400,
          child: tiersAsync.when(
            data: (tiers) {
              if (tiers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No tiers configured'),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: tiers.map((tier) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTierColor(tier.tierCode),
                          child: const Icon(Icons.military_tech, color: Colors.white, size: 20),
                        ),
                        title: Text(_getTierName(tier.tierCode)),
                        subtitle: Text('Min Spent: ${tier.minSpent} — Earn Rate: ${(tier.pointRate * 100).toStringAsFixed(1)}%'),
                        trailing: Text(tier.tierCode, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(loyaltySettingsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loyalty Settings'),
        content: SizedBox(
          width: 400,
          child: settingsAsync.when(
            data: (settings) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSettingRow('Min Redeem Points', settings['min_redeem_points'] ?? '-'),
                    _buildSettingRow('Max Redeem %', '${settings['max_redeem_percent'] ?? '-'}%'),
                    _buildSettingRow('Point Unit', settings['point_unit'] ?? '-'),
                    _buildSettingRow('Birthday Bonus', settings['birthday_bonus_points'] ?? '-'),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings editor available in admin panel')),
              );
            },
            child: const Text('Edit'),
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

class _PointAdjustmentDialog extends StatefulWidget {
  final WidgetRef ref;
  const _PointAdjustmentDialog({required this.ref});

  @override
  State<_PointAdjustmentDialog> createState() => _PointAdjustmentDialogState();
}

class _PointAdjustmentDialogState extends State<_PointAdjustmentDialog> {
  final _searchController = TextEditingController();
  final _pointsController = TextEditingController();
  final _reasonController = TextEditingController();
  Customer? _selectedCustomer;
  List<Customer> _searchResults = [];
  bool _isAdding = true;

  @override
  void dispose() {
    _searchController.dispose();
    _pointsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    final dao = widget.ref.read(customersDaoProvider);
    final results = await dao.searchCustomers(query);
    if (mounted) setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Points'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customer by name or phone',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: _search,
              ),

              if (_searchResults.isNotEmpty && _selectedCustomer == null)
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (_, i) {
                      final c = _searchResults[i];
                      return ListTile(
                        dense: true,
                        title: Text(c.name),
                        subtitle: Text(c.phone ?? ''),
                        trailing: Text('${c.points}P', style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () => setState(() {
                          _selectedCustomer = c;
                          _searchController.text = c.name;
                          _searchResults = [];
                        }),
                      );
                    },
                  ),
                ),

              if (_selectedCustomer != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${_selectedCustomer!.name} — ${_selectedCustomer!.points}P')),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _selectedCustomer = null;
                          _searchController.clear();
                        }),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Add'),
                      selected: _isAdding,
                      selectedColor: Colors.green.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _isAdding = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Deduct'),
                      selected: !_isAdding,
                      selectedColor: Colors.red.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _isAdding = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Points',
                  prefixIcon: Icon(_isAdding ? Icons.add : Icons.remove),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  hintText: 'e.g. Manual adjustment, Promotion',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedCustomer == null || _pointsController.text.isEmpty
              ? null
              : () => _submit(context),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final points = int.tryParse(_pointsController.text);
    if (points == null || points <= 0 || _selectedCustomer == null) return;

    try {
      final dao = widget.ref.read(customersDaoProvider);
      if (_isAdding) {
        await dao.addPoints(_selectedCustomer!.id, points);
      } else {
        final success = await dao.usePoints(_selectedCustomer!.id, points);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Insufficient points'), backgroundColor: Colors.red),
          );
          return;
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAdding
                ? 'Added $points points to ${_selectedCustomer!.name}'
                : 'Deducted $points points from ${_selectedCustomer!.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
