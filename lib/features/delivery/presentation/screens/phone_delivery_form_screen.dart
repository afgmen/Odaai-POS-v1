import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customers/providers/customers_provider.dart';
import '../../../pos/data/models/order_type.dart';
import '../../../pos/presentation/screens/pos_main_screen.dart';

/// PhoneDeliveryFormScreen — 전화 배달 주문 폼
/// Phase 4: 전화번호 → 고객 자동조회, 주소, 예상시간, 결제방식
class PhoneDeliveryFormScreen extends ConsumerStatefulWidget {
  const PhoneDeliveryFormScreen({super.key});

  @override
  ConsumerState<PhoneDeliveryFormScreen> createState() =>
      _PhoneDeliveryFormScreenState();
}

class _PhoneDeliveryFormScreenState
    extends ConsumerState<PhoneDeliveryFormScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  String _paymentMethod = 'cod'; // cod | prepaid
  int _estimatedMinutes = 30;
  Customer? _matchedCustomer;
  bool _isLookingUp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deliveryColor = OrderType.phoneDelivery.color;

    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Delivery'),
        backgroundColor: deliveryColor.withValues(alpha: 0.1),
        foregroundColor: deliveryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 전화번호
            _SectionLabel('Phone Number'),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '0912 345 678',
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: _isLookingUp
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _lookupCustomer,
                      ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                if (value.length >= 10) _lookupCustomer();
              },
            ),
            if (_matchedCustomer != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _matchedCustomer!.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          if (_matchedCustomer!.phone?.isNotEmpty ?? false)
                            Text(
                              _matchedCustomer!.phone!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                    if (_matchedCustomer!.points > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_matchedCustomer!.points} pts',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // 고객명
            _SectionLabel(l10n.customerName),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Customer name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            // 배달 주소
            _SectionLabel(l10n.deliveryAddress),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Delivery address',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            // 예상 배달 시간
            _SectionLabel('Estimated Time'),
            Row(
              children: [15, 30, 45, 60].map((min) {
                final isSelected = _estimatedMinutes == min;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${min}m'),
                    selected: isSelected,
                    selectedColor: deliveryColor.withValues(alpha: 0.2),
                    onSelected: (_) =>
                        setState(() => _estimatedMinutes = min),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 결제 방식
            _SectionLabel(l10n.paymentMethod),
            Row(
              children: [
                Expanded(
                  child: _PaymentOption(
                    label: 'COD',
                    icon: Icons.money,
                    isSelected: _paymentMethod == 'cod',
                    onTap: () =>
                        setState(() => _paymentMethod = 'cod'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentOption(
                    label: 'Prepaid',
                    icon: Icons.credit_card,
                    isSelected: _paymentMethod == 'prepaid',
                    onTap: () =>
                        setState(() => _paymentMethod = 'prepaid'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 메모
            _SectionLabel('Note'),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Special instructions...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 32),

            // 주문 시작 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startOrder,
                icon: const Icon(Icons.shopping_cart, size: 22),
                label: Text('Start Order',
                    style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: deliveryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _lookupCustomer() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) return;

    setState(() => _isLookingUp = true);

    try {
      final dao = ref.read(customersDaoProvider);

      // Try exact match first
      Customer? customer = await dao.getCustomerByPhone(phone);

      // If no exact match, try search
      if (customer == null) {
        final results = await dao.searchCustomers(phone);
        if (results.isNotEmpty) {
          customer = results.first;
        }
      }

      if (customer != null && mounted) {
        setState(() {
          _matchedCustomer = customer;
          _nameController.text = customer!.name;
          if (customer.note != null &&
              customer.note!.isNotEmpty &&
              _addressController.text.isEmpty) {
            _addressController.text = customer.note!;
          }
        });

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Customer found: ${customer.name}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    } catch (e) {
      debugPrint('Customer lookup failed: $e');
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  void _startOrder() {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PosMainScreen(
          orderType: OrderType.phoneDelivery,
          // customerName, deliveryAddress, deliveryPhone는
          // Phase 5에서 Sale 생성 시 전달 예정
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.blue : Colors.grey, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
