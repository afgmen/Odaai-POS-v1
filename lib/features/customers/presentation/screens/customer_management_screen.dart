import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/customers_provider.dart';

/// 고객 관리 (CRM) 화면
class CustomerManagementScreen extends ConsumerStatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  ConsumerState<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends ConsumerState<CustomerManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(allCustomersProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.customerManagement),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _showCustomerForm(context),
            icon: const Icon(Icons.person_add, color: AppTheme.primary),
            tooltip: l10n.addCustomer,
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchCustomerHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(customerSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(customerSearchQueryProvider.notifier).state = val;
              },
            ),
          ),

          // 고객 목록
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final query = ref.watch(customerSearchQueryProvider);
                final filtered = query.isEmpty
                    ? customers
                    : customers
                        .where((c) =>
                            c.name.toLowerCase().contains(query.toLowerCase()) ||
                            (c.phone?.contains(query) ?? false) ||
                            (c.email?.toLowerCase().contains(query.toLowerCase()) ?? false))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppTheme.textDisabled),
                        const SizedBox(height: 16),
                        Text(
                          query.isEmpty ? l10n.noCustomers : l10n.noSearchResult,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _CustomerCard(customer: filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.msgError(e.toString()))),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerForm(BuildContext context, {Customer? customer}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final noteCtrl = TextEditingController(text: customer?.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        final l10nDialog = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(customer == null ? l10nDialog.addCustomer : l10nDialog.editCustomer),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10nDialog.customerNameLabel, prefixIcon: const Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(labelText: l10nDialog.customerPhoneLabel, prefixIcon: const Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(labelText: l10nDialog.customerEmailLabel, prefixIcon: const Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(labelText: l10nDialog.customerNoteLabel, prefixIcon: const Icon(Icons.note)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10nDialog.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final dao = ref.read(customersDaoProvider);
                if (customer == null) {
                  await dao.createCustomer(CustomersCompanion.insert(
                    name: nameCtrl.text.trim(),
                    phone: Value(phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim()),
                    email: Value(emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim()),
                    note: Value(noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim()),
                  ));
                } else {
                  await dao.updateCustomer(CustomersCompanion(
                    id: Value(customer.id),
                    name: Value(nameCtrl.text.trim()),
                    phone: Value(phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim()),
                    email: Value(emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim()),
                    note: Value(noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim()),
                    points: Value(customer.points),
                    balance: Value(customer.balance),
                    isActive: const Value(true),
                    createdAt: Value(customer.createdAt),
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(l10nDialog.save),
            ),
          ],
        );
      },
    );
  }
}

/// 고객 카드 위젯
class _CustomerCard extends ConsumerWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSpentAsync = ref.watch(customerTotalSpentProvider(customer.id));
    final currencyFormat = NumberFormat('#,###');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCustomerDetail(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 아바타
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withAlpha(30),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (customer.phone != null)
                      Text(customer.phone!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    if (customer.email != null)
                      Text(customer.email!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              // 포인트 & 총 사용
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${currencyFormat.format(customer.points)} P',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  totalSpentAsync.when(
                    data: (total) => Text(
                      '₩${currencyFormat.format(total.toInt())}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomerDetail(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.read(customerHistoryProvider(customer.id));
    final currencyFormat = NumberFormat('#,###');
    final dateFormat = DateFormat('MM/dd HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            final l10nInner = AppLocalizations.of(context)!;
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primary.withAlpha(30),
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            if (customer.phone != null) Text(customer.phone!, style: const TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(l10nInner.points, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          Text(
                            '${currencyFormat.format(customer.points)} P',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 포인트 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _adjustPoints(ctx, ref, true),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(l10nInner.earnPoints),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: customer.points > 0 ? () => _adjustPoints(ctx, ref, false) : null,
                          icon: const Icon(Icons.remove, size: 18),
                          label: Text(l10nInner.usePoints),
                        ),
                      ),
                    ],
                  ),
                ),
                // 구매 이력
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10nInner.purchaseHistory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Sale>>(
                    future: ref.read(customersDaoProvider).getCustomerPurchaseHistory(customer.id),
                    builder: (context, snapshot) {
                      final l10nFuture = AppLocalizations.of(context)!;
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final sales = snapshot.data!;
                      if (sales.isEmpty) {
                        return Center(child: Text(l10nFuture.noPurchaseHistory, style: const TextStyle(color: AppTheme.textSecondary)));
                      }
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sales.length,
                        itemBuilder: (_, i) {
                          final sale = sales[i];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              sale.paymentMethod == 'cash' ? Icons.payments : Icons.credit_card,
                              color: AppTheme.textSecondary,
                            ),
                            title: Text('#${sale.saleNumber}'),
                            subtitle: Text(dateFormat.format(sale.createdAt)),
                            trailing: Text(
                              '₩${currencyFormat.format(sale.total.toInt())}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _adjustPoints(BuildContext context, WidgetRef ref, bool isAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final l10nDialog = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(isAdd ? l10nDialog.earnPointsTitle : l10nDialog.usePointsTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10nDialog.pointsLabel,
              suffixText: 'P',
              hintText: isAdd ? l10nDialog.earnPointsHint : l10nDialog.usePointsHint(customer.points),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10nDialog.cancel)),
            ElevatedButton(
              onPressed: () async {
                final pts = int.tryParse(controller.text) ?? 0;
                if (pts <= 0) return;
                final dao = ref.read(customersDaoProvider);
                if (isAdd) {
                  await dao.addPoints(customer.id, pts);
                } else {
                  await dao.usePoints(customer.id, pts);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) Navigator.pop(context); // bottom sheet도 닫기
              },
              child: Text(l10nDialog.confirm),
            ),
          ],
        );
      },
    );
  }
}
