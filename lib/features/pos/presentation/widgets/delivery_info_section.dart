import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Delivery order customer information input section
/// Displays when orderType is phoneDelivery or platformDelivery
class DeliveryInfoSection extends StatelessWidget {
  final TextEditingController customerNameController;
  final TextEditingController deliveryPhoneController;
  final TextEditingController deliveryAddressController;

  const DeliveryInfoSection({
    super.key,
    required this.customerNameController,
    required this.deliveryPhoneController,
    required this.deliveryAddressController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delivery_dining, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Delivery Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Customer Name
          TextField(
            controller: customerNameController,
            decoration: InputDecoration(
              labelText: 'Customer Name *',
              hintText: 'Enter customer name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Delivery Phone
          TextField(
            controller: deliveryPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              hintText: 'Enter phone number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Delivery Address
          TextField(
            controller: deliveryAddressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Delivery Address *',
              hintText: 'Enter delivery address',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Validates all delivery information fields
  /// Returns error message if validation fails, null if all valid
  static String? validate(
    BuildContext context,
    String? customerName,
    String? deliveryPhone,
    String? deliveryAddress,
  ) {
    if (customerName == null || customerName.trim().isEmpty) {
      return 'Please enter customer name';
    }

    if (deliveryPhone == null || deliveryPhone.trim().isEmpty) {
      return 'Please enter phone number';
    }

    if (deliveryAddress == null || deliveryAddress.trim().isEmpty) {
      return 'Please enter delivery address';
    }

    return null; // All valid
  }
}
